#import "PhotoFilterCell.h"

#import "PhotoFilter.h"
#import "PhotoFilterDefinition.h"

#import "PhotoEditorInterfaceAssets.h"

NSString * const PhotoFilterCellKind = @"PhotoFilterCellKind";

@interface PhotoFilterCell ()
{
    UIImageView *_imageView;
    UIImageView *_selectionView;
    UILabel *_titleLabel;
}
@end

@implementation PhotoFilterCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.width)];
        _imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:_imageView];
        
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, _imageView.frame.origin.y + _imageView.frame.size.height + 5, frame.size.width, 17)];
        _titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.font = [PhotoEditorInterfaceAssets editorItemTitleFont];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.textColor = [PhotoEditorInterfaceAssets editorItemTitleColor];
        _titleLabel.highlightedTextColor = [PhotoEditorInterfaceAssets editorActiveItemTitleColor];
        [self addSubview:_titleLabel];
        
        static UIImage *selectionImage = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^
        {
            CGFloat width = [PhotoFilterCell filterCellWidth];
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, width), false, 0.0f);
            CGContextRef context = UIGraphicsGetCurrentContext();
            CGContextSetFillColorWithColor(context, [PhotoEditorInterfaceAssets filterSelectionColor].CGColor);
            
            UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(3, 3, width - 2 * 3, width - 2 * 3)];
            [path appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(0, 0, width, width)]];
            path.usesEvenOddFillRule = true;
            [path fill];
            
            selectionImage = [UIGraphicsGetImageFromCurrentImageContext() resizableImageWithCapInsets:UIEdgeInsetsMake(3, 3, 3, 3)];
            UIGraphicsEndImageContext();
        });

        _selectionView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.width)];
        _selectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _selectionView.image = selectionImage;
        _selectionView.hidden = true;
        [self addSubview:_selectionView];
    }
    return self;
}

- (void)setPhotoFilter:(PhotoFilter *)photoFilter
{
    _filterIdentifier = photoFilter.identifier;
    _titleLabel.text = photoFilter.definition.title;
}

- (void)setFilterSelected:(BOOL)selected
{
    [super setSelected:selected];
    
    _titleLabel.highlighted = selected;
    _selectionView.hidden = !selected;
}

- (void)setImage:(UIImage *)image
{
    [self setImage:image animated:false];
}

- (void)setImage:(UIImage *)image animated:(bool)animated
{
    if (_imageView.image == nil)
        animated = false;
    
    if (animated)
    {
        UIImageView *transitionView = [[UIImageView alloc] initWithImage:_imageView.image];
        transitionView.frame = _imageView.frame;
        [self insertSubview:transitionView aboveSubview:_imageView];
        
        _imageView.image = image;
        
        [UIView animateWithDuration:0.3f animations:^
        {
            transitionView.alpha = 0.0f;
        } completion:^(__unused BOOL finished)
        {
            [transitionView removeFromSuperview];
        }];
    }
    else
    {
        _imageView.image = image;
    }
}

- (void)setSelected:(BOOL)__unused selected
{

}

- (void)setHighlighted:(BOOL)__unused highlighted
{

}

+ (CGFloat)filterCellWidth
{
    return 64;
}

@end
