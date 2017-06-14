#import "PhotoMaskPosition.h"

@implementation PhotoMaskPosition

+ (instancetype)maskPositionWithCenter:(CGPoint)center scale:(CGFloat)scale angle:(CGFloat)angle
{
    PhotoMaskPosition *maskPosition = [[PhotoMaskPosition alloc] init];
    maskPosition->_center = center;
    maskPosition->_scale = scale;
    maskPosition->_angle = angle;
    return maskPosition;
}

@end
