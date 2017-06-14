#import "DocumentAttributeVideo.h"

#import "PSKeyValueCoder.h"

@implementation DocumentAttributeVideo

- (instancetype)initWithSize:(CGSize)size duration:(int32_t)duration {
    self = [super init];
    if (self != nil) {
        _size = size;
        _duration = duration;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    return [self initWithSize:[aDecoder decodeCGSizeForKey:@"size"] duration:[aDecoder decodeInt32ForKey:@"duration"]];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeCGSize:_size forKey:@"size"];
    [aCoder encodeInt32:_duration forKey:@"duration"];
}

- (instancetype)initWithKeyValueCoder:(PSKeyValueCoder *)coder {
    return [self initWithSize:CGSizeMake([coder decodeInt32ForCKey:"s.w"], [coder decodeInt32ForCKey:"s.h"]) duration:[coder decodeInt32ForCKey:"d"]];
}

- (void)encodeWithKeyValueCoder:(PSKeyValueCoder *)coder {
    [coder encodeInt32:(int32_t)_size.width forCKey:"s.w"];
    [coder encodeInt32:(int32_t)_size.height forCKey:"s.h"];
    [coder encodeInt32:_duration forCKey:"d"];
}

- (BOOL)isEqual:(id)object {
    return [object isKindOfClass:[DocumentAttributeVideo class]] && CGSizeEqualToSize(_size, ((DocumentAttributeVideo *)object)->_size) && _duration == ((DocumentAttributeVideo *)object)->_duration;
}

@end
