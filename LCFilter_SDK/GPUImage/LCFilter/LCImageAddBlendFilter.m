//
//  LCImageAddBlendFilter.m
//  LOFTERCam
//
//  Created by Dikey on 11/30/15.
//  Copyright © 2015 Netease. All rights reserved.
//

#import "LCImageAddBlendFilter.h"


#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE

//NSString *const kGPUImageAddBlendFragmentShaderString = SHADER_STRING

NSString *const kLCImageAddBlendFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 uniform lowp float ratio;
 
 void main()
 {
     lowp vec4 base = texture2D(inputImageTexture, textureCoordinate);
     lowp vec4 overlay = texture2D(inputImageTexture2, textureCoordinate2);
     
     mediump float r;
     r = base.r*(1.0-ratio)+overlay.r*ratio;
     
     mediump float g;
     g = base.g*(1.0-ratio)+overlay.g*ratio;
     
     mediump float b;
     b = base.b*(1.0-ratio)+overlay.b*ratio;
     
     gl_FragColor = vec4(r, g, b, 1.0);
 }
 );
#else
NSString *const kGPUImageAddBlendFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 varying vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 uniform float ratio;
 
 void main()
 {
     vec4 base = texture2D(inputImageTexture, textureCoordinate);
     vec4 overlay = texture2D(inputImageTexture2, textureCoordinate2);
     
     float r;
     r = base.r*(1.0-ratio)+overlay.r*ratio;
     
     float g;
     g = base.g*(1.0-ratio)+overlay.g*ratio;
     
     float b;
     b = base.b*(1.0-ratio)+overlay.b*ratio;
     
     gl_FragColor = vec4(r, g, b, 1.0);
 }
 );
#endif

@implementation LCImageAddBlendFilter

- (id)initWithRatio:(float)setR
{
    if (!(self = [super initWithFragmentShaderFromString:kLCImageAddBlendFragmentShaderString]))
    {
        return nil;
    }
    _glRatioLocation = [filterProgram uniformIndex:@"ratio"];
    glUniform1f(_glRatioLocation, setR);
    
    _fRatio = setR;
    
    return self;
}

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kLCImageAddBlendFragmentShaderString]))
    {
        return nil;
    }
    
    return self;
}

@end
