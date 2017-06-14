#import "PhotoEditorCurvesHistogramView.h"

#import <SSignalKit/SSignalKit.h>

#import "CurvesTool.h"
#import "PhotoToolComposer.h"
#import "PhotoHistogram.h"

#import "ImageUtils.h"

#import "ModernButton.h"
#import "PhotoEditorInterfaceAssets.h"
#import "HistogramView.h"

#import "PhotoEditorTabController.h"
#import "PhotoEditorToolButtonsView.h"

#import "Common.h"

@interface PhotoEditorCurvesHistogramView ()
{
    ModernButton *_rgbButton;
    ModernButton *_redButton;
    ModernButton *_greenButton;
    ModernButton *_blueButton;
    TGHistogramView *_histogramView;
    
    SMetaDisposable *_histogramDisposable;
    PhotoHistogram *_histogram;
    
    bool _appeared;
}
@end

@implementation PhotoEditorCurvesHistogramView

@synthesize valueChanged = _valueChanged;
@synthesize value = _value;
@synthesize interactionEnded = _interactionEnded;
@synthesize actualAreaSize;
@synthesize isLandscape = _isLandscape;
@synthesize toolbarLandscapeSize;

- (instancetype)initWithEditorItem:(id<PhotoEditorItem>)editorItem
{
    self = [super initWithFrame:CGRectZero];
    if (self != nil)
    {
        _rgbButton = [self _modeButtonWithTitle:TGLocalized(@"All")];
        _rgbButton.selected = true;
        _rgbButton.tag = PGCurvesTypeLuminance;
        [self addSubview:_rgbButton];
        
        _redButton = [self _modeButtonWithTitle:TGLocalized(@"Red")];
        _redButton.tag = PGCurvesTypeRed;
        [self addSubview:_redButton];
    
        _greenButton = [self _modeButtonWithTitle:TGLocalized(@"Green")];
        _greenButton.tag = PGCurvesTypeGreen;
        [self addSubview:_greenButton];
        
        _blueButton = [self _modeButtonWithTitle:TGLocalized(@"Blue")];
        _blueButton.tag = PGCurvesTypeBlue;
        [self addSubview:_blueButton];
        
        _histogramView = [[TGHistogramView alloc] initWithFrame:CGRectZero];
        [self addSubview:_histogramView];
        
        if ([editorItem isKindOfClass:[CurvesTool class]])
            [self setValue:editorItem.value];
        
        _histogramDisposable = [[SMetaDisposable alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_histogramDisposable dispose];
}

- (void)setIsLandscape:(bool)isLandscape
{
    _isLandscape = isLandscape;
    _histogramView.isLandscape = isLandscape;
    
    [self layoutHistogramView];
}

- (CGSize)histogramViewSize
{
    CGSize screenSize = TGScreenSize();
    CGFloat portraitHeight = PhotoEditorPanelSize + PhotoEditorToolbarSize - PhotoEditorToolButtonsViewSize;
    if (self.isLandscape)
        return CGSizeMake(PhotoEditorPanelSize - 34, screenSize.width);
    else
        return CGSizeMake(screenSize.width, portraitHeight - 34);
}

- (void)layoutHistogramView
{
    CGSize histogramViewSize = [self histogramViewSize];
    _histogramView.frame = CGRectMake(0, 0, histogramViewSize.width, histogramViewSize.height);
}

- (ModernButton *)_modeButtonWithTitle:(NSString *)title
{
    ModernButton *button = [[ModernButton alloc] initWithFrame:CGRectZero];
    
    button = [[ModernButton alloc] initWithFrame:CGRectMake(0, 0, 80, 20)];
    button.backgroundColor = [UIColor clearColor];
    button.titleLabel.font = [PhotoEditorInterfaceAssets editorItemTitleFont];
    [button setTitle:[title uppercaseString] forState:UIControlStateNormal];
    [button setTitleColor:UIColorRGB(0x808080) forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected | UIControlStateHighlighted];
    [button addTarget:self action:@selector(modeButtonPressed:) forControlEvents:UIControlEventTouchDown];
    
    return button;
}

- (void)modeButtonPressed:(ModernButton *)sender
{
    for (ModernButton *button in self.subviews)
    {
        if (![button isKindOfClass:[ModernButton class]])
            continue;
        
        button.selected = (button == sender);
    }

    CurvesToolValue *value = [(CurvesToolValue *)self.value copy];
    if (value.activeType != sender.tag)
    {
        value.activeType = (PGCurvesType)sender.tag;
        
        _value = value;
        
        self.valueChanged(value, false);
        
        [self updateHistogram];
    }
}

- (bool)isTracking
{
    return false;
}

- (bool)buttonPressed:(bool)__unused cancelButton
{
    return true;
}

- (void)layoutSubviews
{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    CGSize histogramViewSize = [self histogramViewSize];
    
    if (!self.isLandscape)
    {
        _rgbButton.frame = CGRectMake(floor(self.frame.size.width / 5 - _rgbButton.frame.size.width / 2), 8, _rgbButton.frame.size.width, _rgbButton.frame.size.height);
        _redButton.frame = CGRectMake(floor(self.frame.size.width / 5 * 2 - _redButton.frame.size.width / 2), 8, _redButton.frame.size.width, _redButton.frame.size.height);
        _greenButton.frame = CGRectMake(floor(self.frame.size.width / 5 * 3 - _greenButton.frame.size.width / 2), 8, _greenButton.frame.size.width, _greenButton.frame.size.height);
        _blueButton.frame = CGRectMake(floor(self.frame.size.width / 5 * 4 - _blueButton.frame.size.width / 2), 8, _blueButton.frame.size.width, _blueButton.frame.size.height);
        
        _histogramView.frame = CGRectMake(0, 34, histogramViewSize.width, histogramViewSize.height);
    }
    else
    {
        [UIView performWithoutAnimation:^
        {
            if (orientation == UIInterfaceOrientationLandscapeLeft)
            {
                CGAffineTransform transform = CGAffineTransformMakeRotation(M_PI_2);
                _rgbButton.transform = transform;
                _redButton.transform = transform;
                _greenButton.transform = transform;
                _blueButton.transform = transform;
                _histogramView.transform = transform;
                
                _rgbButton.frame = CGRectMake(self.frame.size.width - _rgbButton.frame.size.width - 8, floor(self.frame.size.height / 5 - _rgbButton.frame.size.height / 2), _rgbButton.frame.size.width, _rgbButton.frame.size.height);
                _redButton.frame = CGRectMake(self.frame.size.width - _redButton.frame.size.width - 8, floor(self.frame.size.height / 5 * 2 - _redButton.frame.size.height / 2), _redButton.frame.size.width, _redButton.frame.size.height);
                _greenButton.frame = CGRectMake(self.frame.size.width - _blueButton.frame.size.width - 8, floor(self.frame.size.height / 5 * 3 - _greenButton.frame.size.height / 2), _greenButton.frame.size.width, _greenButton.frame.size.height);
                _blueButton.frame = CGRectMake(self.frame.size.width - _blueButton.frame.size.width - 8, floor(self.frame.size.height / 5 * 4 - _blueButton.frame.size.height / 2), _blueButton.frame.size.width, _blueButton.frame.size.height);
                _histogramView.frame = CGRectMake(0, 0, histogramViewSize.width, histogramViewSize.height);
            }
            else if (orientation == UIInterfaceOrientationLandscapeRight)
            {
                CGAffineTransform transform = CGAffineTransformMakeRotation(-M_PI_2);
                _rgbButton.transform = transform;
                _redButton.transform = transform;
                _greenButton.transform = transform;
                _blueButton.transform = transform;
                _histogramView.transform = transform;
                
                _rgbButton.frame = CGRectMake(8, floor(self.frame.size.height / 5 * 4 - _rgbButton.frame.size.height / 2), _rgbButton.frame.size.width, _rgbButton.frame.size.height);
                _redButton.frame = CGRectMake(8, floor(self.frame.size.height / 5 * 3 - _redButton.frame.size.height / 2), _redButton.frame.size.width, _redButton.frame.size.height);
                _greenButton.frame = CGRectMake(8, floor(self.frame.size.height / 5 * 2 - _greenButton.frame.size.height / 2), _greenButton.frame.size.width, _greenButton.frame.size.height);
                _blueButton.frame = CGRectMake(8, floor(self.frame.size.height / 5 - _blueButton.frame.size.height / 2), _blueButton.frame.size.width, _blueButton.frame.size.height);
                _histogramView.frame = CGRectMake(34, 0, histogramViewSize.width, histogramViewSize.height);
            }
        }];
    }
    
    if (!_appeared)
    {
        _appeared = true;
        [self updateHistogram];
    }
}

- (void)updateHistogram
{
    CurvesToolValue *value = (CurvesToolValue *)self.value;
    [_histogramView setHistogram:_histogram type:value.activeType animated:true];
}

- (void)setHistogramSignal:(SSignal *)signal
{
    __weak PhotoEditorCurvesHistogramView *weakSelf = self;
    [_histogramDisposable setDisposable:[[signal deliverOn:[SQueue mainQueue]] startWithNext:^(PhotoHistogram *next)
    {
        __strong PhotoEditorCurvesHistogramView *strongSelf = weakSelf;
        if (strongSelf != nil)
        {
            strongSelf->_histogram = next;
            [strongSelf updateHistogram];
        }
    }]];
}

@end
