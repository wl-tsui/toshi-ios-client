#import "TGMediaAvatarMenuMixin.h"

#import "AppDelegate.h"

#import "Camera.h"
#import "AccessChecker.h"
#import "ImageUtils.h"
#import "TGActionSheet.h"

#import "MenuSheetController.h"
#import "OverlayFormsheetWindow.h"

#import "CameraPreviewView.h"
#import "AttachmentCameraView.h"
#import "AttachmentCarouselItemView.h"

#import "CameraController.h"
#import "TGImagePickerController.h"
#import "MediaAssetsController.h"

@interface TGMediaAvatarMenuMixin ()
{
    ViewController *_parentController;
    bool _hasDeleteButton;
    bool _personalPhoto;
}
@end

@implementation TGMediaAvatarMenuMixin

- (instancetype)initWithParentController:(ViewController *)parentController hasDeleteButton:(bool)hasDeleteButton
{
    return [self initWithParentController:parentController hasDeleteButton:hasDeleteButton personalPhoto:false];
}

- (instancetype)initWithParentController:(ViewController *)parentController hasDeleteButton:(bool)hasDeleteButton personalPhoto:(bool)personalPhoto
{
    self = [super init];
    if (self != nil)
    {
        _parentController = parentController;
        _hasDeleteButton = hasDeleteButton;
        _personalPhoto = false;
    }
    return self;
}

- (void)present
{
    [_parentController.view endEditing:true];
    
    [self _presentAvatarMenu];
}

- (void)_presentAvatarMenu
{
    __weak TGMediaAvatarMenuMixin *weakSelf = self;
    MenuSheetController *controller = [[MenuSheetController alloc] init];
    controller.dismissesByOutsideTap = true;
    controller.hasSwipeGesture = true;
    controller.didDismiss = ^(bool manual)
    {
        if (!manual)
            return;
        
        __strong TGMediaAvatarMenuMixin *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        
        if (strongSelf.didDismiss != nil)
            strongSelf.didDismiss();
    };
    
    __weak MenuSheetController *weakController = controller;
    
    NSMutableArray *itemViews = [[NSMutableArray alloc] init];
    
    AttachmentCarouselItemView *carouselItem = [[AttachmentCarouselItemView alloc] initWithCamera:true selfPortrait:_personalPhoto forProfilePhoto:true assetType:MediaAssetPhotoType];
    carouselItem.parentController = _parentController;
    carouselItem.openEditor = true;
    carouselItem.cameraPressed = ^(AttachmentCameraView *cameraView)
    {
        __strong TGMediaAvatarMenuMixin *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        
        __strong MenuSheetController *strongController = weakController;
        if (strongController == nil)
            return;
        
        [strongSelf _displayCameraWithView:cameraView menuController:strongController];
    };
    carouselItem.avatarCompletionBlock = ^(UIImage *resultImage)
    {
        __strong TGMediaAvatarMenuMixin *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        
        __strong MenuSheetController *strongController = weakController;
        if (strongController == nil)
            return;
        
        if (strongSelf.didFinishWithImage != nil)
            strongSelf.didFinishWithImage(resultImage);
        
        [strongController dismissAnimated:false];
    };
    [itemViews addObject:carouselItem];
    
    MenuSheetButtonItemView *galleryItem = [[MenuSheetButtonItemView alloc] initWithTitle:@"Choose Photo" type:MenuSheetButtonTypeDefault action:^
    {
        __strong TGMediaAvatarMenuMixin *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        
        __strong MenuSheetController *strongController = weakController;
        if (strongController == nil)
            return;
        
        [strongController dismissAnimated:true];
        [strongSelf _displayMediaPicker];
    }];
    [itemViews addObject:galleryItem];
        
    if (_hasDeleteButton)
    {
        MenuSheetButtonItemView *deleteItem = [[MenuSheetButtonItemView alloc] initWithTitle:@"GroupInfo.SetGroupPhotoDelete" type:MenuSheetButtonTypeDestructive action:^
        {
            __strong TGMediaAvatarMenuMixin *strongSelf = weakSelf;
            if (strongSelf == nil)
                return;
            
            __strong MenuSheetController *strongController = weakController;
            if (strongController == nil)
                return;
            
            [strongController dismissAnimated:true];
            [strongSelf _performDelete];
        }];
        [itemViews addObject:deleteItem];
    }
    
    MenuSheetButtonItemView *cancelItem = [[MenuSheetButtonItemView alloc] initWithTitle:@"Cancel" type:MenuSheetButtonTypeCancel action:^
    {
        __strong TGMediaAvatarMenuMixin *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        
        __strong MenuSheetController *strongController = weakController;
        if (strongController == nil)
            return;
        
        [strongController dismissAnimated:true manual:true];
    }];
    [itemViews addObject:cancelItem];
    
    [controller setItemViews:itemViews];
    
    [controller presentInViewController:_parentController sourceView:nil animated:true];
}

- (void)_presentLegacyAvatarMenu
{
    NSMutableArray *actions = [[NSMutableArray alloc] init];
    
    if ([Camera cameraAvailable])
        [actions addObject:[[TGActionSheetAction alloc] initWithTitle:@"TakePhoto" action:@"camera"]];
    
    [actions addObject:[[TGActionSheetAction alloc] initWithTitle:@"ChoosePhoto" action:@"choosePhoto"]];
//    [actions addObject:[[TGActionSheetAction alloc] initWithTitle:@"Conversation.SearchWebImages" action:@"searchWeb"]];
    
    if (_hasDeleteButton)
    {
        [actions addObject:[[TGActionSheetAction alloc] initWithTitle:@"GroupInfo.SetGroupPhotoDelete" action:@"delete" type:TGActionSheetActionTypeDestructive]];
    }
    
    [actions addObject:[[TGActionSheetAction alloc] initWithTitle:@"Cancel" action:@"cancel" type:TGActionSheetActionTypeCancel]];
    
    [[[TGActionSheet alloc] initWithTitle:nil actions:actions actionBlock:^(TGMediaAvatarMenuMixin *controller, NSString *action)
    {
        if ([action isEqualToString:@"camera"])
            [controller _displayCameraWithView:nil menuController:nil];
        else if ([action isEqualToString:@"choosePhoto"])
            [controller _displayMediaPicker];
        else if ([action isEqualToString:@"delete"])
            [controller _performDelete];
        else if ([action isEqualToString:@"cancel"] && controller.didDismiss != nil)
            controller.didDismiss();
    } target:self] showInView:_parentController.view];
}

- (void)_displayCameraWithView:(AttachmentCameraView *)cameraView menuController:(MenuSheetController *)menuController
{
    if (![AccessChecker checkCameraAuthorizationStatusWithAlertDismissComlpetion:nil])
        return;
    
    CameraController *controller = nil;
    CGSize screenSize = TGScreenSize();
    
    if (cameraView.previewView != nil)
        controller = [[CameraController alloc] initWithCamera:cameraView.previewView.camera previewView:cameraView.previewView intent:CameraControllerAvatarIntent];
    else
        controller = [[CameraController alloc] initWithIntent:CameraControllerAvatarIntent];
    
    controller.shouldStoreCapturedAssets = true;
    
    CameraControllerWindow *controllerWindow = [[CameraControllerWindow alloc] initWithParentController:_parentController contentController:controller];
    controllerWindow.hidden = false;
    controllerWindow.clipsToBounds = true;
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        controllerWindow.frame = CGRectMake(0, 0, screenSize.width, screenSize.height);
    else
        controllerWindow.frame = [UIScreen mainScreen].bounds;
    
    bool standalone = true;
    CGRect startFrame = CGRectMake(0, screenSize.height, screenSize.width, screenSize.height);
    if (cameraView != nil)
    {
        standalone = false;
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
            startFrame = CGRectZero;
        else
            startFrame = [controller.view convertRect:cameraView.previewView.frame fromView:cameraView];
    }
    
    [cameraView detachPreviewView];
    [controller beginTransitionInFromRect:startFrame];
    
    __weak TGMediaAvatarMenuMixin *weakSelf = self;
    __weak CameraController *weakCameraController = controller;
    __weak AttachmentCameraView *weakCameraView = cameraView;
    
    controller.beginTransitionOut = ^CGRect
    {
        __strong CameraController *strongCameraController = weakCameraController;
        if (strongCameraController == nil)
            return CGRectZero;
        
        __strong AttachmentCameraView *strongCameraView = weakCameraView;
        if (strongCameraView != nil)
        {
            [strongCameraView willAttachPreviewView];
            if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
                return CGRectZero;
            
            return [strongCameraController.view convertRect:strongCameraView.frame fromView:strongCameraView.superview];
        }
        
        return CGRectZero;
    };
    
    controller.finishedTransitionOut = ^
    {
        __strong AttachmentCameraView *strongCameraView = weakCameraView;
        if (strongCameraView == nil)
            return;
        
        [strongCameraView attachPreviewViewAnimated:true];
    };
    
    controller.finishedWithPhoto = ^(UIImage *resultImage, __unused NSString *caption, __unused NSArray *stickers)
    {
        __strong TGMediaAvatarMenuMixin *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        
        if (strongSelf.didFinishWithImage != nil)
            strongSelf.didFinishWithImage(resultImage);
        
        [menuController dismissAnimated:false];
    };
}

- (void)_displayMediaPicker
{
    if (![AccessChecker checkPhotoAuthorizationStatusForIntent:PhotoAccessIntentRead alertDismissCompletion:nil])
        return;
    
    __weak TGMediaAvatarMenuMixin *weakSelf = self;
    void (^presentBlock)(MediaAssetsController *) = nil;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        presentBlock = ^(MediaAssetsController *controller)
        {
            __strong TGMediaAvatarMenuMixin *strongSelf = weakSelf;
            if (strongSelf == nil)
                return;
            
            controller.dismissalBlock = ^
            {
                __strong TGMediaAvatarMenuMixin *strongSelf = weakSelf;
                if (strongSelf == nil)
                    return;
                
                [strongSelf->_parentController dismissViewControllerAnimated:true completion:nil];
                
                if (strongSelf.didDismiss != nil)
                    strongSelf.didDismiss();
            };
            
            [strongSelf->_parentController presentViewController:controller animated:true completion:nil];
        };
    }
    
    void (^showMediaPicker)(MediaAssetGroup *) = ^(MediaAssetGroup *group)
    {
        __strong TGMediaAvatarMenuMixin *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        
        MediaAssetsController *controller = [MediaAssetsController controllerWithAssetGroup:group intent:MediaAssetsControllerIntentSetProfilePhoto];
        __weak MediaAssetsController *weakController = controller;
        controller.avatarCompletionBlock = ^(UIImage *resultImage)
        {
            __strong TGMediaAvatarMenuMixin *strongSelf = weakSelf;
            if (strongSelf == nil)
                return;
            
            if (strongSelf.didFinishWithImage != nil)
                strongSelf.didFinishWithImage(resultImage);
            
            __strong MediaAssetsController *strongController = weakController;
            if (strongController != nil && strongController.dismissalBlock != nil)
                strongController.dismissalBlock();
        };
        presentBlock(controller);
    };
    
    if ([MediaAssetsLibrary authorizationStatus] == MediaLibraryAuthorizationStatusNotDetermined)
    {
        [MediaAssetsLibrary requestAuthorizationForAssetType:MediaAssetAnyType completion:^(__unused MediaLibraryAuthorizationStatus status, MediaAssetGroup *cameraRollGroup)
         {
             if (![AccessChecker checkPhotoAuthorizationStatusForIntent:PhotoAccessIntentRead alertDismissCompletion:nil])
                 return;
             
             showMediaPicker(cameraRollGroup);
         }];
    }
    else
    {
        showMediaPicker(nil);
    }
}

- (void)imagePickerController:(TGImagePickerController *)__unused imagePicker didFinishPickingWithAssets:(NSArray *)assets
{
    UIImage *resultImage = nil;
    
    if (assets.count != 0)
    {
        if ([assets[0] isKindOfClass:[UIImage class]])
            resultImage = assets[0];
    }
    
    if (self.didFinishWithImage != nil)
        self.didFinishWithImage(resultImage);
    
    [_parentController dismissViewControllerAnimated:true completion:nil];
}

- (void)legacyCameraControllerCompletedWithNoResult
{
    [_parentController dismissViewControllerAnimated:true completion:nil];
    
    if (self.didDismiss != nil)
        self.didDismiss();
}

- (void)_performDelete
{
    if (self.didFinishWithDelete != nil)
        self.didFinishWithDelete();
}

@end
