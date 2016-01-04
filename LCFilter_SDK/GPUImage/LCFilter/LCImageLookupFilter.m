//
//  LCImageLookupFilter.m
//  LOFTERCam
//
//  Created by Dikey on 11/30/15.
//  Copyright © 2015 Netease. All rights reserved.
//

#import "LCImageLookupFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
//NSString *const kGPUImageLookupFragmentShaderFormat = SHADER_STRING
NSString *const kLCImageLookupFragmentShaderFormat = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2; // TODO: This is not used
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2; // lookup texture
 
 uniform highp float ratio%i;
 
 void main()
 {
     highp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     
     highp float blueColor = textureColor.b * 63.0;
     
     highp vec2 quad1;
     quad1.y = floor(floor(blueColor) / 8.0);
     quad1.x = floor(blueColor) - (quad1.y * 8.0);
     
     highp vec2 quad2;
     quad2.y = floor(ceil(blueColor) / 8.0);
     quad2.x = ceil(blueColor) - (quad2.y * 8.0);
     
     highp vec2 texPos1;
     texPos1.x = (quad1.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
     texPos1.y = (quad1.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);
     
     highp vec2 texPos2;
     texPos2.x = (quad2.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
     texPos2.y = (quad2.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);
     
     lowp vec4 newColor1 = texture2D(inputImageTexture2, texPos1);
     lowp vec4 newColor2 = texture2D(inputImageTexture2, texPos2);
     
     lowp vec4 newColor = mix(newColor1, newColor2, fract(blueColor));
     
     lowp vec4 resultColor = mix(textureColor,newColor,ratio%i);
     gl_FragColor = vec4(resultColor.rgb, textureColor.w);
 }
 );
#else
NSString *const kGPUImageLookupFragmentShaderFormat = SHADER_STRING
(
 varying vec2 textureCoordinate;
 varying vec2 textureCoordinate2; // TODO: This is not used
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2; // lookup texture
 
 uniform highp float ratio%i;
 
 void main()
 {
     vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     
     float blueColor = textureColor.b * 63.0;
     
     vec2 quad1;
     quad1.y = floor(floor(blueColor) / 8.0);
     quad1.x = floor(blueColor) - (quad1.y * 8.0);
     
     vec2 quad2;
     quad2.y = floor(ceil(blueColor) / 8.0);
     quad2.x = ceil(blueColor) - (quad2.y * 8.0);
     
     vec2 texPos1;
     texPos1.x = (quad1.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
     texPos1.y = (quad1.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);
     
     vec2 texPos2;
     texPos2.x = (quad2.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
     texPos2.y = (quad2.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);
     
     vec4 newColor1 = texture2D(inputImageTexture2, texPos1);
     vec4 newColor2 = texture2D(inputImageTexture2, texPos2);
     
     vec4 newColor = mix(newColor1, newColor2, fract(blueColor));
     
     vec4 resultColor = mix(textureColor,newColor,ratio%i);
     gl_FragColor = vec4(resultColor.rgb, textureColor.w);
 }
 );
#endif

@implementation LCImageLookupFilter

- (id)initWithRatio:(float)setR
         textureIdx:(int)textureIdx
{
    
    NSString* kLCImageLookupFragmentShaderString = [NSString stringWithFormat:kLCImageLookupFragmentShaderFormat,textureIdx,textureIdx];
    
    //    NSLog(kGPUImageLookupFragmentShaderString);
    
    if (!(self = [super initWithFragmentShaderFromString:kLCImageLookupFragmentShaderString]))
    {
        return nil;
    }
    
    NSString* ratioString = [NSString stringWithFormat:@"ratio%i",textureIdx];
    _glRatioLocation = [filterProgram uniformIndex:ratioString];
    glUniform1f(_glRatioLocation, setR);
    
    _fRatio = setR;
    
    return self;
}
@end
