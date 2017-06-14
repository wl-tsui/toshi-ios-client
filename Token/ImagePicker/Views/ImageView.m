#import "ImageView.h"

#import "ImageManager.h"
#import "Common.h"
#import "UIImage+TG.h"

NSString *ImageViewOptionKeepCurrentImageAsPlaceholder = @"ImageViewOptionKeepCurrentImageAsPlaceholder";
NSString *ImageViewOptionEmbeddedImage = @"ImageViewOptionEmbeddedImage";
NSString *ImageViewOptionSynchronous = @"ImageViewOptionSynchronous";

@interface ImageView ()
{
    id _loadToken;
    volatile int _version;
    SMetaDisposable *_disposable;
    
    UIImageView *_transitionOverlayView;
}

@end

@implementation ImageView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {
        _disposable = [[SMetaDisposable alloc] init];
        _legacyAutomaticProgress = true;
    }
    return self;
}

- (void)dealloc
{
    [_disposable dispose];
    if (_loadToken != nil)
        [[ImageManager instance] cancelTaskWithId:_loadToken];
}

- (void)setExpectExtendedEdges:(bool)expectExtendedEdges
{
    if (_expectExtendedEdges != expectExtendedEdges)
    {
        _expectExtendedEdges = expectExtendedEdges;
        
        if (_expectExtendedEdges && _extendedInsetsImageView == nil)
        {
            self.image = nil;
            _extendedInsetsImageView = [[UIImageView alloc] init];
            [self addSubview:_extendedInsetsImageView];
        }
        else if (!_expectExtendedEdges && _extendedInsetsImageView != nil)
        {
            _extendedInsetsImageView.image = nil;
            [_extendedInsetsImageView removeFromSuperview];
            _extendedInsetsImageView = nil;
        }
    }
}

- (void)loadUri:(NSString *)uri withOptions:(NSDictionary *)__unused options
{
    [_disposable setDisposable:nil];
    _version++;
    
    UIImage *image = nil;
    
    bool beganAsyncTask = false;
    
    if (options[ImageViewOptionEmbeddedImage] != nil)
        image = options[ImageViewOptionEmbeddedImage];
    else
    {
//        __autoreleasing id asyncTaskId = nil;
//        __weak ImageView *weakSelf = self;
//        int version = _version;
//        CFAbsoluteTime loadStartTime = MTAbsoluteSystemTime();
//        bool legacyAutomaticProgress = _legacyAutomaticProgress;
//        image = [[ImageManager instance] loadImageSyncWithUri:uri canWait:[options[ImageViewOptionSynchronous] boolValue] decode:true acceptPartialData:true asyncTaskId:&asyncTaskId progress:^(float value)
//        {
//            if (legacyAutomaticProgress)
//            {
//                DispatchOnMainThread(^
//                {
//                    __strong ImageView *strongSelf = weakSelf;
//                    if (strongSelf != nil && strongSelf->_version == version)
//                        [strongSelf _updateProgress:value];
//                });
//            }
//        } partialCompletion:^(UIImage *partialImage)
//        {
//            DispatchOnMainThread(^
//            {
//                __strong ImageView *strongSelf = weakSelf;
//                if (strongSelf != nil && strongSelf->_version == version)
//                    [strongSelf _commitImage:partialImage partial:true loadTime:(NSTimeInterval)(MTAbsoluteSystemTime() - loadStartTime)];
//                else
//                    TGLog(@"[ImageView _commitImage version mismatch]");
//            });
//        } completion:^(UIImage *image)
//        {
//            DispatchOnMainThread(^
//            {
//                __strong ImageView *strongSelf = weakSelf;
//                if (strongSelf != nil && strongSelf->_version == version)
//                {
//                    if (legacyAutomaticProgress)
//                        [strongSelf _updateProgress:1.0f];
//                    [strongSelf _commitImage:image partial:false loadTime:(NSTimeInterval)(MTAbsoluteSystemTime() - loadStartTime)];
//                }
//                else
//                    TGLog(@"[ImageView _commitImage version mismatch]");
//            });
//        }];
//        
//        if (asyncTaskId != nil)
//        {
//            beganAsyncTask = true;
//            _loadToken = asyncTaskId;
//        }
    }
    
    if (image != nil)
        [self _commitImage:image partial:beganAsyncTask loadTime:0.0];
    else
    {
//        if (![options[ImageViewOptionKeepCurrentImageAsPlaceholder] boolValue])
//        {
//            UIImage *placeholderImage = [[ImageManager instance] loadAttributeSyncForUri:uri attribute:@"placeholder"];
//            if (placeholderImage != nil)
//                [self _commitImage:placeholderImage partial:beganAsyncTask loadTime:0.0];
//            else
//                [self performTransitionToImage:nil partial:true duration:0.0];
//        }
//        
//        CFAbsoluteTime loadStartTime = MTAbsoluteSystemTime();
//        
//        __weak ImageView *weakSelf = self;
//        int version = _version;
//        bool legacyAutomaticProgress = _legacyAutomaticProgress;
//        _loadToken = [[ImageManager instance] beginLoadingImageAsyncWithUri:uri decode:true progress:^(float value)
//        {
//            if (legacyAutomaticProgress)
//            {
//                DispatchOnMainThread(^
//                {
//                    __strong ImageView *strongSelf = weakSelf;
//                    if (strongSelf != nil && strongSelf->_version == version)
//                        [strongSelf _updateProgress:value];
//                });
//            }
//        } partialCompletion:^(UIImage *partialImage)
//        {
//            DispatchOnMainThread(^
//            {
//                __strong ImageView *strongSelf = weakSelf;
//                if (strongSelf != nil && strongSelf->_version == version)
//                    [strongSelf _commitImage:partialImage partial:true loadTime:(NSTimeInterval)(MTAbsoluteSystemTime() - loadStartTime)];
//                else
//                    TGLog(@"[ImageView _commitImage version mismatch]");
//            });
//        } completion:^(UIImage *image)
//        {
//            DispatchOnMainThread(^
//            {
//                __strong ImageView *strongSelf = weakSelf;
//                if (strongSelf != nil && strongSelf->_version == version)
//                {
//                    if (legacyAutomaticProgress)
//                        [strongSelf _updateProgress:1.0f];
//                    [strongSelf _commitImage:image partial:false loadTime:(NSTimeInterval)(MTAbsoluteSystemTime() - loadStartTime)];
//                }
//                else
//                    TGLog(@"[ImageView _commitImage version mismatch]");
//            });
//        }];
    }
}

- (void)_updateProgress:(float)value
{
    [self performProgressUpdate:value];
}

- (void)_commitImage:(UIImage *)image partial:(bool)partial loadTime:(NSTimeInterval)loadTime
{
    if (image == self.image)
        return;
    
    NSTimeInterval transitionDuration = 0.0;
    
    if (loadTime > DBL_EPSILON)
        transitionDuration = 0.16;
    
    [self performTransitionToImage:image partial:partial duration:transitionDuration];
}

- (void)reset
{
//    _version++;
//    [_disposable setDisposable:nil];
//    
//    if (_loadToken != nil)
//    {
//        [[ImageManager instance] cancelTaskWithId:_loadToken];
//        _loadToken = nil;
//    }
//    
//    [self _commitImage:nil partial:false loadTime:0.0];
}

- (UIImage *)currentImage
{
    if (_expectExtendedEdges)
        return _extendedInsetsImageView.image;
    return [super image];
}

- (void)performProgressUpdate:(CGFloat)__unused progress
{
}

- (void)performTransitionToImage:(UIImage *)image partial:(bool)__unused partial duration:(NSTimeInterval)duration
{
    if (((_expectExtendedEdges && _extendedInsetsImageView.image != nil) || (!_expectExtendedEdges && self.image != nil)) && duration > DBL_EPSILON)
    {
        self.alpha = 1.0f;
        _extendedInsetsImageView.alpha = 1.0f;
        
        if (_transitionOverlayView == nil)
            _transitionOverlayView = [[UIImageView alloc] init];
        
        _transitionOverlayView.frame = _extendedInsetsImageView == nil ? self.bounds : _extendedInsetsImageView.frame;
        [self insertSubview:_transitionOverlayView atIndex:0];
        
        _transitionOverlayView.image = _extendedInsetsImageView == nil ? self.image : _extendedInsetsImageView.image;
        _transitionOverlayView.backgroundColor = self.backgroundColor;
        _transitionOverlayView.alpha = 1.0;
        
        [UIView animateWithDuration:duration animations:^
        {
            _transitionOverlayView.alpha = 0.0;
        } completion:^(__unused BOOL finished)
        {
            _transitionOverlayView.image = nil;
            [_transitionOverlayView removeFromSuperview];
        }];
        
        if (_extendedInsetsImageView != nil)
        {
            _extendedInsetsImageView.alpha = 0.0f;
            [UIView animateWithDuration:duration / 2.0f animations:^
            {
                _extendedInsetsImageView.alpha = 1.0f;
            }];
        }
    }
    else if (image != nil && duration > DBL_EPSILON)
    {
        if (_expectExtendedEdges)
            _extendedInsetsImageView.alpha = 0.0f;
       // else
           // self.alpha = 0.0f;
        [UIView animateWithDuration:duration animations:^
        {
            if (_expectExtendedEdges)
                _extendedInsetsImageView.alpha = 1.0f;
            else
                self.alpha = 1.0f;
        } completion:^(__unused BOOL finished)
        {
        }];
    }
    else
    {
        self.alpha = 1.0f;
    }

    if (!_expectExtendedEdges)
    {
        self.image = image;
        if (_extendedInsetsImageView != nil)
        {
            [_extendedInsetsImageView removeFromSuperview];
            _extendedInsetsImageView = nil;
        }
    }
    else
    {
        UIEdgeInsets insets = [image extendedEdgeInsets];
        _extendedInsetsImageView.image = image;
        _extendedInsetsImageView.frame = CGRectMake(-insets.left, -insets.top, self.bounds.size.width + insets.left + insets.right, self.bounds.size.height + insets.top + insets.bottom);
    }
}

- (void)setSignal:(SSignal *)signal
{
    _version++;
    int version = _version;
    __weak ImageView *weakSelf = self;
    
    [_disposable setDisposable:[signal startWithNext:^(id next)
    {
        bool synchronous = [NSThread isMainThread];
        DispatchOnMainThread(^
        {
            __strong ImageView *strongSelf = weakSelf;
            if (strongSelf != nil && strongSelf->_version == version)
            {
                if ([next isKindOfClass:[UIImage class]])
                    [strongSelf _commitImage:next partial:[next degraded] && ![next edited] loadTime:synchronous ? 0.0 : 1.0];
                else if ([next respondsToSelector:@selector(floatValue)])
                    [strongSelf _updateProgress:[next floatValue]];
            }
        });
    } error:^(id error)
    {
        TGLog(@"ImageView signal error: %@", error);
    } completed:^
    {
    }]];
}

@end
