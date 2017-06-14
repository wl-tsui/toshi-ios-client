#import "PhotoEntitiesContainerView.h"
#import "PhotoPaintEntityView.h"
#import "PhotoTextEntityView.h"

#import "PhotoEditorUtils.h"

@interface PhotoEntitiesContainerView () <UIGestureRecognizerDelegate>
{
    PhotoPaintEntityView *_currentView;
    UITapGestureRecognizer *_tapGestureRecognizer;
}
@end

@implementation PhotoEntitiesContainerView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {
        _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        _tapGestureRecognizer.delegate = self;
        [self addGestureRecognizer:_tapGestureRecognizer];
    }
    return self;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)__unused gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)__unused otherGestureRecognizer
{
    return false;
}

- (void)handleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    CGPoint location = [gestureRecognizer locationInView:self];
    
    NSMutableArray *intersectedViews = [[NSMutableArray alloc] init];
    for (PhotoPaintEntityView *view in self.subviews)
    {
        if (![view isKindOfClass:[PhotoPaintEntityView class]])
            continue;
        
        if ([view pointInside:[view convertPoint:location fromView:self] withEvent:nil])
            [intersectedViews addObject:view];
    }
    
    PhotoPaintEntityView *result = nil;
    if (intersectedViews.count > 1)
    {
        __block PhotoPaintEntityView *subresult = nil;
        [intersectedViews enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(PhotoPaintEntityView *view, __unused NSUInteger index, BOOL *stop)
        {
            if ([view precisePointInside:[view convertPoint:location fromView:self]])
            {
                subresult = view;
                *stop = true;
            }
        }];
        
        result = subresult ?: intersectedViews.lastObject;
    }
    else if (intersectedViews.count == 1)
    {
        result = intersectedViews.firstObject;
    }
    
    if (self.entitySelected != nil)
        self.entitySelected(result);
}

- (NSUInteger)entitiesCount
{
    return MAX(0, (NSInteger)self.subviews.count - 1);
}

- (PhotoPaintEntityView *)viewForUUID:(NSInteger)uuid
{
    for (PhotoPaintEntityView *view in self.subviews)
    {
        if (![view isKindOfClass:[PhotoPaintEntityView class]])
            continue;
        
        if (view.entityUUID == uuid)
            return view;
    }
    
    return nil;
}

- (void)removeViewWithUUID:(NSInteger)uuid
{
    for (PhotoPaintEntityView *view in self.subviews)
    {
        if (![view isKindOfClass:[PhotoPaintEntityView class]])
            continue;
        
        if (view.entityUUID == uuid)
        {
            [view removeFromSuperview];
            
            if (self.entityRemoved != nil)
                self.entityRemoved(view);
            break;
        }
    }
}

- (void)removeAll
{
    for (PhotoPaintEntityView *view in self.subviews)
    {
        if (![view isKindOfClass:[PhotoPaintEntityView class]])
            continue;
        
        [view removeFromSuperview];
    }
}

- (void)handlePinch:(UIPinchGestureRecognizer *)gestureRecognizer
{
    CGPoint location = [gestureRecognizer locationInView:self];
    
    switch (gestureRecognizer.state)
    {
        case UIGestureRecognizerStateBegan:
        {
            if (_currentView != nil)
                return;
            
            _currentView = [self viewForLocation:location];
        }
            break;
            
        case UIGestureRecognizerStateChanged:
        {
            if (_currentView == nil)
                return;
            
            CGFloat scale = gestureRecognizer.scale;
            [_currentView scale:scale absolute:false];
            
            [gestureRecognizer setScale:1.0f];
        }
            break;
            
        case UIGestureRecognizerStateEnded:
        {
            _currentView = nil;
        }
            break;
            
        case UIGestureRecognizerStateCancelled:
        {
            _currentView = nil;
        }
            break;
            
        default:
            break;
    }
}

- (void)handleRotate:(UIRotationGestureRecognizer *)gestureRecognizer
{
    CGPoint location = [gestureRecognizer locationInView:self];
    
    switch (gestureRecognizer.state)
    {
        case UIGestureRecognizerStateBegan:
        {
            if (_currentView != nil)
                return;
            
            _currentView = [self viewForLocation:location];
        }
            break;
            
        case UIGestureRecognizerStateChanged:
        {
            if (_currentView == nil)
                return;
            
            CGFloat rotation = gestureRecognizer.rotation;
            [_currentView rotate:rotation absolute:false];
            
            [gestureRecognizer setRotation:0.0f];
        }
            break;
            
        case UIGestureRecognizerStateEnded:
        {
            
        }
            break;
            
        case UIGestureRecognizerStateCancelled:
        {
            
        }
            break;
            
        default:
            break;
    }
}

- (PhotoPaintEntityView *)viewForLocation:(CGPoint)__unused location
{
    for (PhotoPaintEntityView *view in self.subviews)
    {
        if (![view isKindOfClass:[PhotoPaintEntityView class]])
            continue;
        
        if (view.selectionView != nil)
            return view;
    }
    
    return nil;
}

- (UIImage *)imageInRect:(CGRect)rect background:(UIImage *)background
{
    if (self.subviews.count < 2)
        return nil;
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(rect.size.width, rect.size.height), false, 1.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect bounds = CGRectMake(0, 0, rect.size.width, rect.size.height);
    [background drawInRect:bounds];
    
    for (PhotoPaintEntityView *view in self.subviews)
    {
        if (![view isKindOfClass:[PhotoPaintEntityView class]])
            continue;
        
         if ([view isKindOfClass:[PhotoTextEntityView class]])
        {
            [self drawView:view inContext:context withBlock:^
            {
                [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:false];
            }];
        }
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)drawView:(UIView *)view inContext:(CGContextRef)context withBlock:(void (^)(void))block
{
    CGContextSaveGState(context);
    
    CGContextTranslateCTM(context, view.center.x, view.center.y);
    CGContextConcatCTM(context, view.transform);
    CGContextTranslateCTM(context, -view.bounds.size.width / 2.0f, -view.bounds.size.height / 2.0f);
    
    block();
    
    CGContextRestoreGState(context);
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    bool pointInside = [super pointInside:point withEvent:event];
    if (!pointInside)
    {
        for (UIView *subview in self.subviews)
        {
            CGPoint convertedPoint = [self convertPoint:point toView:subview];
            if ([subview pointInside:convertedPoint withEvent:event])
                pointInside = true;
        }
    }
    return pointInside;
}

- (bool)isTrackingAnyEntityView
{
    bool tracking = false;
    for (PhotoPaintEntityView *view in self.subviews)
    {
        if (![view isKindOfClass:[PhotoPaintEntityView class]])
            continue;
        
        if (view.isTracking)
        {
            tracking = true;
            break;
        }
    }
    return tracking;
}

@end
