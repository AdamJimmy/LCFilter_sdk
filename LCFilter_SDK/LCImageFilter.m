//
//  LCImageFilter.m
//  LCFilter-Lofter
//
//  Created by NetEase on 15/12/28.
//  Copyright © 2015年 NetEase. All rights reserved.
//

#import "LCImageFilter.h"
#import "FilterItem.h"
#import "NETEASELookupFilter.h"
#import "GPUImagePicture.h"
#import "GPUImageLookupFilter.h"
#import "GPUImageSaturationFilter.h"
#import "GPUImageSharpenFilter.h"
#import "NETEASEAddBlendFilter.h"
#import "NETEASEMultiplyFilter.h"
#import <QuartzCore/QuartzCore.h>
#import <Accelerate/Accelerate.h>
static CIContext* __ciContext = nil;
static CGColorSpaceRef __rgbColorSpace = NULL;
#define NYX_DEGREES_TO_RADIANS(__DEGREES) (__DEGREES * 0.017453293) // (M_PI / 180.0f)
/* Number of components for an ARGB pixel (Alpha / Red / Green / Blue) = 4 */
#define kNyxNumberOfComponentsPerARBGPixel 4
@interface LCImageFilter ()
@property (nonatomic, strong) NSArray *filterItems;

@end
@implementation LCImageFilter{
    GPUImageOutput<GPUImageInput> *_output;
}
#pragma mark - 滤镜效果
- (UIImage *)filtOriginImage:(UIImage *)originImage
           withDefaultFilter:(LCOriginalFilter_Type)originFilterType
                        size:(CGSize)size
                       ratio:(CGFloat)ratio{
    UIImage *filterImage = [self getFilterImage:originFilterType];
    UIImage *resultImage = nil;
    resultImage = [self filterOriginImage:originImage withFilterImage:filterImage ratio:ratio];
    
    if (size.height == 0 && size.width == 0) {
        return resultImage;
    }
    resultImage = [self resizeImage:resultImage toSize:size];
    return resultImage;
}
#pragma mark-一般的滤镜用这个方法
- (UIImage *)filterOriginImage:(UIImage *)originImage
               withFilterImage:(UIImage *)filterImage
                         ratio:(CGFloat)ratio{
    if (!originImage ) {
        NSLog(@"LCImageFilter:传入文件不能为空");
        return nil;
    }
    if (!filterImage) {
        NSLog(@"LCImageFilter:传入的色块文件不能为空");
        return originImage;
    }
    NETEASELookupFilter *presentFilter = [[NETEASELookupFilter alloc] initWithFilterImage:filterImage ratio:ratio textureIdx:1];
    GPUImagePicture *oriGPUImage = [[GPUImagePicture alloc] initWithImage:originImage];
    GPUImageOutput<GPUImageInput>* filter =  presentFilter;
    [oriGPUImage addTarget:filter atTextureLocation:0];
    [oriGPUImage processImage];
    [filter useNextFrameForImageCapture];
    
    return [filter imageFromCurrentFramebuffer];
}
#pragma mark - 微调效果
- (UIImage *)trimOriginImage:(UIImage *)originImage{
    if (!originImage ) {
        NSLog(@"LCImageFilter:传入文件不能为空");
        return nil;
    }
    GPUImagePicture *oriGPUImage = [[GPUImagePicture alloc] initWithImage:originImage];
    GPUImageOutput<GPUImageInput>* filter =  _output;
    [oriGPUImage addTarget:filter atTextureLocation:0];
    [oriGPUImage processImage];
    [filter useNextFrameForImageCapture];
    
    return [filter imageFromCurrentFramebuffer];
}
- (UIImage *)trimOriginImage:(UIImage *)originImage withDefaultTrim:(LCOriginalTrim_Type)originFilterType size:(CGSize)size ratio:(CGFloat)ratio{
    UIImage *trimImage = [self getTrimImage:originFilterType withRatio:ratio];
    UIImage *resultImage = nil;

    if (originFilterType == LCOriginalTrim_Saturation) {
        GPUImageSaturationFilter *saturationFilter = [[GPUImageSaturationFilter alloc] init];
        [saturationFilter setSaturation:ratio+1.0f]; // 0 - 2
        _output = saturationFilter;
       
    }else if (originFilterType ==LCOriginalTrim_Sharpness){
        GPUImageSharpenFilter *sharpnessFilter = [[GPUImageSharpenFilter alloc] init];
        [sharpnessFilter setSharpness:ratio+1.0f]; // 0 - 2
        _output = sharpnessFilter;
        
    }else if (originFilterType == LCOriginalTrim_ColorTemp||originFilterType == LCOriginalTrim_Exposure||originFilterType == LCOriginalTrim_Contrast){
        NETEASELookupFilter *presentFilter = [[NETEASELookupFilter alloc] initWithFilterImage:trimImage ratio:fabs(ratio) textureIdx:1];
        _output = presentFilter;
    }else if (originFilterType == LCOriginalTrim_Noise){
        CGFloat ratioFinal = (ratio + 1)*0.5;
         NETEASEAddBlendFilter* grainFilter = [[NETEASEAddBlendFilter alloc]initWithImage:trimImage ratio:ratioFinal*.3f textureIdx:1.0];
        _output = grainFilter;
        resultImage = [self filterOriginImage:originImage withFilterImage:trimImage ratio:ratioFinal];
    }else if (originFilterType == LCOriginalTrim_Dark){
            CGFloat ratioFinal = (ratio + 1)*0.5;
        NETEASEMultiplyFilter* vignetteFilter = [[NETEASEMultiplyFilter alloc]initWithImage:trimImage ratio:ratioFinal textureIdx:1.0];
        _output = vignetteFilter;
    }
    else{
        CGFloat ratioFinal = (ratio + 1)*0.5;
        NETEASELookupFilter *presentFilter = [[NETEASELookupFilter alloc] initWithFilterImage:trimImage ratio:ratioFinal textureIdx:1];
        _output = presentFilter;
    }
    
   resultImage = [self trimOriginImage:originImage];

    if (size.height == 0 && size.width == 0) {
        return resultImage;
    }
    resultImage = [self resizeImage:resultImage toSize:size];
    return resultImage;
}

- (UIImage *)getTrimImage:(LCOriginalTrim_Type)trimType withRatio:(CGFloat )ratio{
    NSString *trimImageName = nil;
    switch (trimType) {

        case LCOriginalTrim_ColorTemp:{
            if (ratio>0) {
                trimImageName = @"temperaturep.jpg";
            }else{
                trimImageName = @"temperaturem.jpg";
            }
        }break;
        case LCOriginalTrim_Saturation:{
            
        }break;
        case LCOriginalTrim_Exposure:{
            if (ratio>0) {
                trimImageName = @"exposurep.jpg";
            }else{
                trimImageName = @"exposurem.jpg";
            }
        }break;
        case LCOriginalTrim_Contrast:{
            if (ratio>0) {
                trimImageName = @"contrastp.jpg";
            }else{
                trimImageName = @"contrastm.jpg";
            }
        }break;
        case LCOriginalTrim_Sharpness:{

        }break;
        case LCOriginalTrim_Clarity:{
            trimImageName = @"clarityp.jpg";
        }break;
        case LCOriginalTrim_Noise:{
            trimImageName = @"grain.jpg";
        }break;
        case LCOriginalTrim_Dark:{
            trimImageName = @"vignette.jpg";
        }break;
        case LCOriginalTrim_Hightlight0:{
            trimImageName = @"highlight0.jpg";
        }break;
        case LCOriginalTrim_Hightlight1:{
           trimImageName = @"highlight1.jpg";
        }break;
        case LCOriginalTrim_Hightlight2:{
            trimImageName = @"highlight2.jpg";
        }break;
        case LCOriginalTrim_Hightlight3:{
            trimImageName = @"highlight3.jpg";
        }break;
        case LCOriginalTrim_Hightlight4:{
            trimImageName = @"highlight4.jpg";
        }break;
        case LCOriginalTrim_Hightlight5:{
            trimImageName = @"highlight5.jpg";
        }break;
        case LCOriginalTrim_HightlightOrigin:{
            trimImageName = @"highlightOrigin.jpg";
        }break;
        case LCOriginalTrim_ShadeDetail0:{
            trimImageName = @"darkness0.jpg";
        }break;
        case LCOriginalTrim_ShadeDetail1:{
            trimImageName = @"darkness1.jpg";
        }break;
        case LCOriginalTrim_ShadeDetail2:{
            trimImageName = @"darkness2.jpg";
        }break;
        case LCOriginalTrim_ShadeDetail3:{
            trimImageName = @"darkness3.jpg";
        }break;
        case LCOriginalTrim_ShadeDetail4:{
            trimImageName = @"darkness4.jpg";
        }break;
        case LCOriginalTrim_ShadeDetail5:{
            trimImageName = @"darkness5.jpg";
        }break;
        case LCOriginalTrim_ShadeDetailOrigin:{
            trimImageName = @"darknessOrigin.jpg";
        }break;
        case LCOriginalTrim_BlurEffect:{
            trimImageName = @"fade.jpg";
        }break;
        default:
            break;
    }
    
    return [self getImageWithImageName:trimImageName];
//    return [UIImage imageNamed:trimImageName];
    
}


- (UIImage *)resizeImage:(UIImage *)image
                  toSize:(CGSize)size{
    CGRect rect = {0,0,size};
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [image drawInRect:rect];
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resultImage;
}

- (UIImage *)getFilterImage:(LCOriginalFilter_Type)originFilterType{
    FilterItem *item = self.filterItems[originFilterType];
    return [self getImageWithImageName:item.filterName];
}

- (UIImage *)getImageWithImageName:(NSString *)imageName{
    NSString *bundlePath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"LCFilterResources.bundle"];
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    NSString *img_path = [bundle pathForResource:imageName ofType:nil];
    UIImage *image = [UIImage imageWithContentsOfFile:img_path];
    
//    if (image == nil) {
////        NSLog(@"imageName:%@",imageName);
////        NSLog(@"bundlePath:%@",bundlePath);
//        NSLog(@"Path is %@",img_path);
//        NSLog(@"Error:找不到滤镜色块文件");
//    }
    return image;
}

#pragma mark - 旋转
+(UIImage*)rotateInRadians:(float)radians originImage:(UIImage *)image
{
    return [self rotateInRadians:radians flipOverHorizontalAxis:NO verticalAxis:NO image:image];
}
+(UIImage*)rotateInDegrees:(float)degrees originImage:(UIImage *)image
{
    return [self rotateInRadians:(float)NYX_DEGREES_TO_RADIANS(degrees) originImage:image];
}

+(UIImage*)rotateInRadians:(CGFloat)radians flipOverHorizontalAxis:(BOOL)doHorizontalFlip verticalAxis:(BOOL)doVerticalFlip image:(UIImage *)image
{
    /// Create an ARGB bitmap context
    const size_t width = (size_t)CGImageGetWidth(image.CGImage);
    const size_t height = (size_t)CGImageGetHeight(image.CGImage);
    
    CGRect rotatedRect = CGRectApplyAffineTransform(CGRectMake(0., 0., width, height), CGAffineTransformMakeRotation(radians));
    
    CGContextRef bmContext = NYXCreateARGBBitmapContext((size_t)rotatedRect.size.width, (size_t)rotatedRect.size.height, (size_t)rotatedRect.size.width * kNyxNumberOfComponentsPerARBGPixel, YES);
    if (!bmContext)
        return nil;
    
    /// Image quality
    CGContextSetShouldAntialias(bmContext, true);
    CGContextSetAllowsAntialiasing(bmContext, true);
    CGContextSetInterpolationQuality(bmContext, kCGInterpolationHigh);
    
    /// Rotation happen here (around the center)
    CGContextTranslateCTM(bmContext, +(rotatedRect.size.width / 2.0f), +(rotatedRect.size.height / 2.0f));
    CGContextRotateCTM(bmContext, radians);
    
    // Do flips
    CGContextScaleCTM(bmContext, (doHorizontalFlip ? -1.0f : 1.0f), (doVerticalFlip ? -1.0f : 1.0f));
    
    /// Draw the image in the bitmap context
    CGContextDrawImage(bmContext, CGRectMake(-(width / 2.0f), -(height / 2.0f), width, height), image.CGImage);
    
    /// Create an image object from the context
    CGImageRef resultImageRef = CGBitmapContextCreateImage(bmContext);
    
    UIImage* resultImage = [UIImage imageWithCGImage:resultImageRef scale:image.scale orientation:image.imageOrientation];
    
    /// Cleanup
    CGImageRelease(resultImageRef);
    CGContextRelease(bmContext);
    
    return resultImage;
}

CGContextRef NYXCreateARGBBitmapContext(const size_t width, const size_t height, const size_t bytesPerRow, BOOL withAlpha)
{
    /// Use the generic RGB color space
    /// We avoid the NULL check because CGColorSpaceRelease() NULL check the value anyway, and worst case scenario = fail to create context
    /// Create the bitmap context, we want pre-multiplied ARGB, 8-bits per component
    CGImageAlphaInfo alphaInfo = (withAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst);
    CGContextRef bmContext = CGBitmapContextCreate(NULL, width, height, 8/*Bits per component*/, bytesPerRow, NYXGetRGBColorSpace(), kCGBitmapByteOrderDefault | alphaInfo);
    
    return bmContext;
}
CGColorSpaceRef NYXGetRGBColorSpace(void)
{
    if (!__rgbColorSpace)
    {
        __rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    }
    return __rgbColorSpace;
}
#pragma mark - 剪切
+(UIImage *)cropToRect:(CGRect)newRect originImage:(UIImage *)image
{
    double (^rad)(double) = ^(double deg) {
        return deg / 180.0 * M_PI;
    };
    
    CGAffineTransform rectTransform;
    switch (image.imageOrientation) {
        case UIImageOrientationLeft:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(90)), 0, -image.size.height);
            break;
        case UIImageOrientationRight:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(-90)), -image.size.width, 0);
            break;
        case UIImageOrientationDown:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(-180)), -image.size.width, -image.size.height);
            break;
        default:
            rectTransform = CGAffineTransformIdentity;
    };
    rectTransform = CGAffineTransformScale(rectTransform, image.scale, image.scale);
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], CGRectApplyAffineTransform(newRect, rectTransform));
    UIImage *result = [UIImage imageWithCGImage:imageRef scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(imageRef);
    
    return result;
}
+ (UIImage *)cropToRatioRect:(CGRect)ratioRect originImage:(UIImage *)image{
    CGFloat ratioX = ratioRect.origin.x;
    CGFloat ratioY = ratioRect.origin.y;
    CGFloat rationW = ratioRect.size.width;
    CGFloat rationH = ratioRect.size.height;
    
    CGRect rect = CGRectMake(ratioX*image.size.width, ratioY*image.size.height, rationW*image.size.width, rationH*image.size.height);
    return [self cropToRect:rect originImage:image];
}
#pragma mark - 懒加载

- (NSArray *)filterItems{
    if (_filterItems == nil) {
        NSString *bundlePath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"LCFilterResources.bundle"];
        NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
        NSString *path = [bundle pathForResource:@"Filters" ofType:@"plist"];
        NSArray *array = [NSArray arrayWithContentsOfFile:path];
        NSMutableArray *filters = [NSMutableArray array];
        for (NSDictionary *dic  in array) {
            FilterItem *filterItem = [FilterItem filterItemWithDict:dic];
            [filters addObject:filterItem];
        }
        _filterItems = filters;
 
    }
    return _filterItems;
    
}
#pragma mark - 类方法

+ (instancetype)shareLCImageFilterManager{
    static LCImageFilter *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[LCImageFilter alloc] init];
    });
    return manager;
}
+ (UIImage *)filtOriginImage:(UIImage *)originImage withDefaultFilter:(LCOriginalFilter_Type)originFilterType size:(CGSize)size ratio:(CGFloat)ratio {
    return [[self shareLCImageFilterManager]filtOriginImage:originImage withDefaultFilter:originFilterType size:size ratio:ratio];
}
+ (UIImage *)trimOriginImage:(UIImage *)originImage withDefaultTrim:(LCOriginalTrim_Type)originFilterType size:(CGSize)size ratio:(CGFloat)ratio{
    return [[self shareLCImageFilterManager] trimOriginImage:originImage withDefaultTrim:originFilterType size:size ratio:ratio];
}
@end
