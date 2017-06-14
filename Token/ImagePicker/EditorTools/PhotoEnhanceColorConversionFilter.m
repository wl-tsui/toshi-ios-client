#import "PhotoEnhanceColorConversionFilter.h"

#import "PhotoProcessPass.h"

NSString *const PhotoEnhanceRGBToHSVShaderString = PGShaderString
(
 precision highp float;
 
 varying vec2 texCoord;
 uniform sampler2D sourceImage;
 
 vec3 rgb_to_hsv(vec3 c) {
     vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
     vec4 p = c.g < c.b ? vec4(c.bg, K.wz) : vec4(c.gb, K.xy);
     vec4 q = c.r < p.x ? vec4(p.xyw, c.r) : vec4(c.r, p.yzx);
     
     float d = q.x - min(q.w, q.y);
     float e = 1.0e-10;
     return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
 }
 
 void main() {
     vec4 texel = texture2D(sourceImage, texCoord);
     
     gl_FragColor = vec4(rgb_to_hsv(texel.rgb), texel.a);
 }
);

NSString *const PhotoEnhanceHSVToRGBShaderString = PGShaderString
(
 precision highp float;
 
 varying vec2 texCoord;
 uniform sampler2D sourceImage;
 
 vec3 hsv_to_rgb(vec3 c) {
     vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
     vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
     return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
 }
 
 void main() {
     vec4 texel = texture2D(sourceImage, texCoord);
     
     gl_FragColor = vec4(hsv_to_rgb(texel.rgb), texel.a);
 }
);

@implementation PhotoEnhanceColorConversionFilter

- (instancetype)initWithMode:(PGPhotoEnhanceColorConversionMode)mode
{
    return [super initWithFragmentShaderFromString:(mode == PGPhotoEnhanceColorConversionRGBToHSVMode) ? PhotoEnhanceRGBToHSVShaderString : PhotoEnhanceHSVToRGBShaderString];
}

@end
