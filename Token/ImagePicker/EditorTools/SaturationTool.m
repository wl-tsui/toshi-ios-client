#import "SaturationTool.h"
#import "Common.h"

@interface SaturationTool ()
{
    PhotoProcessPassParameter *_parameter;
}
@end

@implementation SaturationTool

- (instancetype)init
{
    self = [super init];
    if (self != nil)
    {
        _identifier = @"saturation";
        _type = PhotoToolTypeShader;
        _order = 8;
        
        _minimumValue = -100;
        _maximumValue = 100;
        _defaultValue = 0;
        
        self.value = @(_defaultValue);
    }
    return self;
}

- (NSString *)title
{
    return TGLocalized(@"SaturationTool");
}

- (UIImage *)image
{
    return [UIImage imageNamed:@"PhotoEditorSaturationTool"];
}

- (bool)shouldBeSkipped
{
    return (ABS(((NSNumber *)self.displayValue).floatValue - (float)self.defaultValue) < FLT_EPSILON);
}

- (NSArray *)parameters
{
    if (!_parameters)
    {
        _parameter = [PhotoProcessPassParameter parameterWithName:@"saturation" type:@"lowp float"];
        _parameters = @[ [PhotoProcessPassParameter constWithName:@"satLuminanceWeighting" type:@"mediump vec3" value:@"vec3(0.2126, 0.7152, 0.0722)"],
                         _parameter ];
    }
    
    return _parameters;
}

- (void)updateParameters
{
    NSNumber *value = (NSNumber *)self.displayValue;
    
    CGFloat parameterValue = (value.floatValue / 100.0f);
    if (parameterValue > 0)
        parameterValue *= 1.05f;
    parameterValue += 1;
    [_parameter setFloatValue:parameterValue];
}

- (NSString *)shaderString
{
    return PGShaderString
    (
        lowp float satLuminance = dot(result.rgb, satLuminanceWeighting);
        lowp vec3 greyScaleColor = vec3(satLuminance);
     
        result = vec4(clamp(mix(greyScaleColor, result.rgb, saturation), 0.0, 1.0), result.a);
    );
}

@end
