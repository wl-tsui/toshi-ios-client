// Copyright (c) 2017 Token Browser, Inc
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

#import <Foundation/Foundation.h>

typedef enum {
    PhotoFilterTypePassThrough,
    PhotoFilterTypeLookup,
    PhotoFilterTypeCustom
} PhotoFilterType;

@interface PhotoFilterDefinition : NSObject

@property (readonly, nonatomic) NSString *identifier;
@property (readonly, nonatomic) NSString *title;
@property (readonly, nonatomic) PhotoFilterType type;
@property (readonly, nonatomic) NSString *lookupFilename;
@property (readonly, nonatomic) NSString *shaderFilename;
@property (readonly, nonatomic) NSArray *textureFilenames;

+ (PhotoFilterDefinition *)originalFilterDefinition;
+ (PhotoFilterDefinition *)definitionWithDictionary:(NSDictionary *)dictionary;

@end
