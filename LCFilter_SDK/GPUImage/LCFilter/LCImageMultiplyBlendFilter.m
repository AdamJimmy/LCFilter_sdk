//
//  LCImageMultiplyBlendFilter.m
//  LOFTERCam
//
//  Created by Dikey on 11/30/15.
//  Copyright © 2015 Netease. All rights reserved.
//

#import "LCImageMultiplyBlendFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
//NSString *const kGPUImageMultiplyBlendFragmentShaderString = SHADER_STRING
NSString *const kLCImageMultiplyBlendFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 uniform lowp float ratio;
 
 void main()
 {
     lowp vec4 base = texture2D(inputImageTexture, textureCoordinate);
     lowp vec4 overlayer = texture2D(inputImageTexture2, textureCoordinate2);
     
     lowp vec4 tmp = overlayer * base + overlayer * (1.0 - base.a) + base * (1.0 - overlayer.a);
     gl_FragColor = mix(base,tmp,ratio);
 }
 );
#else
NSString *const kGPUImageMultiplyBlendFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 varying vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 uniform float ratio;
 
 void main()
 {
     vec4 base = texture2D(inputImageTexture, textureCoordinate);
     vec4 overlayer = texture2D(inputImageTexture2, textureCoordinate2);
     
     vec4 tmp = overlayer * base + overlayer * (1.0 - base.a) + base * (1.0 - overlayer.a);
     gl_FragColor = mix(base,tmp,ratio);
 }
 );
#endif

@implementation LCImageMultiplyBlendFilter

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kLCImageMultiplyBlendFragmentShaderString]))
    {
        return nil;
    }
    
    return self;
}

- (id)initWithRatio:(float)setR
{
    if (!(self = [super initWithFragmentShaderFromString:kLCImageMultiplyBlendFragmentShaderString]))
    {
        return nil;
    }
    _glRatioLocation = [filterProgram uniformIndex:@"ratio"];
    glUniform1f(_glRatioLocation, setR);
    
    _fRatio = setR;
    
    return self;
}


@end
