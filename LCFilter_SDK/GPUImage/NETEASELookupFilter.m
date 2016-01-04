#import "NETEASELookupFilter.h"
#import "GPUImagePicture.h"
#import "GPUImageLookupFilter.h"
//#import "LOCFileManager.h"
#import "LCImageLookupFilter.h"

@implementation NETEASELookupFilter

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
    
    lookupImageSource = [[GPUImagePicture alloc] initWithImage:image];
    GPUImageLookupFilter *lookupFilter = [[GPUImageLookupFilter alloc] init];
    [self addFilter:lookupFilter];
    
    [lookupImageSource addTarget:lookupFilter atTextureLocation:1];
    [lookupImageSource processImage];
    
    self.initialFilters = [NSArray arrayWithObjects:lookupFilter, nil];
    self.terminalFilter = lookupFilter;
    
    return self;
}



- (id)initWithFilterImage:(UIImage *)filterImage
                    ratio:(float)setR
               textureIdx:(int)setTextureIdx
{
    
    if (!(self = [super init]))
    {
        return nil;
    }

    
    lookupImageSource = [[GPUImagePicture alloc] initWithImage:filterImage];
    if (filterImage == nil) {
        lookupImageSource = [[GPUImagePicture alloc]init];
    }else{
        lookupImageSource = [[GPUImagePicture alloc] initWithImage:filterImage];
    }
    LCImageLookupFilter *lookupFilter = [[LCImageLookupFilter alloc] initWithRatio:setR
                                                                        textureIdx:setTextureIdx];
    [self addFilter:lookupFilter];
    
    [lookupImageSource addTarget:lookupFilter atTextureLocation:setTextureIdx];
    [lookupImageSource processImage];
    
    self.initialFilters = [NSArray arrayWithObjects:lookupFilter, nil];
    self.terminalFilter = lookupFilter;
    
    return self;
}


@end
