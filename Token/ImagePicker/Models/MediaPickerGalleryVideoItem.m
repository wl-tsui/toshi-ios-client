#import "MediaPickerGalleryVideoItem.h"

#import "MediaPickerGalleryVideoItemView.h"

#import "MediaAsset+MediaEditableItem.h"
#import "AVURLAsset+MediaItem.h"
#import "Common.h"

@interface MediaPickerGalleryVideoItem ()
{
    CGSize _dimensions;
    NSTimeInterval _duration;
}
@end

@implementation MediaPickerGalleryVideoItem

@synthesize selectionContext;
@synthesize editingContext;

- (instancetype)initWithFileURL:(NSURL *)fileURL dimensions:(CGSize)dimensions duration:(NSTimeInterval)duration
{
    self = [super init];
    if (self != nil)
    {
        _avAsset = [[AVURLAsset alloc] initWithURL:fileURL options:nil];
        _dimensions = dimensions;
        _duration = duration;
    }
    return self;
}

- (CGSize)dimensions
{
    if (self.asset != nil)
        return self.asset.dimensions;
    
    return _dimensions;
}

- (SSignal *)durationSignal
{
    if (self.asset != nil)
        return self.asset.actualVideoDuration;
    
    return [SSignal single:@(_duration)];
}

- (NSString *)uniqueId
{
    if (self.asset != nil)
        return self.asset.identifier;
    else if (self.avAsset != nil)
        return self.avAsset.URL.absoluteString;
    
    return nil;
}

- (id<MediaSelectableItem>)selectableMediaItem
{
    if (self.asset != nil)
        return self.asset;
    else if (self.avAsset != nil)
        return self.avAsset;
    
    return nil;
}

- (id<MediaEditableItem>)editableMediaItem
{
    if (self.asset != nil)
        return self.asset;
    else if (self.avAsset != nil)
        return self.avAsset;
    
    return nil;
}

- (PhotoEditorTab)toolbarTabs
{
    return PhotoEditorCaptionTab | PhotoEditorCropTab | PhotoEditorQualityTab;// PhotoEditorGifTab;
}

- (Class)viewClass
{
    return [MediaPickerGalleryVideoItemView class];
}

- (BOOL)isEqual:(id)object
{
    return [object isKindOfClass:[MediaPickerGalleryVideoItem class]]
    && ((self.asset != nil && TGObjectCompare(self.asset, ((MediaPickerGalleryItem *)object).asset)) ||
    (self.avAsset != nil && TGObjectCompare(self.avAsset.URL, ((MediaPickerGalleryVideoItem *)object).avAsset.URL)));
}

@end
