#import "MediaPickerGalleryGifItemView.h"
#import "MediaPickerGalleryGifItem.h"

#import "PhotoEditorUtils.h"
#import "StringUtils.h"
#import "Font.h"
#import "Common.h"

#import "MessageImageViewOverlayView.h"

#import "MediaAssetImageSignals.h"

@interface MediaPickerGalleryGifItemView ()
{
    UIView *_containerView;
    
    CGSize _imageSize;
    
    UITapGestureRecognizer *_tapGestureRecognizer;
    
    SMetaDisposable *_gifDataDisposable;
    
    MessageImageViewOverlayView *_progressView;
    bool _progressVisible;
    void (^_currentAvailabilityObserver)(bool);
    
    UILabel *_fileInfoLabel;
    SMetaDisposable *_attributesDisposable;
    
    bool _imageAvailable;
}
@end

@implementation MediaPickerGalleryGifItemView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {
        _containerView = [[UIView alloc] initWithFrame:self.bounds];
        _containerView.clipsToBounds = true;
        [self addSubview:_containerView];
        
        _imageView = [[ModernGalleryImageItemImageView alloc] init];
        [_containerView addSubview:_imageView];
        
        _fileInfoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 20)];
        _fileInfoLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _fileInfoLabel.backgroundColor = [UIColor clearColor];
        _fileInfoLabel.font = TGSystemFontOfSize(13.0f);
        _fileInfoLabel.textAlignment = NSTextAlignmentCenter;
        _fileInfoLabel.textColor = [UIColor whiteColor];
        
        _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap)];
        [_containerView addGestureRecognizer:_tapGestureRecognizer];
        
        _gifDataDisposable = [[SMetaDisposable alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_gifDataDisposable dispose];
    [_attributesDisposable dispose];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    if (_containerView == nil)
        return;
    
    _containerView.frame = self.bounds;
}

- (void)prepareForRecycle
{
    [_imageView reset];
    
    _imageAvailable = false;
    [self setProgressVisible:false value:0.0f animated:false];
}

- (void)setItem:(MediaPickerGalleryGifItem *)item synchronously:(bool)synchronously
{
    [super setItem:item synchronously:synchronously];
    
    _imageSize = item.asset.dimensions;
    
    if (item.asset == nil)
    {
        [self.imageView reset];
    }
    else
    {
        SSignal *imageSignal = [MediaAssetImageSignals imageForAsset:item.asset imageType:(item.immediateThumbnailImage != nil) ? MediaAssetImageTypeScreen : MediaAssetImageTypeFastScreen size:CGSizeMake(1280, 1280)];
        
        if (item.immediateThumbnailImage != nil)
            imageSignal = [[SSignal single:item.immediateThumbnailImage] then:imageSignal];

        [self.imageView setSignal:imageSignal];
        
        __weak MediaPickerGalleryGifItemView *weakSelf = self;
        [_gifDataDisposable setDisposable:[[MediaAssetImageSignals imageDataForAsset:item.asset] startWithNext:^(id next)
        {
            __strong MediaPickerGalleryGifItemView *strongSelf = weakSelf;
            if (strongSelf == nil)
                return;
            
            if ([next isKindOfClass:[NSNumber class]])
            {
                float value = [next floatValue];
                [strongSelf setProgressVisible:value < 1.0f - FLT_EPSILON value:value animated:true];
            }
            else if ([next isKindOfClass:[MediaAssetImageData class]])
            {
                [strongSelf setProgressVisible:false value:1.0f animated:true];
                
                MediaAssetImageData *data = (MediaAssetImageData *)next;
               // [strongSelf _playWithData:data.imageData];
                
                strongSelf->_imageAvailable = true;
                if (strongSelf->_currentAvailabilityObserver != nil)
                    strongSelf->_currentAvailabilityObserver(true);
            }
        }]];
    }
    
    if (!item.asFile)
        return;
    
    _fileInfoLabel.text = nil;
    
    if (_attributesDisposable == nil)
        _attributesDisposable = [[SMetaDisposable alloc] init];
    
    __weak MediaPickerGalleryGifItemView *weakSelf = self;
    [_attributesDisposable setDisposable:[[[MediaAssetImageSignals fileAttributesForAsset:item.asset] deliverOn:[SQueue mainQueue]] startWithNext:^(MediaAssetImageFileAttributes *next)
    {
        __strong MediaPickerGalleryGifItemView *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        
        NSString *extension = @"GIF";
        NSString *fileSize = [StringUtils stringForFileSize:next.fileSize precision:2];
        NSString *dimensions = [NSString stringWithFormat:@"%dx%d", (int)next.dimensions.width, (int)next.dimensions.height];
        
        strongSelf->_fileInfoLabel.text = [NSString stringWithFormat:@"%@ • %@ • %@", extension, fileSize, dimensions];
    }]];
}

- (void)singleTap
{
    if ([self.item conformsToProtocol:@protocol(ModernGallerySelectableItem)])
    {
        MediaSelectionContext *selectionContext = ((id<ModernGallerySelectableItem>)self.item).selectionContext;
        id<MediaSelectableItem> item = ((id<ModernGallerySelectableItem>)self.item).selectableMediaItem;
        
        [selectionContext toggleItemSelection:item animated:true sender:nil];
    }
    else
    {
        id<ModernGalleryItemViewDelegate> delegate = self.delegate;
        if ([delegate respondsToSelector:@selector(itemViewDidRequestInterfaceShowHide:)])
            [delegate itemViewDidRequestInterfaceShowHide:self];
    }
}

- (void)setProgressVisible:(bool)progressVisible value:(CGFloat)value animated:(bool)animated
{
    _progressVisible = progressVisible;
    
    if (progressVisible && _progressView == nil)
    {
        _progressView = [[MessageImageViewOverlayView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 50.0f, 50.0f)];
        _progressView.userInteractionEnabled = false;
        
        _progressView.frame = (CGRect){{CGFloor((self.frame.size.width - _progressView.frame.size.width) / 2.0f), CGFloor((self.frame.size.height - _progressView.frame.size.height) / 2.0f)}, _progressView.frame.size};
    }
    
    if (progressVisible)
    {
        if (_progressView.superview == nil)
            [_containerView addSubview:_progressView];
        
        _progressView.alpha = 1.0f;
    }
    else if (_progressView.superview != nil)
    {
        if (animated)
        {
            [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^
             {
                 _progressView.alpha = 0.0f;
             } completion:^(BOOL finished)
             {
                 if (finished)
                     [_progressView removeFromSuperview];
             }];
        }
        else
            [_progressView removeFromSuperview];
    }
    
    [_progressView setProgress:value cancelEnabled:false animated:animated];
}

- (SSignal *)contentAvailabilityStateSignal
{
    __weak MediaPickerGalleryGifItemView *weakSelf = self;
    return [[SSignal alloc] initWithGenerator:^id<SDisposable>(SSubscriber *subscriber)
    {
        __strong MediaPickerGalleryGifItemView *strongSelf = weakSelf;
        if (strongSelf != nil)
        {
            [subscriber putNext:@(strongSelf->_imageAvailable)];
            strongSelf->_currentAvailabilityObserver = ^(bool available)
            {
                [subscriber putNext:@(available)];
            };
        }
        
        return nil;
    }];
}

- (UIView *)footerView
{
    if (((MediaPickerGalleryItem *)self.item).asFile)
        return _fileInfoLabel;
    
    return nil;
}

- (UIView *)transitionView
{
    return _containerView;
}

- (CGRect)transitionViewContentRect
{
    return [_imageView convertRect:_imageView.bounds toView:[self transitionView]];
}

@end
