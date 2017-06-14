#import "AttachmentCameraCell.h"

NSString *const AttachmentCameraCellIdentifier = @"AttachmentCameraCell";

@implementation AttachmentCameraCell

- (void)attachCameraViewIfNeeded:(AttachmentCameraView *)cameraView
{
    if (_cameraView == cameraView)
        return;
    
    _cameraView = cameraView;
    _cameraView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _cameraView.frame = self.bounds;
    [self addSubview:cameraView];
}

@end
