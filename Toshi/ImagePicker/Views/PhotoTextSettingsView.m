#import "PhotoTextSettingsView.h"
#import "PhotoEditorSliderView.h"

#import "Font.h"
#import "ImageUtils.h"

#import "ModernButton.h"
#import "PhotoTextEntityView.h"
#import "Common.h"

const CGFloat PhotoTextSettingsViewMargin = 19.0f;
const CGFloat PhotoTextSettingsItemHeight = 44.0f;

@interface PhotoTextSettingsView ()
{
    NSArray *_fonts;
    
    UIInterfaceOrientation _interfaceOrientation;
    
    UIImageView *_backgroundView;
    
    NSArray *_fontViews;
    NSArray *_fontSeparatorViews;
    UIImageView *_selectedCheckView;
    
    UIView *_separatorView;
}
@end

@implementation PhotoTextSettingsView

@synthesize interfaceOrientation = _interfaceOrientation;

- (instancetype)initWithFonts:(NSArray *)fonts selectedFont:(PhotoPaintFont *)__unused selectedFont selectedStroke:(bool)selectedStroke
{
    self = [super initWithFrame:CGRectZero];
    if (self)
    {
        _fonts = fonts;
        
        _interfaceOrientation = UIInterfaceOrientationPortrait;
        
        _backgroundView = [[UIImageView alloc] init];
        _backgroundView.alpha = 0.98f;
        [self addSubview:_backgroundView];
        
        NSMutableArray *fontViews = [[NSMutableArray alloc] init];
        NSMutableArray *separatorViews = [[NSMutableArray alloc] init];
        
        UIFont *font = [UIFont boldSystemFontOfSize:18];
        
        ModernButton *outlineButton = [[ModernButton alloc] initWithFrame:CGRectMake(0, PhotoTextSettingsViewMargin, 0, 0)];
        outlineButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        outlineButton.titleLabel.font = font;
        outlineButton.contentEdgeInsets = UIEdgeInsetsMake(0.0f, 44.0f, 0.0f, 0.0f);
        outlineButton.tag = 0;
        [outlineButton setTitle:@"" forState:UIControlStateNormal];
        [outlineButton setTitleColor:[UIColor clearColor]];
        [outlineButton addTarget:self action:@selector(strokeValueChanged:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:outlineButton];
        [fontViews addObject:outlineButton];
        
        PhotoTextView *textView = [[PhotoTextView alloc] init];
        textView.backgroundColor = [UIColor clearColor];
        textView.textColor = [UIColor whiteColor];
        textView.strokeWidth = 3.0f;
        textView.strokeColor = [UIColor blackColor];
        textView.strokeOffset = CGPointMake(0.0f, 0.5f);
        textView.font = font;
        textView.text = TGLocalized(@"Paint.Outlined");
        [textView sizeToFit];
        textView.frame = CGRectMake(39.0f, ceil((PhotoTextSettingsItemHeight - textView.frame.size.height) / 2.0f) - 1.0f, ceil(textView.frame.size.width), ceil(textView.frame.size.height + 0.5f));
        [outlineButton addSubview:textView];
        
        UIView *separatorView = [[UIView alloc] init];
        separatorView.backgroundColor = UIColorRGB(0xd6d6da);
        [self addSubview:separatorView];

        [separatorViews addObject:separatorView];
        
        ModernButton *regularButton = [[ModernButton alloc] initWithFrame:CGRectMake(0, PhotoTextSettingsViewMargin +  PhotoTextSettingsItemHeight, 0, 0)];
        regularButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        regularButton.titleLabel.font = font;
        regularButton.contentEdgeInsets = UIEdgeInsetsMake(0.0f, 44.0f, 0.0f, 0.0f);
        regularButton.tag = 1;
        [regularButton setTitle:TGLocalized(@"Paint.Regular") forState:UIControlStateNormal];
        [regularButton setTitleColor:[UIColor blackColor]];
        [regularButton addTarget:self action:@selector(strokeValueChanged:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:regularButton];
        [fontViews addObject:regularButton];
        
        _fontViews = fontViews;
        _fontSeparatorViews = separatorViews;
        
        _selectedCheckView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"PaintCheck"]];
        _selectedCheckView.frame = CGRectMake(15.0f, 16.0f, _selectedCheckView.frame.size.width, _selectedCheckView.frame.size.height);
        
        [self setStroke:selectedStroke];
    }
    return self;
}

- (void)fontButtonPressed:(ModernButton *)sender
{
    [sender addSubview:_selectedCheckView];
    
    if (self.fontChanged != nil)
        self.fontChanged(_fonts[sender.tag]);
}

- (void)strokeValueChanged:(ModernButton *)sender
{
    if (self.strokeChanged != nil)
        self.strokeChanged(1 - sender.tag);
}

- (void)present
{
    self.alpha = 0.0f;
    
    self.layer.rasterizationScale = TGScreenScaling();
    self.layer.shouldRasterize = true;
    
    [UIView animateWithDuration:0.2 animations:^
    {
        self.alpha = 1.0f;
    } completion:^(__unused BOOL finished)
    {
        self.layer.shouldRasterize = false;
    }];
}

- (void)dismissWithCompletion:(void (^)(void))completion
{
    self.layer.rasterizationScale = TGScreenScaling();
    self.layer.shouldRasterize = true;
    
    [UIView animateWithDuration:0.15 animations:^
    {
        self.alpha = 0.0f;
    } completion:^(__unused BOOL finished)
    {
        if (completion != nil)
            completion();
    }];
}

- (bool)stroke
{
    return 1 - _selectedCheckView.superview.tag;
}

- (void)setStroke:(bool)stroke
{
    [_fontViews[1 - stroke] addSubview:_selectedCheckView];
}

- (NSString *)font
{
    return _fonts[_selectedCheckView.superview.tag];
}

- (void)setFont:(PhotoPaintFont *)__unused font
{
    
}

- (CGSize)sizeThatFits:(CGSize)__unused size
{
    return CGSizeMake(256, _fontViews.count * PhotoTextSettingsItemHeight + PhotoTextSettingsViewMargin * 2);
}

- (void)setInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    _interfaceOrientation = interfaceOrientation;
    
    switch (self.interfaceOrientation)
    {
        case UIInterfaceOrientationLandscapeLeft:
        {
            _backgroundView.image = [PhotoPaintSettingsView landscapeLeftBackgroundImage];
        }
            break;
            
        case UIInterfaceOrientationLandscapeRight:
        {
            _backgroundView.image = [PhotoPaintSettingsView landscapeRightBackgroundImage];
        }
            break;
            
        default:
        {
            _backgroundView.image = [PhotoPaintSettingsView portraitBackgroundImage];
        }
            break;
    }
    
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    switch (self.interfaceOrientation)
    {
        case UIInterfaceOrientationLandscapeLeft:
        {
            _backgroundView.image = [TGTintedImage([UIImage imageNamed:@"PaintPopupLandscapeLeftBackground"], UIColorRGB(0xf7f7f7)) resizableImageWithCapInsets:UIEdgeInsetsMake(32.0f, 32.0f, 32.0f, 32.0f)];
            _backgroundView.frame = CGRectMake(PhotoTextSettingsViewMargin - 13.0f, PhotoTextSettingsViewMargin, self.frame.size.width - PhotoTextSettingsViewMargin * 2 + 13.0f, self.frame.size.height - PhotoTextSettingsViewMargin * 2);
        }
            break;
            
        case UIInterfaceOrientationLandscapeRight:
        {
            _backgroundView.image = [TGTintedImage([UIImage imageNamed:@"PaintPopupLandscapeRightBackground"], UIColorRGB(0xf7f7f7)) resizableImageWithCapInsets:UIEdgeInsetsMake(32.0f, 32.0f, 32.0f, 32.0f)];
            _backgroundView.frame = CGRectMake(PhotoTextSettingsViewMargin, PhotoTextSettingsViewMargin, self.frame.size.width - PhotoTextSettingsViewMargin * 2 + 13.0f, self.frame.size.height - PhotoTextSettingsViewMargin * 2);
        }
            break;
            
        default:
        {
            _backgroundView.image = [TGTintedImage([UIImage imageNamed:@"PaintPopupPortraitBackground"], UIColorRGB(0xf7f7f7)) resizableImageWithCapInsets:UIEdgeInsetsMake(32.0f, 32.0f, 32.0f, 32.0f)];
            _backgroundView.frame = CGRectMake(PhotoTextSettingsViewMargin, PhotoTextSettingsViewMargin, self.frame.size.width - PhotoTextSettingsViewMargin * 2, self.frame.size.height - PhotoTextSettingsViewMargin * 2 + 13.0f);
        }
            break;
    }

    CGFloat thickness = TGScreenPixel;
    
    [_fontViews enumerateObjectsUsingBlock:^(ModernButton *view, NSUInteger index, __unused BOOL *stop)
    {
        view.frame = CGRectMake(PhotoTextSettingsViewMargin, PhotoTextSettingsViewMargin + PhotoTextSettingsItemHeight * index, self.frame.size.width - PhotoTextSettingsViewMargin * 2, PhotoTextSettingsItemHeight);

    }];

    [_fontSeparatorViews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger index, __unused BOOL *stop)
    {
        view.frame = CGRectMake(PhotoTextSettingsViewMargin + 44.0f, PhotoTextSettingsViewMargin + PhotoTextSettingsItemHeight * (index + 1), self.frame.size.width - PhotoTextSettingsViewMargin * 2 - 44.0f, thickness);
    }];
    
    _separatorView.frame = CGRectMake(PhotoTextSettingsViewMargin, PhotoTextSettingsViewMargin + PhotoTextSettingsItemHeight * _fontViews.count, self.frame.size.width - PhotoTextSettingsViewMargin * 2, thickness);
}

@end
