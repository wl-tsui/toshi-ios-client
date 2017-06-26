#import "BlurTool.h"

#import "PhotoBlurPass.h"
#import "PhotoEditorBlurToolView.h"
#import "PhotoEditorBlurAreaView.h"

#import "Common.h"

@implementation BlurToolValue

- (instancetype)copyWithZone:(NSZone *)__unused zone
{
    BlurToolValue *value = [[BlurToolValue alloc] init];
    value.type = self.type;
    value.point = self.point;
    value.size = self.size;
    value.falloff = self.falloff;
    value.angle = self.angle;
    value.intensity = self.intensity;
    value.editingIntensity = self.editingIntensity;
    
    return value;
}

- (BOOL)isEqual:(id)object
{
    if (object == self)
        return true;
    
    if (!object || ![object isKindOfClass:[self class]])
        return false;
    
    BlurToolValue *value = (BlurToolValue *)object;
    
    if (value.type != self.type)
        return false;
    
    if (!CGPointEqualToPoint(value.point, self.point))
        return false;
    
    if (value.size != self.size)
        return false;
    
    if (value.falloff != self.falloff)
        return false;
    
    if (value.angle != self.angle)
        return false;
    
    if (value.intensity != self.intensity)
        return false;
    
    return true;
}

@end

@implementation BlurTool

- (instancetype)init
{
    self = [super init];
    if (self != nil)
    {
        _identifier = @"blur";
        _type = PhotoToolTypePass;
        _order = 3;
        
        _pass = [[PhotoBlurPass alloc] init];
        
        _minimumValue = 0;
        _maximumValue = 100;
        _defaultValue = 50;
        
        BlurToolValue *value = [[BlurToolValue alloc] init];
        value.type = BlurToolTypeNone;
        value.point = CGPointMake(0.5f, 0.5f);
        value.falloff = 0.12f;
        value.size = 0.24f;
        value.angle = 0;
        value.intensity = _defaultValue;
        
        self.value = value;
    }
    return self;
}

- (NSString *)title
{
    return TGLocalized(@"BlurTool");
}

- (NSString *)intensityEditingTitle
{
    return TGLocalized(@"BlurToolRadius");
}

- (UIImage *)image
{
    return [UIImage imageNamed:@"PhotoEditorBlurTool"];
}

- (UIView <PhotoEditorToolView> *)itemControlViewWithChangeBlock:(void (^)(id, bool))changeBlock
{
    __weak BlurTool *weakSelf = self;
    
    UIView <PhotoEditorToolView> *view = [[PhotoEditorBlurToolView alloc] initWithEditorItem:self];
    view.valueChanged = ^(id newValue, bool animated)
    {
        __strong BlurTool *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        
        if ([strongSelf.tempValue isEqual:newValue])
            return;
        
        strongSelf.tempValue = newValue;
        
        if (changeBlock != nil)
            changeBlock(newValue, animated);
    };
    return view;
}

- (UIView <PhotoEditorToolView> *)itemAreaViewWithChangeBlock:(void (^)(id))changeBlock
{
    __weak BlurTool *weakSelf = self;
    
    UIView <PhotoEditorToolView> *view = [[PhotoEditorBlurAreaView alloc] initWithEditorItem:self];
    view.valueChanged = ^(id newValue, __unused bool animated)
    {
        __strong PhotoTool *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        
        if (newValue != nil)
        {
            if ([strongSelf.tempValue isEqual:newValue])
                return;
            
            strongSelf.tempValue = newValue;
        }
        
        if (changeBlock != nil)
            changeBlock(newValue);
    };
    return view;
}

- (Class)valueClass
{
    return [BlurToolValue class];
}

- (PhotoProcessPass *)pass
{
    BlurToolValue *value = (BlurToolValue *)self.displayValue;
    
    if (value.type == BlurToolTypeNone)
        return nil;
    
    [self updatePassParameters];
    
    return _pass;
}

- (void)updatePassParameters
{
    BlurToolValue *value = (BlurToolValue *)self.displayValue;

    PhotoBlurPass *blurPass = (PhotoBlurPass *)_pass;
    blurPass.type = value.type;
    blurPass.size = value.size;
    blurPass.point = value.point;
    blurPass.angle = value.angle;
    blurPass.falloff = value.falloff;
}

- (bool)shouldBeSkipped
{
    if (self.disabled)
        return true;
    
    return (((BlurToolValue *)self.displayValue).type == BlurToolTypeNone);
}

- (NSString *)stringValue
{
    if ([self.value isKindOfClass:[BlurToolValue class]])
    {
        BlurToolValue *value = (BlurToolValue *)self.value;
        if (value.type == BlurToolTypeRadial)
            return TGLocalized(@"BlurToolRadial");
        else if (value.type == BlurToolTypeLinear)
            return TGLocalized(@"BlurToolLinear");
    }
    
    return nil;
}

@end
