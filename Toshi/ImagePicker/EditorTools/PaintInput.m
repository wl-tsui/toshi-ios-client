#import "PaintInput.h"
#import <CoreGraphics/CoreGraphics.h>

#import "PaintPanGestureRecognizer.h"

#import "Painting.h"
#import "PaintPath.h"
#import "PaintState.h"
#import "PaintCanvas.h"
#import "PaintUtils.h"
#import "Common.h"

@interface PaintInput ()
{
    bool _first;
    bool _moved;
    bool _clearBuffer;
    
    CGPoint _lastLocation;
    CGFloat _lastRemainder;
    
    PaintPoint *_points[3];
    NSInteger _pointsCount;
}
@end

@implementation PaintInput

- (CGPoint)_location:(CGPoint)location inView:(UIView *)view
{
    location.y = view.bounds.size.height - location.y;
    
    CGAffineTransform inverted = CGAffineTransformInvert(_transform);
    CGPoint transformed = CGPointApplyAffineTransform(location, inverted);
    
    return transformed;
}

- (void)smoothenAndPaintPoints:(PaintCanvas *)canvas ended:(bool)ended
{
    NSMutableArray *points = [[NSMutableArray alloc] init];
    
    PaintPoint *prev2 = _points[0];
    PaintPoint *prev1 = _points[1];
    PaintPoint *cur = _points[2];
    
    CGPoint midPoint1 = PaintMultiplyPoint(PaintAddPoints(prev1.CGPoint, prev2.CGPoint), 0.5f);
    CGPoint midPoint2 = PaintMultiplyPoint(PaintAddPoints(cur.CGPoint, prev1.CGPoint), 0.5f);
    
    NSInteger segmentDistance = 2;
    CGFloat distance = PaintDistance(midPoint1, midPoint2);
    NSInteger numberOfSegments = (NSInteger)MIN(72, MAX(floor(distance / segmentDistance), 36));
    
    CGFloat t = 0.0f;
    CGFloat step = 1.0f / numberOfSegments;
    for (NSInteger j = 0; j < numberOfSegments; j++)
    {
        CGPoint pos = PaintAddPoints(PaintAddPoints(PaintMultiplyPoint(midPoint1, pow(1 - t, 2)), PaintMultiplyPoint(prev1.CGPoint, 2.0 * (1 - t) * t)), PaintMultiplyPoint(midPoint2, t * t));
        PaintPoint *newPoint = [PaintPoint pointWithCGPoint:pos z:1.0f];
        if (_first)
        {
            newPoint.edge = true;
            _first = false;
        }
        [points addObject:newPoint];
        t += step;
    }
    
    PaintPoint *finalPoint = [PaintPoint pointWithCGPoint:midPoint2 z:1.0f];
    if (ended)
        finalPoint.edge = true;
    [points addObject:finalPoint];
    
    PaintPath *path = [[PaintPath alloc] initWithPoints:points];
    [self paintPath:path inCanvas:canvas];
    
    for (int i = 0; i < 2; i++)
    {
        _points[i] = _points[i + 1];
    }
    
    if (ended)
        _pointsCount = 0;
    else
        _pointsCount = 2;
}

- (void)gestureBegan:(PaintPanGestureRecognizer *)recognizer
{
    _moved = false;
    _first = true;
    
    CGPoint location = [self _location:[recognizer locationInView:recognizer.view] inView:recognizer.view];
    _lastLocation = location;
    
    PaintPoint *point = [PaintPoint pointWithX:location.x y:location.y z:1.0f];
    _points[0] = point;
    _pointsCount = 1;
    
    _clearBuffer = true;
}

- (void)gestureMoved:(PaintPanGestureRecognizer *)recognizer
{
    PaintCanvas *canvas = (PaintCanvas *)recognizer.view;
    CGPoint location = [self _location:[recognizer locationInView:recognizer.view] inView:recognizer.view];
    CGFloat distanceMoved = PaintDistance(location, _lastLocation);
    
    if (distanceMoved < 8.0f)
        return;
    
    PaintPoint *point = [PaintPoint pointWithX:location.x y:location.y z:1.0f];
    _points[_pointsCount++] = point;
    
    if (_pointsCount == 3)
    {
        [self smoothenAndPaintPoints:canvas ended:false];
        _moved = true;
    }
    
    _lastLocation = location;
}

- (void)gestureEnded:(PaintPanGestureRecognizer *)recognizer
{
    PaintCanvas *canvas = (PaintCanvas *)recognizer.view;
    Painting *painting = canvas.painting;
    
    CGPoint location = [self _location:[recognizer locationInView:recognizer.view] inView:recognizer.view];
    if (!_moved)
    {
        PaintPoint *point = [PaintPoint pointWithX:location.x y:location.y z:1.0];
        point.edge = true;
        
        PaintPath *path = [[PaintPath alloc] initWithPoint:point];
        [self paintPath:path inCanvas:canvas];
    }
    else
    {
        [self smoothenAndPaintPoints:canvas ended:true];
    }
    
    _pointsCount = 0;
    
    [painting commitStrokeWithColor:canvas.state.color erase:canvas.state.isEraser];
}

- (void)gestureCanceled:(UIGestureRecognizer *)recognizer
{
     PaintCanvas *canvas = (PaintCanvas *) recognizer.view;
     Painting *painting = canvas.painting;

     painting.activePath = nil;
     [canvas draw];
}

- (void)paintPath:(PaintPath *)path inCanvas:(PaintCanvas *)canvas
{
    path.color = canvas.state.color;
    path.action = canvas.state.isEraser ? PaintActionErase : PaintActionDraw;
    path.brush = canvas.state.brush;
    path.baseWeight = canvas.state.weight;
    
    if (_clearBuffer)
        _lastRemainder = 0.0f;
    
    path.remainder = _lastRemainder;
    
    [canvas.painting paintStroke:path clearBuffer:_clearBuffer completion:^
    {
        DispatchOnMainThread(^
        {
            _lastRemainder = path.remainder;
            _clearBuffer = false;
        });
    }];
}

@end
