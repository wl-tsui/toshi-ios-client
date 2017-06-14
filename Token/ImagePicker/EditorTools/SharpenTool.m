#import "SharpenTool.h"
#import "Common.h"
#import "PhotoSharpenPass.h"

@implementation SharpenTool

- (instancetype)init
{
    self = [super init];
    if (self != nil)
    {
        _identifier = @"sharpen";
        _type = PhotoToolTypePass;
        _order = 2;
        
        _pass = [[PhotoSharpenPass alloc] init];
        
        _minimumValue = 0;
        _maximumValue = 100;
        _defaultValue = 0;
        
        self.value = @(_defaultValue);
    }
    return self;
}

- (NSString *)title
{
    return TGLocalized(@"SharpenTool");
}

- (UIImage *)image
{
    return [UIImage imageNamed:@"PhotoEditorSharpenTool"];
}

- (PhotoProcessPass *)pass
{
    [self updatePassParameters];
    
    return _pass;
}

- (bool)shouldBeSkipped
{
    return false;
    //return (fabsf(((NSNumber *)self.displayValue).floatValue - self.defaultValue) < FLT_EPSILON);
}

- (void)updatePassParameters
{
    NSNumber *value = (NSNumber *)self.displayValue;
    [(PhotoSharpenPass *)_pass setSharpness:0.125f + value.floatValue / 100 * 0.6f];
}

@end
