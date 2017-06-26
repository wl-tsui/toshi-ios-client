#import "CameraShutterButton.h"

#import "JNWSpringAnimation.h"

#import "CameraInterfaceAssets.h"
#import "ModernButton.h"

@interface CameraShutterButton ()
{
    UIImageView *_ringView;
    ModernButton *_buttonView;
}
@end

@implementation CameraShutterButton

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {
        CGFloat padding = [self innerPadding];
        
        NSString *key = [NSString stringWithFormat:@"%f", frame.size.width];
        
        static NSMutableDictionary *ringImages = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^
        {
            ringImages = [[NSMutableDictionary alloc] init];
        });
        
        UIImage *ringImage = ringImages[key];
        if (ringImage == nil)
        {
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(frame.size.width, frame.size.height), false, 0.0f);
            CGContextRef context = UIGraphicsGetCurrentContext();
            
            CGFloat thickness = (padding < 8.0f) ? 5.0f : 6.0f;
            
            CGContextSetStrokeColorWithColor(context, [CameraInterfaceAssets normalColor].CGColor);
            CGContextSetLineWidth(context, thickness);
            CGContextStrokeEllipseInRect(context, CGRectMake(thickness / 2.0f, thickness / 2.0f, frame.size.width - thickness, frame.size.height - thickness));
            
            ringImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            ringImages[key] = ringImage;
        }
        
        self.exclusiveTouch = true;
        
        _ringView = [[UIImageView alloc] initWithFrame:self.bounds];
        _ringView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _ringView.image = ringImage;
        [self addSubview:_ringView];
                
        _buttonView = [[ModernButton alloc] initWithFrame:CGRectMake(padding, padding, self.frame.size.width - padding * 2, self.frame.size.height - padding * 2)];
        _buttonView.backgroundColor = [CameraInterfaceAssets normalColor];
        _buttonView.layer.cornerRadius = _buttonView.frame.size.width / 2;
        [_buttonView addTarget:self action:@selector(buttonReleased) forControlEvents:UIControlEventTouchUpInside];
        [_buttonView addTarget:self action:@selector(buttonPressed) forControlEvents:UIControlEventTouchDown];
        [self addSubview:_buttonView];
        
        [self setButtonMode:CameraShutterButtonNormalMode animated:false];
    }
    return self;
}

- (CGFloat)innerPadding
{
    if (self.frame.size.width == 50.0f)
        return 7.0f;
    
    return 8.0f;
}

- (CGFloat)squarePadding
{
    if (self.frame.size.width == 50.0f)
        return 15.0f;
    
    return 19.0f;
}

- (void)setButtonMode:(CameraShutterButtonMode)mode animated:(bool)animated
{
    CGFloat padding = [self innerPadding];
    CGFloat squarePadding = [self squarePadding];
    
    if (animated)
    {
        switch (mode)
        {
            case CameraShutterButtonNormalMode:
            {
                [UIView animateWithDuration:0.25f animations:^
                {
                    _buttonView.backgroundColor = [CameraInterfaceAssets normalColor];
                }];
            }
                break;
                
            case CameraShutterButtonVideoMode:
            {
                [UIView animateWithDuration:0.25f animations:^
                {
                    _buttonView.backgroundColor = [CameraInterfaceAssets redColor];
                }];
            }
                break;
                
            case CameraShutterButtonRecordingMode:
            {
                [UIView animateWithDuration:0.25f animations:^
                {
                    _buttonView.backgroundColor = [CameraInterfaceAssets redColor];
                }];
                
                JNWSpringAnimation *cornersAnimation = [JNWSpringAnimation animationWithKeyPath:@"cornerRadius"];
                cornersAnimation.fromValue = @(_buttonView.layer.cornerRadius);
                cornersAnimation.toValue = @(4);
                cornersAnimation.mass = 5;
                cornersAnimation.damping = 100;
                cornersAnimation.stiffness = 300;
                [_buttonView.layer addAnimation:cornersAnimation forKey:@"cornerRadius"];
                _buttonView.layer.cornerRadius = 4;
                
                JNWSpringAnimation *boundsAnimation = [JNWSpringAnimation animationWithKeyPath:@"bounds"];
                boundsAnimation.fromValue = [NSValue valueWithCGRect:_buttonView.layer.bounds];
                boundsAnimation.toValue = [NSValue valueWithCGRect:CGRectMake(0, 0, self.frame.size.width - squarePadding * 2, self.frame.size.height - squarePadding * 2)];
                boundsAnimation.mass = 5;
                boundsAnimation.damping = 100;
                boundsAnimation.stiffness = 300;
                [_buttonView.layer addAnimation:boundsAnimation forKey:@"bounds"];
                _buttonView.layer.bounds = CGRectMake(0, 0, self.frame.size.width - squarePadding * 2, self.frame.size.height - squarePadding * 2);
            }
                break;
                
            default:
                break;
        }
    }
    else
    {
        switch (mode)
        {
            case CameraShutterButtonNormalMode:
            {
                _buttonView.backgroundColor = [CameraInterfaceAssets normalColor];
                _buttonView.frame = CGRectMake(padding, padding, self.frame.size.width - padding * 2, self.frame.size.height - padding * 2);
                _buttonView.layer.cornerRadius = _buttonView.frame.size.width / 2;
            }
                break;
                
            case CameraShutterButtonVideoMode:
            {
                [_buttonView.layer removeAllAnimations];
                _buttonView.backgroundColor = [CameraInterfaceAssets redColor];
                _buttonView.frame = CGRectMake(padding, padding, self.frame.size.width - padding * 2, self.frame.size.height - padding * 2);
                _buttonView.layer.cornerRadius = _buttonView.frame.size.width / 2;
            }
                break;
                
            case CameraShutterButtonRecordingMode:
            {
                _buttonView.backgroundColor = [CameraInterfaceAssets redColor];
                _buttonView.frame = CGRectMake(squarePadding, squarePadding, self.frame.size.width - squarePadding * 2, self.frame.size.height - squarePadding * 2);
                _buttonView.layer.cornerRadius = 4;
            }
                break;
                
            default:
                break;
        }
    }
}

- (void)setEnabled:(bool)__unused enabled animated:(bool)__unused animated
{
    
}

- (void)buttonReleased
{
    [self sendActionsForControlEvents:UIControlEventTouchUpInside];
}

- (void)buttonPressed
{
    [self sendActionsForControlEvents:UIControlEventTouchDown];
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];

    [_buttonView setHighlighted:highlighted];
}

- (void)setHighlighted:(bool)highlighted animated:(bool)animated
{
    if (animated)
    {
        [UIView animateWithDuration:0.25 animations:^
        {
            [self setHighlighted:highlighted]; 
        }];
    }
    else
    {
        [self setHighlighted:highlighted];
    }
}

@end
