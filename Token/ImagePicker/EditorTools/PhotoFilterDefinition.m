#import "PhotoFilterDefinition.h"

@implementation PhotoFilterDefinition

+ (PhotoFilterDefinition *)originalFilterDefinition
{
    PhotoFilterDefinition *definition = [[PhotoFilterDefinition alloc] init];
    definition->_type = PhotoFilterTypePassThrough;
    definition->_identifier = @"0_0";
    definition->_title = @"Original";
    
    return definition;
}

+ (PhotoFilterDefinition *)definitionWithDictionary:(NSDictionary *)dictionary
{
    PhotoFilterDefinition *definition = [[PhotoFilterDefinition alloc] init];
    
    if ([dictionary[@"type"] isEqualToString:@"lookup"])
        definition->_type = PhotoFilterTypeLookup;
    else if ([dictionary[@"type"] isEqualToString:@"custom"])
        definition->_type = PhotoFilterTypeCustom;
    else
        return nil;
    
    definition->_identifier = dictionary[@"id"];
    definition->_title = dictionary[@"title"];
    definition->_lookupFilename = dictionary[@"lookup_name"];
    definition->_shaderFilename = dictionary[@"shader_name"];
    definition->_textureFilenames = dictionary[@"texture_names"];
    
    return definition;
}

@end
