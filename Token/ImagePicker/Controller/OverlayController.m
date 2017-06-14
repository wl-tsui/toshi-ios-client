#import "OverlayController.h"

#import "OverlayControllerWindow.h"

@interface OverlayController ()

@end

@implementation OverlayController

- (id)init
{
    self = [super init];
    if (self != nil)
    {
    }
    return self;
}

- (void)dismiss
{
    OverlayControllerWindow *overlayWindow = _overlayWindow;
    [overlayWindow dismiss];
}

@end
