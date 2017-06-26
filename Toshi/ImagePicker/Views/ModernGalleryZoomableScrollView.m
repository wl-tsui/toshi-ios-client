#import "ModernGalleryZoomableScrollView.h"

#import "DoubleTapGestureRecognizer.h"

@interface ModernGalleryZoomableScrollView () <DoubleTapGestureRecognizerDelegate>

@end

@implementation ModernGalleryZoomableScrollView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {
        DoubleTapGestureRecognizer *recognizer = [[DoubleTapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapGesture:)];
        recognizer.consumeSingleTap = true;
        [self addGestureRecognizer:recognizer];
        
        _normalZoomScale = 1.0f;
    }
    return self;
}

- (void)doubleTapGesture:(DoubleTapGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateRecognized)
    {
        if (recognizer.doubleTapped)
        {
            if (_doubleTapped)
                _doubleTapped([recognizer locationInView:self]);
        }
        else
        {
            if (_singleTapped)
                _singleTapped();
        }
    }
}

- (void)doubleTapGestureRecognizerSingleTapped:(DoubleTapGestureRecognizer *)__unused recognizer
{
    if (_singleTapped)
        _singleTapped();
}

@end
