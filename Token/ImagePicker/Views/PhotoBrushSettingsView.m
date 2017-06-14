#import "PhotoBrushSettingsView.h"
#import "PhotoEditorSliderView.h"

#import "ImageUtils.h"
#import "ModernButton.h"

#import "PaintBrush.h"
#import "PaintBrushPreview.h"

#import "Common.h"

const CGFloat PhotoBrushSettingsViewMargin = 19.0f;
const CGFloat PhotoBrushSettingsItemHeight = 44.0f;

@interface PhotoBrushSettingsView ()
{
    NSArray *_brushes;
    PaintBrushPreview *_preview;
    
    UIImageView *_backgroundView;
    
    NSArray *_brushViews;
    NSArray *_brushSeparatorViews;
    UIImageView *_selectedCheckView;
    
    UIImage *_landscapeLeftBackgroundImage;
    UIImage *_landscapeRightBackgroundImage;
    UIImage *_portraitBackgroundImage;
}
@end

@implementation PhotoBrushSettingsView

@synthesize interfaceOrientation = _interfaceOrientation;

- (instancetype)initWithBrushes:(NSArray *)brushes preview:(PaintBrushPreview *)preview
{
    self = [super initWithFrame:CGRectZero];
    if (self != nil)
    {
        _brushes = brushes;
        _preview = preview;
        
        _interfaceOrientation = UIInterfaceOrientationPortrait;
        
        _backgroundView = [[UIImageView alloc] init];
        //_backgroundView.alpha = 0.98f;
        [self addSubview:_backgroundView];
        
        NSMutableArray *brushViews = [[NSMutableArray alloc] init];
        NSMutableArray *separatorViews = [[NSMutableArray alloc] init];
        [brushes enumerateObjectsUsingBlock:^(__unused PaintBrush *brush, NSUInteger index, __unused BOOL *stop)
        {
            ModernButton *button = [[ModernButton alloc] initWithFrame:CGRectMake(0, PhotoBrushSettingsViewMargin + index * PhotoBrushSettingsItemHeight, 0, 0)];
            button.tag = index;
            button.imageView.contentMode = UIViewContentModeCenter;
            button.contentEdgeInsets = UIEdgeInsetsMake(0.0f, 30.0f, 0.0f, 0.0f);
            [button addTarget:self action:@selector(brushButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:button];
            
            [brushViews addObject:button];
            
            if (index != brushes.count - 1)
            {
                UIView *separatorView = [[UIView alloc] init];
                separatorView.backgroundColor = UIColorRGB(0xd6d6da);
                [self addSubview:separatorView];
                
                [separatorViews addObject:separatorView];
            }
        }];
        
        _brushViews = brushViews;
        _brushSeparatorViews = separatorViews;
        
        _selectedCheckView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"PaintCheck"]];
        _selectedCheckView.frame = CGRectMake(15.0f, 16.0f, _selectedCheckView.frame.size.width, _selectedCheckView.frame.size.height);
    }
    return self;
}

- (void)brushButtonPressed:(ModernButton *)sender
{
    [sender addSubview:_selectedCheckView];
    
    if (self.brushChanged != nil)
        self.brushChanged(_brushes[sender.tag]);
}

- (void)present
{
    self.alpha = 0.0f;

    self.layer.rasterizationScale = TGScreenScaling();
    self.layer.shouldRasterize = true;
    
    [self _setupBrushPreviews];
    
    [UIView animateWithDuration:0.2 animations:^
    {
        self.alpha = 1.0f;
    } completion:^(__unused BOOL finished)
    {
        //self.layer.shouldRasterize = false;
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

- (void)_setupBrushPreviews
{
    [_brushes enumerateObjectsUsingBlock:^(PaintBrush *aBrush, NSUInteger index, __unused BOOL *stop)
    {
        UIImage *image = aBrush.previewImage;
        if (image == nil)
        {
            image = [_preview imageForBrush:aBrush size:CGSizeMake([self sizeThatFits:CGSizeZero].width - 85.0f, PhotoBrushSettingsItemHeight)];
            aBrush.previewImage = image;
        }
        
        [_brushViews[index] setImage:image forState:UIControlStateNormal];
    }];
}

- (PaintBrush *)brush
{
    return _brushes[_selectedCheckView.superview.tag];
}

- (void)setBrush:(PaintBrush *)brush
{
    [_brushes enumerateObjectsUsingBlock:^(PaintBrush *aBrush, NSUInteger index, BOOL *stop)
    {
        if ([brush isEqual:aBrush])
        {
            [_brushViews[index] addSubview:_selectedCheckView];
            *stop = true;
        }
    }];
}

- (CGSize)sizeThatFits:(CGSize)__unused size
{
    return CGSizeMake(256, _brushViews.count * PhotoBrushSettingsItemHeight + PhotoBrushSettingsViewMargin * 2);
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
            _backgroundView.frame = CGRectMake(PhotoBrushSettingsViewMargin - 13.0f, PhotoBrushSettingsViewMargin, self.frame.size.width - PhotoBrushSettingsViewMargin * 2 + 13.0f, self.frame.size.height - PhotoBrushSettingsViewMargin * 2);
        }
            break;
            
        case UIInterfaceOrientationLandscapeRight:
        {
            _backgroundView.frame = CGRectMake(PhotoBrushSettingsViewMargin, PhotoBrushSettingsViewMargin, self.frame.size.width - PhotoBrushSettingsViewMargin * 2 + 13.0f, self.frame.size.height - PhotoBrushSettingsViewMargin * 2);
        }
            break;
            
        default:
        {
            _backgroundView.frame = CGRectMake(PhotoBrushSettingsViewMargin, PhotoBrushSettingsViewMargin, self.frame.size.width - PhotoBrushSettingsViewMargin * 2, self.frame.size.height - PhotoBrushSettingsViewMargin * 2 + 13.0f);
        }
            break;
    }
    
    CGFloat thickness = TGScreenPixel;
    
    [_brushViews enumerateObjectsUsingBlock:^(ModernButton *view, NSUInteger index, __unused BOOL *stop)
    {
        view.frame = CGRectMake(PhotoBrushSettingsViewMargin, PhotoBrushSettingsViewMargin + PhotoBrushSettingsItemHeight * index, self.frame.size.width - PhotoBrushSettingsViewMargin * 2, PhotoBrushSettingsItemHeight);
         
    }];
    
    [_brushSeparatorViews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger index, __unused BOOL *stop)
    {
        view.frame = CGRectMake(PhotoBrushSettingsViewMargin + 44.0f, PhotoBrushSettingsViewMargin + PhotoBrushSettingsItemHeight * (index + 1), self.frame.size.width - PhotoBrushSettingsViewMargin * 2 - 44.0f, thickness);
    }];
}

@end
