#import "ModernMediaListItem.h"

@protocol MediaEditableItem;
@class MediaEditingContext;

@protocol ModernMediaListEditableItem <ModernMediaListItem>

@property (nonatomic, strong) MediaEditingContext *editingContext;

- (id<MediaEditableItem>)editableMediaItem;

@end
