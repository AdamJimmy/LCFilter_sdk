//
//  LCImageFilter.m
//  LCFilter-Lofter
//
//  Created by NetEase on 15/12/28.
//  Copyright © 2015年 NetEase. All rights reserved.
//

#import "LCImageFilter.h"
#import "NETEASELookupFilter.h"
#import "GPUImagePicture.h"
#import "GPUImageLookupFilter.h"
#import "GPUImageSaturationFilter.h"
#import "GPUImageSharpenFilter.h"
#import "NETEASEAddBlendFilter.h"
#import "NETEASEMultiplyFilter.h"
#import "GTMBase64.h"
#define DEGREES_TO_RADIANS(__DEGREES) (__DEGREES * 0.017453293) // (M_PI / 180.0f)
static const NSString *CODE = @"encodingFilePath";
@interface LCImageFilter ()
@property (nonatomic, strong) NSArray *filterItems;

@end
@implementation LCImageFilter{
    GPUImageOutput<GPUImageInput> *_output;
    NSCache *_cache;
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
+ (void)filtOriginImage:(UIImage *)originImage
      withDefaultFilter:(LCOriginalFilter_Type)originFilterType
                   size:(CGSize)size
                  ratio:(CGFloat)ratio
        completionBlock:(void (^)(UIImage *))competionBlock{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *result = [self filtOriginImage:originImage withDefaultFilter:originFilterType size:size ratio:ratio];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (competionBlock) {
                competionBlock(result);
            }
        });
        
    });
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
+ (void)trimOriginImage:(UIImage *)originImage
        withDefaultTrim:(LCOriginalTrim_Type)originFilterType
                   size:(CGSize)size
                  ratio:(CGFloat)ratio
        completionBlock:(void (^)(UIImage *))competionBlock{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *result = [self trimOriginImage:originImage withDefaultTrim:originFilterType size:size ratio:ratio];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (competionBlock) {
                competionBlock(result);
            }
        });

    });
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
                trimImageName = @"temperaturep";
            }else{
                trimImageName = @"temperaturem";
            }
        }break;
        case LCOriginalTrim_Saturation:{
            return nil;
            
        }break;
        case LCOriginalTrim_Exposure:{
            if (ratio>0) {
                trimImageName = @"exposurep";
            }else{
                trimImageName = @"exposurem";
            }
        }break;
        case LCOriginalTrim_Contrast:{
            if (ratio>0) {
                trimImageName = @"contrastp";
            }else{
                trimImageName = @"contrastm";
            }
        }break;
        case LCOriginalTrim_Sharpness:{
            return nil;

        }break;
        case LCOriginalTrim_Clarity:{
            trimImageName = @"clarityp";
        }break;
        case LCOriginalTrim_Noise:{
            trimImageName = @"grain";
        }break;
        case LCOriginalTrim_Dark:{
            trimImageName = @"vignette";
        }break;
        case LCOriginalTrim_Hightlight0:{
            trimImageName = @"highlight0";
        }break;
        case LCOriginalTrim_Hightlight1:{
           trimImageName = @"highlight1";
        }break;
        case LCOriginalTrim_Hightlight2:{
            trimImageName = @"highlight2";
        }break;
        case LCOriginalTrim_Hightlight3:{
            trimImageName = @"highlight3";
        }break;
        case LCOriginalTrim_Hightlight4:{
            trimImageName = @"highlight4";
        }break;
        case LCOriginalTrim_Hightlight5:{
            trimImageName = @"highlight5";
        }break;
        case LCOriginalTrim_HightlightOrigin:{
            trimImageName = @"highlightOrigin";
        }break;
        case LCOriginalTrim_ShadeDetail0:{
            trimImageName = @"darkness0";
        }break;
        case LCOriginalTrim_ShadeDetail1:{
            trimImageName = @"darkness1";
        }break;
        case LCOriginalTrim_ShadeDetail2:{
            trimImageName = @"darkness2";
        }break;
        case LCOriginalTrim_ShadeDetail3:{
            trimImageName = @"darkness3";
        }break;
        case LCOriginalTrim_ShadeDetail4:{
            trimImageName = @"darkness4";
        }break;
        case LCOriginalTrim_ShadeDetail5:{
            trimImageName = @"darkness5";
        }break;
        case LCOriginalTrim_ShadeDetailOrigin:{
            trimImageName = @"darknessOrigin";
        }break;
        case LCOriginalTrim_BlurEffect:{
            trimImageName = @"fade";
        }break;
        default:
            break;
    }
    
    return [self getImageWithImageName:trimImageName];
    
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
    NSString *filterName = nil;
    switch (originFilterType) {
        case LCOriginalFilter_Jane:
            filterName = @"jian";
            break;
        case LCOriginalFilter_SaltI:
            filterName = @"yan";
            break;
        case LCOriginalFilter_SaltII:
            filterName = @"yan2";
            break;
        case LCOriginalFilter_SaltIII:
            filterName = @"yan3";
            break;
        case LCOriginalFilter_Cyan:
            filterName = @"qing";
            break;
        case LCOriginalFilter_Summer:
            filterName = @"xia";
            break;
        case LCOriginalFilter_MoodGray:
            filterName = @"hui";
            break;
        case LCOriginalFilter_Dusk:
            filterName = @"mu";
            break;
        case LCOriginalFilter_Firefly:
            filterName = @"ying";
            break;
        case LCOriginalFilter_InkI:
            filterName = @"mo1";
            break;
        case LCOriginalFilter_InkII:
            filterName = @"mo2";
            break;
        case LCOriginalFilter_InkIII:
            filterName = @"mo3";
            break;
        case LCOriginalFilter_A1:
            filterName = @"vsco_a1";
            break;
        case LCOriginalFilter_A5:
            filterName = @"vsco_a5";
            break;
        case LCOriginalFilter_A6:
            filterName = @"vsco_a6";
        case LCOriginalFilter_A7:
            filterName = @"vsco_a7";
            break;
        case LCOriginalFilter_A8:
            filterName = @"vsco_a8";
            break;
        case LCOriginalFilter_M5:
            filterName = @"vsco_m5";
            break;
        case LCOriginalFilter_J6:
            filterName = @"vsco_j6";
            break;
        case LCOriginalFilter_N1:
            filterName = @"vsco_n1";
            break;
        case LCOriginalFilter_HB1:
            filterName = @"vsco_hb1";
            break;
        case LCOriginalFilter_KK1:
            filterName = @"vsco_kk1";
            break;
        case LCOriginalFilter_T1:
            filterName = @"vsco_t1";
            break;
        case LCOriginalFilter_H5:
            filterName = @"vsco_h5";
            break;
        case LCOriginalFilter_SE1:
            filterName = @"vsco_se1";
            break;
        case LCOriginalFilter_F2:
            filterName = @"vsco_f2";
            break;
            
        default:
            break;
    }
    return [self getImageWithImageName:filterName];
}

- (UIImage *)getImageWithImageName:(NSString *)imageName{

    if (!_cache) {
        _cache = [NSCache new];
    }
    UIImage *image = nil;
    NSString *img_path = nil;
    image = [_cache objectForKey:imageName];
    if (!image) {
        NSString *bundlePath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"LCFilterResources.bundle"];
        NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
        img_path = [bundle pathForResource:imageName ofType:nil];
        NSData *dataEncoded = [NSData dataWithContentsOfFile:img_path];
        NSData *datadecoded = [GTMBase64 decodeData:dataEncoded];
        //密码字符串
        NSString *codeFinal = [NSString stringWithFormat:@"%@/%@",CODE,imageName];
        //密码文件
        NSData *codeData = [codeFinal dataUsingEncoding:NSUTF8StringEncoding];
        NSUInteger pre = codeData.length;
        NSUInteger total = datadecoded.length;
        NSRange range = {pre,total - pre};
        //除去加密文件
        NSData *imData = [datadecoded subdataWithRange:range];
        image = [UIImage imageWithData:imData];
        [_cache setObject:image forKey:imageName];
    }

    if (!image) {
        NSLog(@"Error:找不到滤镜色块文件,imgPath:%@",img_path);
        return nil;
        
    }
    return image;
}

#pragma mark - 旋转
+ (UIImage *)rotateInRadian:(CGFloat)radians image:(UIImage *)image fitSize:(BOOL)fitSize{
    size_t width = (size_t)CGImageGetWidth(image.CGImage);
    size_t height = (size_t)CGImageGetHeight(image.CGImage);
    CGRect newRect = CGRectApplyAffineTransform(CGRectMake(0., 0., width, height),
                                                fitSize ? CGAffineTransformMakeRotation(radians) : CGAffineTransformIdentity);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 (size_t)newRect.size.width,
                                                 (size_t)newRect.size.height,
                                                 8,
                                                 (size_t)newRect.size.width * 4,
                                                 colorSpace,
                                                 kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    if (!context) return nil;
    
    CGContextSetShouldAntialias(context, true);
    CGContextSetAllowsAntialiasing(context, true);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    
    CGContextTranslateCTM(context, +(newRect.size.width * 0.5), +(newRect.size.height * 0.5));
    CGContextRotateCTM(context, radians);
    
    CGContextDrawImage(context, CGRectMake(-(width * 0.5), -(height * 0.5), width, height), image.CGImage);
    CGImageRef imgRef = CGBitmapContextCreateImage(context);
    UIImage *img = [UIImage imageWithCGImage:imgRef scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(imgRef);
    CGContextRelease(context);
    return img;

}
+ (UIImage *)rotateInDegree:(CGFloat)degree image:(UIImage *)image fitSize:(BOOL)fitSize{
    return [self rotateInRadian:DEGREES_TO_RADIANS(degree) image:image fitSize:fitSize];
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
