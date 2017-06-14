#import "PaintingData.h"

#import <SSignalKit/SQueue.h>

#import "PaintUtils.h"

#import "MediaEditingContext.h"
#import "PaintUndoManager.h"

@interface PaintingData ()
{
    UIImage *_image;
    NSData *_data;
    
    UIImage *(^_imageRetrievalBlock)(void);
}
@end

@implementation PaintingData

+ (instancetype)dataWithPaintingData:(NSData *)data image:(UIImage *)image entities:(NSArray *)entities undoManager:(PaintUndoManager *)undoManager
{
    PaintingData *paintingData = [[PaintingData alloc] init];
    paintingData->_data = data;
    paintingData->_image = image;
    paintingData->_entities = entities;
    paintingData->_undoManager = undoManager;
    return paintingData;
}

+ (instancetype)dataWithPaintingImagePath:(NSString *)imagePath
{
    PaintingData *paintingData = [[PaintingData alloc] init];
    paintingData->_imagePath = imagePath;
    return paintingData;
}

+ (void)storePaintingData:(PaintingData *)data inContext:(MediaEditingContext *)context forItem:(id<MediaEditableItem>)item forVideo:(bool)video
{
    [[PaintingData queue] dispatch:^
    {
        NSURL *dataUrl = nil;
        NSURL *imageUrl = nil;
        
        NSData *compressedData = PaintGZipDeflate(data.data);
        [context setPaintingData:compressedData image:data.image forItem:item dataUrl:&dataUrl imageUrl:&imageUrl forVideo:video];
        
        __weak MediaEditingContext *weakContext = context;
        [[SQueue mainQueue] dispatch:^
        {
            data->_dataPath = dataUrl.path;
            data->_imagePath = imageUrl.path;
            data->_data = nil;
            
            data->_imageRetrievalBlock = ^UIImage *
            {
                __strong MediaEditingContext *strongContext = weakContext;
                if (strongContext != nil)
                    return [strongContext paintingImageForItem:item];
                
                return nil;
            };
        }];
    }];
}

+ (void)facilitatePaintingData:(PaintingData *)data
{
    [[PaintingData queue] dispatch:^
    {
        if (data->_imagePath != nil)
            data->_image = nil;
    }];
}

- (void)dealloc
{
    [self.undoManager reset];
}

- (NSData *)data
{
    if (_data != nil)
        return _data;
    else if (_dataPath != nil)
        return PaintGZipInflate([[NSData alloc] initWithContentsOfFile:_dataPath]);
    else
        return nil;
}

- (UIImage *)image
{
    if (_image != nil)
        return _image;
    else if (_imageRetrievalBlock != nil)
        return _imageRetrievalBlock();
    else
        return nil;
}

- (NSArray *)stickers
{
//    NSMutableSet *stickers = [[NSMutableSet alloc] init];
//    for (PhotoPaintEntity *entity in self.entities)
//    {
//        if ([entity isKindOfClass:[PhotoPaintStickerEntity class]])
//            [stickers addObject:((PhotoPaintStickerEntity *)entity).document];
//    }
    return [NSArray new];// [stickers allObjects];
}

- (BOOL)isEqual:(id)object
{
    if (object == self)
        return true;
    
    if (!object || ![object isKindOfClass:[self class]])
        return false;
    
    PaintingData *data = (PaintingData *)object;
    return [data.entities isEqual:self.entities] && ((data.data != nil && [data.data isEqualToData:self.data]) || (data.data == nil && self.data == nil));
}

+ (SQueue *)queue
{
    static dispatch_once_t onceToken;
    static SQueue *queue;
    dispatch_once(&onceToken, ^
    {
        queue = [SQueue wrapConcurrentNativeQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)];
    });
    return queue;
}

@end
