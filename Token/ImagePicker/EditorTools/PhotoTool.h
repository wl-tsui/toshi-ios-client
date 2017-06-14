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

#import "PhotoEditorItem.h"
#import "PhotoProcessPass.h"

@class PhotoToolComposer;

typedef enum
{
    PhotoToolTypePass,
    PhotoToolTypeShader
} PhotoToolType;

@protocol CustomToolValue <NSObject>

- (id<CustomToolValue>)cleanValue;

@end

@interface PhotoTool : NSObject <PhotoEditorItem>
{
    PhotoProcessPass *_pass;
    
    NSString *_identifier;
    PhotoToolType _type;
    NSInteger _order;
    
    NSArray *_parameters;
    NSArray *_constants;
    
    CGFloat _minimumValue;
    CGFloat _maximumValue;
    CGFloat _defaultValue;
}

@property (nonatomic, readonly) PhotoToolType type;
@property (nonatomic, readonly) NSInteger order;
@property (nonatomic, readonly) UIImage *image;

@property (nonatomic, readonly) bool isHidden;

@property (nonatomic, readonly) NSString *shaderString;
@property (nonatomic, readonly) NSString *ancillaryShaderString;
@property (nonatomic, readonly) PhotoProcessPass *pass;

@property (nonatomic, weak) PhotoToolComposer *toolComposer;

- (void)invalidate;

- (NSString *)stringValue;

@end
