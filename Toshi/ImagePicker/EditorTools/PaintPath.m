#import "PaintPath.h"

@implementation PaintPoint

+ (instancetype)pointWithX:(CGFloat)x y:(CGFloat)y z:(CGFloat)z
{
    PaintPoint *point = [[PaintPoint alloc] init];
    point.x = x;
    point.y = y;
    point.z = z;
    return point;
}

+ (instancetype)pointWithCGPoint:(CGPoint)inPoint z:(CGFloat)z
{
    PaintPoint *point = [[PaintPoint alloc] init];
    point.x = inPoint.x;
    point.y = inPoint.y;
    point.z = z;
    return point;
}

- (instancetype)copyWithZone:(NSZone *)__unused zone
{
    return [PaintPoint pointWithX:_x y:_y z:_z];
}

- (BOOL)isEqual:(id)object
{
    if (object == self)
        return true;
    
    if (!object || ![object isKindOfClass:[self class]])
        return false;
    
    PaintPoint *point = (PaintPoint *)object;
    return (_x == point.x && _y == point.y && _z == point.z);
}

- (CGPoint)CGPoint
{
    return CGPointMake(_x, _y);
}

- (PaintPoint *)add:(PaintPoint *)point
{
    return [PaintPoint pointWithX:_x + point.x y:_y + point.y z:_z + point.z];
}

- (PaintPoint *)subtract:(PaintPoint *)point
{
    return [PaintPoint pointWithX:_x - point.x y:_y - point.y z:_z - point.z];
}

- (PaintPoint *)multiplyByScalar:(CGFloat)scalar
{
    return [PaintPoint pointWithX:_x * scalar y:_y * scalar z:_z * scalar];
}

- (PaintPoint *)normalize
{
    return [self multiplyByScalar:1.0f / [self magnitude]];
}

- (CGFloat)magnitude
{
    return sqrt(_x * _x + _y * _y + _z * _z);
}

- (CGFloat)distanceTo:(PaintPoint *)point
{
    CGFloat xD = _x - point.x;
    CGFloat yD = _y - point.y;
    CGFloat zD = _z - point.z;
    
    return sqrt(xD * xD + yD * yD + zD * zD);
}

@end


@interface PaintPath ()
{
    NSMutableArray *_points;
}
@end

@implementation PaintPath

- (instancetype)init
{
    self = [super init];
    if (self != nil)
    {
        _points = [[NSMutableArray alloc] init];
    }
    return self;
}

- (instancetype)initWithPoint:(PaintPoint *)point
{
    self = [self init];
    if (self != nil)
    {
        [_points addObject:point];
    }
    return self;
}

- (instancetype)initWithPoints:(NSArray *)points
{
    self = [self init];
    if (self != nil)
    {
        [_points addObjectsFromArray:points];
    }
    return self;
}

- (NSArray *)points
{
    return [_points copy];
}

- (void)addPoint:(PaintPoint *)point
{
    [_points addObject:point];
}

@end
