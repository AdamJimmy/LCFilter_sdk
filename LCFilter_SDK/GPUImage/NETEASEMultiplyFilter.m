#import "NETEASEMultiplyFilter.h"
#import "GPUImagePicture.h"
//#import "GPUImageMultiplyBlendFilter.h"
#import "LCImageMultiplyBlendFilter.h"
@implementation NETEASEMultiplyFilter

- (id)init;
{
    if (!(self = [super init]))
    {
		return nil;
    }

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    UIImage *image = [UIImage imageNamed:@"lookup_amatorka.png"];
#else
    NSImage *image = [NSImage imageNamed:@"lookup_amatorka.png"];
#endif
    
    NSAssert(image, @"To use GPUImageAmatorkaFilter you need to add lookup_amatorka.png from GPUImage/framework/Resources to your application bundle.");
    
    return self;
}

- (id)initWithImage:(UIImage*)image
                ratio:(float)setR
                textureIdx:(int)setTextureIdx
{

        if (!(self = [super init]))
        {
            return nil;
        }
        
//#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
//        UIImage *image = [UIImage imageNamed:lutPath];
//#else
//        NSImage *image = [NSImage imageNamed:lutPath];
//#endif
//        
//        NSAssert(image, @"Cannot find lutFile.");
    
        multiplyImageSource = [[GPUImagePicture alloc] initWithImage:image];
//        GPUImageMultiplyBlendFilter *blendFilter = [[GPUImageMultiplyBlendFilter alloc] initWithRatio:setR];
    LCImageMultiplyBlendFilter *blendFilter = [[LCImageMultiplyBlendFilter alloc] initWithRatio:setR];
    
        [self addFilter:blendFilter];
        
        [multiplyImageSource addTarget:blendFilter atTextureLocation:setTextureIdx];
        [multiplyImageSource processImage];
        
        self.initialFilters = [NSArray arrayWithObjects:blendFilter, nil];
        self.terminalFilter = blendFilter;
        
        return self;
}

@end
