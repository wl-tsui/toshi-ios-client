#import "PhotoEditorBlurToolView.h"

#import "PhotoEditorBlurTypeButton.h"
#import "PhotoEditorSliderView.h"

#import "PhotoEditorInterfaceAssets.h"
#import "UIControl+HitTestEdgeInsets.h"
#import "ImageUtils.h"
#import "Common.h"
#import "BlurTool.h"

@interface PhotoEditorBlurToolView ()
{
    BlurToolType _currentType;
    
    UIView *_buttonsWrapper;
    PhotoEditorBlurTypeButton *_offButton;
    PhotoEditorBlurTypeButton *_radialButton;
    PhotoEditorBlurTypeButton *_linearButton;
    
    PhotoEditorSliderView *_sliderView;
    
    bool _editingIntensity;
    CGFloat _startIntensity;
}

@property (nonatomic, weak) BlurTool *blurTool;

@end

@implementation PhotoEditorBlurToolView

@synthesize valueChanged = _valueChanged;
@synthesize value = _value;
@dynamic interactionEnded;
@synthesize actualAreaSize;
@synthesize isLandscape;
@synthesize toolbarLandscapeSize;

- (instancetype)initWithEditorItem:(id<PhotoEditorItem>)editorItem
{
    self = [super initWithFrame:CGRectZero];
    if (self != nil)
    {
        _buttonsWrapper = [[UIView alloc] initWithFrame:self.bounds];
        _buttonsWrapper.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:_buttonsWrapper];
        
        _offButton = [[PhotoEditorBlurTypeButton alloc] initWithFrame:CGRectZero];
        _offButton.tag = BlurToolTypeNone;
        [_offButton addTarget:self action:@selector(blurButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [_offButton setImage:[UIImage imageNamed:@"PhotoEditorBlurOff"]];
        [_offButton setTitle:TGLocalized(@"BlurToolOff")];
        [_buttonsWrapper addSubview:_offButton];
        
        _radialButton = [[PhotoEditorBlurTypeButton alloc] initWithFrame:CGRectZero];
        _radialButton.tag = BlurToolTypeRadial;
        [_radialButton addTarget:self action:@selector(blurButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [_radialButton setImage:[UIImage imageNamed:@"PhotoEditorBlurRadial"]];
        [_radialButton setTitle:TGLocalized(@"BlurToolRadial")];
        [_buttonsWrapper addSubview:_radialButton];

        _linearButton = [[PhotoEditorBlurTypeButton alloc] initWithFrame:CGRectZero];
        _linearButton.tag = BlurToolTypeLinear;
        [_linearButton addTarget:self action:@selector(blurButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [_linearButton setImage:[UIImage imageNamed:@"PhotoEditorBlurLinear"]];
        [_linearButton setTitle:TGLocalized(@"BlurToolLinear")];
        [_buttonsWrapper addSubview:_linearButton];
        
        _sliderView = [[PhotoEditorSliderView alloc] initWithFrame:CGRectZero];
        _sliderView.alpha = 0.0f;
        _sliderView.hidden = true;
        _sliderView.layer.rasterizationScale = TGScreenScaling();
        _sliderView.minimumValue = editorItem.minimumValue;
        _sliderView.maximumValue = editorItem.maximumValue;
        _sliderView.startValue = 0;
        if (editorItem.value != nil && [editorItem.value isKindOfClass:[NSNumber class]])
            _sliderView.value = [(NSNumber *)editorItem.value integerValue];
        [_sliderView addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        [self addSubview:_sliderView];
        
        if ([editorItem isKindOfClass:[BlurTool class]])
        {
            BlurTool *blurTool = (BlurTool *)editorItem;
            self.blurTool = blurTool;
            [self setValue:editorItem.value];
            
            if (blurTool.value != nil)
            {
                BlurToolValue *value = blurTool.value;
                _sliderView.value = value.intensity;
            }
            else
            {
                _sliderView.value = 0.0f;
            }
        }
    }
    return self;
}

- (bool)buttonPressed:(bool)__unused cancelButton
{
//    if (_editingIntensity)
//    {
//        BlurToolValue *value = [(BlurToolValue *)self.value copy];
//        if (cancelButton)
//            value.intensity = _startIntensity;
//        
//        value.editingIntensity = false;
//        
//        _value = value;
//        
//        if (self.valueChanged != nil)
//            self.valueChanged(value);
//        
//        _editingIntensity = false;
//        [self setIntensitySliderHidden:true animated:true];
//        
//        return false;
//    }
//    else
//    {
        return true;
//    }
}

- (void)setInteractionEnded:(void (^)(void))interactionEnded
{
    _sliderView.interactionEnded = interactionEnded;
}

- (bool)isTracking
{
    return _sliderView.isTracking;
}

- (void)sliderValueChanged:(PhotoEditorSliderView *)sender
{
    dispatch_async(dispatch_get_main_queue(), ^
    {
        BlurToolValue *value = [(BlurToolValue *)self.value copy];
        value.intensity = (NSInteger)(floor(sender.value));

        _value = value;
        
        if (self.valueChanged != nil)
            self.valueChanged(value, false);
    });
}

- (void)setSelectedBlurType:(BlurToolType)blurType update:(bool)update
{
    for (PhotoEditorBlurTypeButton *button in _buttonsWrapper.subviews)
        button.selected = (button.tag == blurType);
    
    if (blurType == _currentType)
        return;
    
    _currentType = blurType;
    
    BlurToolValue *value = [(BlurToolValue *)self.value copy];
    value.type = _currentType;
    
    if (update && self.valueChanged != nil)
        self.valueChanged(value, true);
}

- (void)blurButtonPressed:(PhotoEditorBlurTypeButton *)sender
{
//    if (sender.tag != 0 && sender.tag == _currentType)
//    {
//        _editingIntensity = true;
//        _startIntensity = [(BlurToolValue *)self.value intensity];
//        
//        BlurToolValue *value = [(BlurToolValue *)self.value copy];
//        value.editingIntensity = true;
//        
//        _value = value;
//        
//        if (self.valueChanged != nil)
//            self.valueChanged(value);
//        
//        [self setIntensitySliderHidden:false animated:true];
//    }
//    else
//    {
        [self setSelectedBlurType:(BlurToolType)sender.tag update:true];
//    }
}

- (void)setValue:(id)value
{
    if (![value isKindOfClass:[BlurToolValue class]])
    {
        [self setSelectedBlurType:BlurToolTypeNone update:false];
        return;
    }
    
    _value = value;
    
    BlurToolValue *blurValue = (BlurToolValue *)value;
    [self setSelectedBlurType:blurValue.type update:false];
    [_sliderView setValue:blurValue.intensity];
    
    if (blurValue.editingIntensity != _editingIntensity)
    {
        _editingIntensity = blurValue.editingIntensity;

        [self setIntensitySliderHidden:!_editingIntensity animated:false];
    }
}

- (void)setIntensitySliderHidden:(bool)hidden animated:(bool)animated
{
    if (animated)
    {
        CGFloat buttonsDelay = hidden ? 0.07f : 0.0f;
        CGFloat sliderDelay = hidden ? 0.0f : 0.07f;
        
        CGFloat buttonsDuration = hidden ? 0.23f : 0.1f;
        CGFloat sliderDuration = hidden ? 0.1f : 0.23f;
        
        _buttonsWrapper.hidden = false;
        [UIView animateWithDuration:buttonsDuration delay:buttonsDelay options:UIViewAnimationOptionCurveLinear animations:^
        {
            _buttonsWrapper.alpha = hidden ? 1.0f : 0.0f;
        } completion:^(BOOL finished)
        {
            if (finished)
                _buttonsWrapper.hidden = !hidden;
        }];
        
        _sliderView.hidden = false;
        _sliderView.layer.shouldRasterize = true;
        [UIView animateWithDuration:sliderDuration delay:sliderDelay options:UIViewAnimationOptionCurveLinear animations:^
        {
            _sliderView.alpha = hidden ? 0.0f : 1.0f;
        } completion:^(BOOL finished)
        {
            _sliderView.layer.shouldRasterize = false;
            if (finished)
                _sliderView.hidden = hidden;
        }];
    }
    else
    {
        _sliderView.hidden = hidden;
        _sliderView.alpha = hidden ? 0.0f : 1.0f;
        
        _buttonsWrapper.hidden = !hidden;
        _buttonsWrapper.alpha = hidden ? 1.0f : 0.0f;
    }
}

- (void)layoutSubviews
{
    _sliderView.interfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if (CGRectIsEmpty(self.frame))
        return;
    
    if (self.frame.size.width > self.frame.size.height)
    {
        _offButton.frame = CGRectMake(floor(self.frame.size.width / 4 - 50), self.frame.size.height / 2 - 42, 100, 100);
        _radialButton.frame = CGRectMake(self.frame.size.width / 2 - 50, self.frame.size.height / 2 - 42, 100, 100);
        _linearButton.frame = CGRectMake(CGCeil(self.frame.size.width / 2 + self.frame.size.width / 4 - 50), self.frame.size.height / 2 - 42, 100, 100);

        _sliderView.frame = CGRectMake(PhotoEditorSliderViewMargin, (self.frame.size.height - 32) / 2, self.frame.size.width - 2 * PhotoEditorSliderViewMargin, 32);
    }
    else
    {
        _offButton.frame = CGRectMake(self.frame.size.width / 2 - 50, self.frame.size.height / 2 + self.frame.size.height / 4 - 50, 100, 100);
        _radialButton.frame = CGRectMake(self.frame.size.width / 2 - 50, self.frame.size.height / 2 - 50, 100, 100);
        _linearButton.frame = CGRectMake(self.frame.size.width / 2 - 50, self.frame.size.height / 4 - 50, 100, 100);

        _sliderView.frame = CGRectMake((self.frame.size.width - 32) / 2, PhotoEditorSliderViewMargin, 32, self.frame.size.height - 2 * PhotoEditorSliderViewMargin);
    }
    
    _sliderView.hitTestEdgeInsets = UIEdgeInsetsMake(-_sliderView.frame.origin.x,
                                                     -_sliderView.frame.origin.y,
                                                     -(self.frame.size.height - _sliderView.frame.origin.y - _sliderView.frame.size.height),
                                                     -_sliderView.frame.origin.x);
}

@end
