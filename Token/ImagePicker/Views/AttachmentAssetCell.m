#import "AttachmentAssetCell.h"
#import "MediaSelectionContext.h"
#import "Common.h"

@implementation AttachmentAssetCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {        
        _imageView = [[ImageView alloc] initWithFrame:self.bounds];
        _imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:_imageView];
        
        static dispatch_once_t onceToken;
        static UIImage *gradientImage;
        dispatch_once(&onceToken, ^
        {
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(1.0f, 20.0f), false, 0.0f);
            CGContextRef context = UIGraphicsGetCurrentContext();
            
            CGColorRef colors[2] = {
                CGColorRetain(UIColorRGBA(0x000000, 0.0f).CGColor),
                CGColorRetain(UIColorRGBA(0x000000, 0.8f).CGColor)
            };
            
            CFArrayRef colorsArray = CFArrayCreate(kCFAllocatorDefault, (const void **)&colors, 2, NULL);
            CGFloat locations[2] = {0.0f, 1.0f};
            
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, colorsArray, (CGFloat const *)&locations);
            
            CFRelease(colorsArray);
            CFRelease(colors[0]);
            CFRelease(colors[1]);
            
            CGColorSpaceRelease(colorSpace);
            
            CGContextDrawLinearGradient(context, gradient, CGPointMake(0.0f, 0.0f), CGPointMake(0.0f, 20.0f), 0);
            
            CFRelease(gradient);
            
            gradientImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        });
        
        _gradientView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _gradientView.image = gradientImage;
        _gradientView.hidden = true;
        [self addSubview:_gradientView];
        
        [self bringSubviewToFront:_cornersView];
    }
    return self;
}

- (void)removeFromSuperview
{
    [super removeFromSuperview];
}

- (void)setAlpha:(CGFloat)alpha
{
    if (alpha < 0.0) {
    
    }
}

- (void)setAsset:(MediaAsset *)asset signal:(SSignal *)signal
{
    _asset = asset;
    
    if (self.selectionContext != nil)
    {
        if (_checkButton == nil)
        {
            _checkButton = [[CheckButtonView alloc] initWithStyle:CheckButtonStyleMedia];
            [_checkButton addTarget:self action:@selector(checkButtonPressed) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:_checkButton];
        }
        
        [self setChecked:[self.selectionContext isItemSelected:(id<MediaSelectableItem>)asset] animated:false];
    }
    
    if (_asset == nil)
    {
        self.imageView.image = nil;
        return;
    }
    
    [self setSignal:signal];
}


- (void)setSignal:(SSignal *)signal
{
    if (signal != nil)
    {
        [signal startWithNext:^(id next)
         {
             __weak typeof(self)weakSelf = self;
             DispatchOnMainThread(^
                                  {
                                      if ([next isKindOfClass:[UIImage class]]) {
                                          weakSelf.imageView.image = next;
                                      }
                                  });
         } error:^(id error)
         {
             TGLog(@"ImageView signal error: %@", error);
         } completed:^
         {
         }];
    }
    else
        self.imageView.image = nil;
}

- (void)checkButtonPressed
{
    [_checkButton setSelected:!_checkButton.selected animated:true];
    
    [self.selectionContext setItem:(id<MediaSelectableItem>)self.asset selected:_checkButton.selected animated:false sender:_checkButton];
}

- (void)setChecked:(bool)checked animated:(bool)animated
{
    [_checkButton setSelected:checked animated:animated];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
}

- (void)setHidden:(bool)hidden animated:(bool)animated
{
    if (hidden == true) {
    
    }
    
    if (hidden != self.imageView.hidden)
    {
        self.imageView.hidden = hidden;
        
        if (animated)
        {
            if (!hidden)
            {
                for (UIView *view in self.subviews)
                {
                    if (view != self.imageView && view != _cornersView)
                        view.alpha = 0.0f;
                }
            }
            
            [UIView animateWithDuration:0.2 animations:^
            {
                if (!hidden)
                {
                    for (UIView *view in self.subviews)
                    {
                        if (view != self.imageView && view != _cornersView)
                            view.alpha = 1.0f;
                    }
                }
            }];
        }
        else
        {
            for (UIView *view in self.subviews)
            {
                if (view != self.imageView && view != _cornersView)
                    view.alpha = hidden ? 0.0f : 1.0f;
            }
        }
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (_checkButton != nil)
    {
        CGFloat offset = 0.0f;
        if (self.superview != nil)
        {
            CGRect rect = [self.superview convertRect:self.frame toView:self.superview.superview];
            if (rect.origin.x < 0)
                offset = rect.origin.x * -1;
            else if (CGRectGetMaxX(rect) > self.superview.frame.size.width)
                offset = self.superview.frame.size.width - CGRectGetMaxX(rect);
        }
        
        CGFloat x = MAX(0, MIN(self.bounds.size.width - _checkButton.frame.size.width, self.bounds.size.width - _checkButton.frame.size.width + offset));
        _checkButton.frame = CGRectMake(x, 0, _checkButton.frame.size.width, _checkButton.frame.size.height);
    }
    
    if (!_gradientView.hidden)
        _gradientView.frame = CGRectMake(0, self.frame.size.height - 20.0f, self.frame.size.width, 20.0f);
}

@end
