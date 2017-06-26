#import "AttachmentMenuCell.h"
#import "MenuSheetView.h"

const CGFloat AttachmentMenuCellCornerRadius = 5.5f;

@implementation AttachmentMenuCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {
        self.clipsToBounds = true;
        
        if (MenuSheetUseEffectView)
        {
            self.backgroundColor = [UIColor clearColor];
            self.layer.cornerRadius = AttachmentMenuCellCornerRadius;
        }
        else
        {
            self.backgroundColor = [UIColor whiteColor];
            
            static dispatch_once_t onceToken;
            static UIImage *cornersImage;
            dispatch_once(&onceToken, ^
            {
                CGRect rect = CGRectMake(0, 0, AttachmentMenuCellCornerRadius * 2 + 1.0f, AttachmentMenuCellCornerRadius * 2 + 1.0f);
                
                UIGraphicsBeginImageContextWithOptions(rect.size, false, 0);
                CGContextRef context = UIGraphicsGetCurrentContext();
                
                CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
                CGContextFillRect(context, rect);
                
                CGContextSetBlendMode(context, kCGBlendModeClear);
                
                CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
                CGContextFillEllipseInRect(context, rect);
                
                cornersImage = [UIGraphicsGetImageFromCurrentImageContext() resizableImageWithCapInsets:UIEdgeInsetsMake(AttachmentMenuCellCornerRadius, AttachmentMenuCellCornerRadius, AttachmentMenuCellCornerRadius, AttachmentMenuCellCornerRadius)];
                
                UIGraphicsEndImageContext();
            });
            
            _cornersView = [[UIImageView alloc] initWithImage:cornersImage];
            _cornersView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            _cornersView.frame = self.bounds;
            [self addSubview:_cornersView];
        }
    }
    return self;
}

@end
