#import "MediaAttachment.h"
#import "Common.h"

@implementation MediaAttachment

@synthesize type = _type;
@synthesize isMeta = _isMeta;

- (void)serialize:(NSMutableData *)__unused data
{
    TGLog(@"***** MediaAttachment: default implementation not provided");
}

@end
