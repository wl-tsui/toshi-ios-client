#import "PhotoEditorBlurView.h"
#import "Common.h"

const CGFloat PhotoEditorBlurViewOverscreenSize = 3000;

@interface PhotoEditorBlurView ()
{
    UIImageView *_maskView;
    UIView *_leftView;
    UIView *_topView;
    UIView *_rightView;
    UIView *_bottomView;
}
@end

@implementation PhotoEditorBlurView

- (instancetype)initWithType:(BlurToolType)type
{
    self = [super initWithFrame:CGRectZero];
    if (self != nil)
    {
        UIColor *overlayColor = UIColorRGBA(0xffffff, 0.75f);
        UIColor *transparentColor = UIColorRGBA(0xffffff, 0.0f);
        
        static UIImage *radialBlurImage = nil;
        static UIImage *linearBlurImage = nil;
        static dispatch_once_t radialBlurOnceToken;
        static dispatch_once_t linearBlurOnceToken;
        
        UIImage *blurImage = nil;
        
        switch (type)
        {
            case BlurToolTypeRadial:
            {
                dispatch_once(&radialBlurOnceToken, ^
                {
                    UIGraphicsBeginImageContextWithOptions(CGSizeMake(100.0f, 100.0f), false, 0.0f);
                    CGContextRef context = UIGraphicsGetCurrentContext();

                    CGColorRef colors[3] = {
                        CGColorRetain(transparentColor.CGColor),
                        CGColorRetain(overlayColor.CGColor)
                    };

                    CFArrayRef colorsArray = CFArrayCreate(kCFAllocatorDefault, (const void **)&colors, 2, NULL);
                    CGFloat locations[2] = {0.3f, 0.9f};

                    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
                    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, colorsArray, (CGFloat const *)&locations);

                    CFRelease(colorsArray);
                    CFRelease(colors[0]);
                    CFRelease(colors[1]);

                    CGColorSpaceRelease(colorSpace);
                    
                    CGContextDrawRadialGradient(context, gradient, CGPointMake(50.0f, 50.0f), 0, CGPointMake(50.0f, 50.0f), 50.0f, kCGGradientDrawsAfterEndLocation);

                    CFRelease(gradient);

                    radialBlurImage = UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                });
                
                blurImage = radialBlurImage;
            }
                break;
                
            case BlurToolTypeLinear:
            {
                dispatch_once(&linearBlurOnceToken, ^
                {
                    UIGraphicsBeginImageContextWithOptions(CGSizeMake(1.0f, 100.0f), false, 0.0f);
                    CGContextRef context = UIGraphicsGetCurrentContext();

                    CGColorRef colors[4] = {
                        CGColorRetain(overlayColor.CGColor),
                        CGColorRetain(transparentColor.CGColor),
                        CGColorRetain(transparentColor.CGColor),
                        CGColorRetain(overlayColor.CGColor)
                    };

                    CFArrayRef colorsArray = CFArrayCreate(kCFAllocatorDefault, (const void **)&colors, 4, NULL);
                    CGFloat locations[4] = {0.0f, 0.3f, 0.7f, 1.0f};

                    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
                    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, colorsArray, (CGFloat const *)&locations);

                    CFRelease(colorsArray);
                    CFRelease(colors[0]);
                    CFRelease(colors[1]);
                    CFRelease(colors[2]);
                    CFRelease(colors[3]);

                    CGColorSpaceRelease(colorSpace);

                    CGContextDrawLinearGradient(context, gradient, CGPointMake(0.0f, 0.0f), CGPointMake(0.0f, 100.0f), 0);

                    CFRelease(gradient);

                    linearBlurImage = UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                });
                
                blurImage = linearBlurImage;
            }
                break;
                
            default:
                break;
        }
        
        _maskView = [[UIImageView alloc] initWithImage:blurImage];
        [self addSubview:_maskView];
        
        switch (type)
        {
            case BlurToolTypeRadial:
            {
                _leftView = [[UIView alloc] initWithFrame:CGRectZero];
                _leftView.backgroundColor = overlayColor;
                [self addSubview:_leftView];
                
                _rightView = [[UIView alloc] initWithFrame:CGRectZero];
                _rightView.backgroundColor = overlayColor;
                [self addSubview:_rightView];
            }
            case BlurToolTypeLinear:
            {
                _topView = [[UIView alloc] initWithFrame:CGRectZero];
                _topView.backgroundColor = overlayColor;
                [self addSubview:_topView];
                
                _bottomView = [[UIView alloc] initWithFrame:CGRectZero];
                _bottomView.backgroundColor = overlayColor;
                [self addSubview:_bottomView];
            }
                break;
            default:
                break;
        }
    }
    return self;
}

- (void)layoutSubviews
{
    if (_leftView != nil && _rightView != nil)
    {
        _maskView.frame = self.bounds;
        _topView.frame = CGRectMake(0, -PhotoEditorBlurViewOverscreenSize, _maskView.bounds.size.width, PhotoEditorBlurViewOverscreenSize);
        _bottomView.frame = CGRectMake(0, _maskView.bounds.size.height, _maskView.bounds.size.width, PhotoEditorBlurViewOverscreenSize);
        _leftView.frame = CGRectMake(-PhotoEditorBlurViewOverscreenSize, -PhotoEditorBlurViewOverscreenSize, PhotoEditorBlurViewOverscreenSize, _maskView.bounds.size.height + PhotoEditorBlurViewOverscreenSize * 2);
        _rightView.frame = CGRectMake(_maskView.bounds.size.width, -PhotoEditorBlurViewOverscreenSize, PhotoEditorBlurViewOverscreenSize, _maskView.bounds.size.height + PhotoEditorBlurViewOverscreenSize * 2);
    }
    else
    {
        _maskView.frame = CGRectMake(-PhotoEditorBlurViewOverscreenSize, 0, self.bounds.size.width + PhotoEditorBlurViewOverscreenSize * 2, self.bounds.size.height);
        _topView.frame = CGRectMake(_maskView.frame.origin.x, -PhotoEditorBlurViewOverscreenSize, _maskView.bounds.size.width, PhotoEditorBlurViewOverscreenSize);
        _bottomView.frame = CGRectMake(_maskView.frame.origin.x, _maskView.bounds.size.height, _maskView.bounds.size.width, PhotoEditorBlurViewOverscreenSize);
    }
}

@end
