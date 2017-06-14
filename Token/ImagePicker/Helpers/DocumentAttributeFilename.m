#import "DocumentAttributeFilename.h"
#import "Common.h"
#import "PSKeyValueCoder.h"

@implementation DocumentAttributeFilename

- (instancetype)initWithFilename:(NSString *)filename
{
    self = [super init];
    if (self != nil)
    {
        _filename = filename;
    }
    return self;
}

- (instancetype)initWithKeyValueCoder:(PSKeyValueCoder *)coder
{
    return [self initWithFilename:[coder decodeStringForCKey:"f"]];
}

- (void)encodeWithKeyValueCoder:(PSKeyValueCoder *)coder
{
    [coder encodeString:_filename forCKey:"f"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    return [self initWithFilename:[aDecoder decodeObjectForKey:@"filename"]];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    if (_filename != nil)
        [aCoder encodeObject:_filename forKey:@"filename"];
}

- (BOOL)isEqual:(id)object
{
    return [object isKindOfClass:[DocumentAttributeFilename class]] && TGObjectCompare(_filename, ((DocumentAttributeFilename *)object)->_filename);
}

@end
