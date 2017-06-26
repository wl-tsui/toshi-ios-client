#import "PaintSwatch.h"

@implementation PaintSwatch

- (BOOL)isEqual:(id)object
{
    if (object == self)
        return true;
    
    if (!object || ![object isKindOfClass:[self class]])
        return false;
    
    PaintSwatch *swatch = (PaintSwatch *)object;
    return [swatch.color isEqual:self.color] && fabs(swatch.colorLocaton - self.colorLocaton) < FLT_EPSILON && fabs(swatch.brushWeight - self.brushWeight) < FLT_EPSILON;
}

+ (instancetype)swatchWithColor:(UIColor *)color colorLocation:(CGFloat)colorLocation brushWeight:(CGFloat)brushWeight
{
    PaintSwatch *swatch = [[PaintSwatch alloc] init];
    swatch->_color = color;
    swatch->_colorLocaton = colorLocation;
    swatch->_brushWeight = brushWeight;
    
    return swatch;
}

@end
