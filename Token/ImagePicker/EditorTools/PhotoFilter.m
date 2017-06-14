#import "PhotoFilter.h"

#import "PhotoEditorGenericToolView.h" //

#import "PhotoFilterDefinition.h" //

#import "PhotoCustomFilterPass.h" //
#import "PhotoLookupFilterPass.h" // 
#import "PhotoProcessPass.h" //

@interface PhotoFilter ()
{
    PhotoProcessPass *_parameter;
}
@end

@implementation PhotoFilter

@synthesize value = _value;
@synthesize tempValue = _tempValue;
@synthesize parameters = _parameters;
@synthesize beingEdited = _beingEdited;
@synthesize shouldBeSkipped = _shouldBeSkipped;
@synthesize parametersChanged = _parametersChanged;
@synthesize disabled = _disabled;
@synthesize segmented = _segmented;

- (instancetype)initWithDefinition:(PhotoFilterDefinition *)definition
{
    self = [super init];
    if (self != nil)
    {
        _definition = definition;
        _value = @(self.defaultValue);
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)__unused zone
{
    PhotoFilter *filter = [[PhotoFilter alloc] initWithDefinition:self.definition];
    filter.value = self.value;
    return filter;
}

- (NSString *)title
{
    return _definition.title;
}

- (NSString *)identifier
{
    return _definition.identifier;
}

- (PhotoProcessPass *)pass
{
    if (_pass == nil)
    {
        switch (_definition.type)
        {
            case PhotoFilterTypeCustom:
            {
                _pass = [[PhotoCustomFilterPass alloc] initWithShaderFile:_definition.shaderFilename textureFiles:_definition.textureFilenames];
            }
                break;
                
            case PhotoFilterTypeLookup:
            {
                _pass = [[PhotoLookupFilterPass alloc] initWithLookupImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@.png", _definition.lookupFilename]]];
            }
                break;
                
            default:
            {
                _pass = [[PhotoProcessPass alloc] init];
            }
                break;
        }
    }
    
    [self updatePassParameters];
    
    return _pass;
}

- (PhotoProcessPass *)optimizedPass
{
    switch (_definition.type)
    {
        case PhotoFilterTypeCustom:
        {
            return [[PhotoCustomFilterPass alloc] initWithShaderFile:_definition.shaderFilename textureFiles:_definition.textureFilenames optimized:true];
        }
            break;
            
        case PhotoFilterTypeLookup:
        {
            return [[PhotoLookupFilterPass alloc] initWithLookupImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@.png", _definition.lookupFilename]]];
        }
            break;
            
        default:
            break;
    }
    
    return [[PhotoProcessPass alloc] init];
}

- (Class)valueClass
{
    return [NSNumber class];
}

- (CGFloat)minimumValue
{
    return 0.0f;
}

- (CGFloat)maximumValue
{
    return 100.0f;
}

- (CGFloat)defaultValue
{
    return 100.0f;
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

- (NSArray *)parameters
{
    return _parameters;
}

- (void)updateParameters
{
    
}

- (void)updatePassParameters
{
    CGFloat value = ((NSNumber *)self.displayValue).floatValue / self.maximumValue;
        
    if ([_pass isKindOfClass:[PhotoLookupFilterPass class]])
    {
        PhotoLookupFilterPass *pass = (PhotoLookupFilterPass *)_pass;
        [pass setIntensity:value];
    }
    else if ([_pass isKindOfClass:[PhotoCustomFilterPass class]])
    {
        PhotoCustomFilterPass *pass = (PhotoCustomFilterPass *)_pass;
        [pass setIntensity:value];
    }
}

- (void)invalidate
{
    _pass = nil;
    _value = @(self.defaultValue);
}

- (void)reset
{
    [_pass.filter removeAllTargets];
}

- (id<PhotoEditorToolView>)itemControlViewWithChangeBlock:(void (^)(id newValue, bool animated))changeBlock
{
    __weak PhotoFilter *weakSelf = self;
    
    id<PhotoEditorToolView> view = [[PhotoEditorGenericToolView alloc] initWithEditorItem:self];
    view.valueChanged = ^(id newValue, bool animated)
    {
        __strong PhotoFilter *strongSelf = weakSelf;
        if (strongSelf == nil)
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

- (BOOL)isEqual:(id)object
{
    if (object == self)
        return YES;
    
    if (!object || ![object isKindOfClass:[self class]])
        return NO;
    
    return ([[(PhotoFilter *)object definition].identifier isEqualToString:self.definition.identifier]);
}

+ (PhotoFilter *)filterWithDefinition:(PhotoFilterDefinition *)definition
{
    return [[[self class] alloc] initWithDefinition:definition];
}

@end
