#import "NETEASEAddBlendFilter.h"
#import "GPUImagePicture.h"
#import "GPUImageAddBlendFilter.h"
#import "LCImageAddBlendFilter.h"

@implementation NETEASEAddBlendFilter

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
    
    //    lookupImageSource = [[GPUImagePicture alloc] initWithImage:image];
    //    GPUImageLookupFilter *lookupFilter = [[GPUImageLookupFilter alloc] init];
    //    [self addFilter:lookupFilter];
    //
    //    [lookupImageSource addTarget:lookupFilter atTextureLocation:1];
    //    [lookupImageSource processImage];
    //
    //    self.initialFilters = [NSArray arrayWithObjects:lookupFilter, nil];
    //    self.terminalFilter = lookupFilter;
    
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
//    UIImage *image = [UIImage imageNamed:lutPath];
//#else
//    NSImage *image = [NSImage imageNamed:lutPath];
//#endif
//    
//    NSAssert(image, @"Cannot find lutFile.");
    
    addBlendImageSource = [[GPUImagePicture alloc] initWithImage:image];
//    GPUImageAddBlendFilter *blendFilter = [[GPUImageAddBlendFilter alloc] initWithRatio:setR];
    //        [self addFilter:blendFilter];
    
    LCImageAddBlendFilter *blendFilter = [[LCImageAddBlendFilter alloc] initWithRatio:setR];
    [self addFilter:blendFilter];
    
    [addBlendImageSource addTarget:blendFilter atTextureLocation:setTextureIdx];
    [addBlendImageSource processImage];
    
    self.initialFilters = [NSArray arrayWithObjects:blendFilter, nil];
    self.terminalFilter = blendFilter;
    
    return self;
}

/*
 - (id)initWithRatio:(NSString*) lutPath
 ratio:(float)setR
 {
 
 if (!(self = [super init]))
 {
 return nil;
 }
 
 #if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
 UIImage *image = [UIImage imageNamed:lutPath];
 #else
 NSImage *image = [NSImage imageNamed:lutPath];
 #endif
 
 NSAssert(image, @"Cannot find lutFile.");
 
 lookupImageSource = [[GPUImagePicture alloc] initWithImage:image];
 GPUImageLookupFilter *lookupFilter = [[GPUImageLookupFilter alloc] initWithRatio:setR];
 [self addFilter:lookupFilter];
 
 [lookupImageSource addTarget:lookupFilter atTextureLocation:1];
 [lookupImageSource processImage];
 
 self.initialFilters = [NSArray arrayWithObjects:lookupFilter, nil];
 self.terminalFilter = lookupFilter;
 
 return self;
 }
 */


#pragma mark -
#pragma mark Accessors

@end
