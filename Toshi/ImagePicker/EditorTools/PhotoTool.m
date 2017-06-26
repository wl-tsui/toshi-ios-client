#import "PhotoTool.h"
#import "PhotoEditorGenericToolView.h"

@implementation PhotoTool

@synthesize title = _title;
@synthesize value = _value;
@synthesize tempValue = _tempValue;
@synthesize parameters = _parameters;
@synthesize beingEdited = _beingEdited;
@synthesize shouldBeSkipped = _shouldBeSkipped;
@synthesize parametersChanged = _parametersChanged;
@synthesize disabled = _disabled;
@synthesize segmented = _segmented;

- (instancetype)init
{
    self = [super init];
    if (self != nil)
    {
        [self parameters];
    }
    return self;
}

- (NSString *)identifier
{
    return _identifier;
}

- (PhotoToolType)type
{
    return _type;
}

- (NSInteger)order
{
    return _order;
}

- (Class)valueClass
{
    return [NSNumber class];
}

- (CGFloat)minimumValue
{
    return _minimumValue;
}

- (CGFloat)maximumValue
{
    return _maximumValue;
}

- (CGFloat)defaultValue
{
    return _defaultValue;
}

- (id)tempValue
{
    if (self.disabled)
    {
        if ([_tempValue isKindOfClass:[NSNumber class]])
            return @0;
    }
    
    return _tempValue;
}

- (id)displayValue
{
    if (self.beingEdited)
        return self.tempValue;

    return self.value;
}

- (void)setDisabled:(bool)disabled
{
    _disabled = disabled;
    
    if (self.beingEdited)
        [self updateParameters];
}

- (void)setBeingEdited:(bool)beingEdited
{
    _beingEdited = beingEdited;
    
    [self updateParameters];
}

- (void)setValue:(id)value
{
    _value = value;
    
    if (!self.beingEdited)
        [self updateParameters];
}

- (void)setTempValue:(id)tempValue
{
    _tempValue = tempValue;
    
    if (self.beingEdited)
        [self updateParameters];
}

- (bool)isHidden
{
    return false;
}

- (void)updateParameters
{
    
}

- (void)reset
{

}

- (void)invalidate
{
    if (_pass != nil)
        [_pass invalidate];
}

- (UIView <PhotoEditorToolView> *)itemControlViewWithChangeBlock:(void (^)(id newValue, bool animated))changeBlock
{
    __weak PhotoTool *weakSelf = self;
    
    UIView <PhotoEditorToolView> *view = [[PhotoEditorGenericToolView alloc] initWithEditorItem:self];
    view.valueChanged = ^(id newValue, bool animated)
    {
        __strong PhotoTool *strongSelf = weakSelf;
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

- (UIView <PhotoEditorToolView> *)itemAreaViewWithChangeBlock:(void (^)(id newValue))__unused changeBlock
{
    return nil;
}

- (NSString *)stringValue
{
    if ([self.displayValue isKindOfClass:[NSNumber class]])
    {
        NSNumber *value = (NSNumber *)self.displayValue;
        CGFloat fractValue = value.floatValue / ABS(self.maximumValue);
        if (floorf(ABS(value.floatValue)) == 0)
            return nil;
        else if (fractValue > 0)
            return [NSString stringWithFormat:@"+%0.2f", fractValue];
        else if (fractValue < 0)
            return [NSString stringWithFormat:@"%0.2f", fractValue];
    }
    
    return nil;
}

- (NSString *)ancillaryShaderString
{
    return nil;
}

@end
