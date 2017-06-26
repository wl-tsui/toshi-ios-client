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
#import <OpenGLES/ES2/gl.h>

@interface PaintShader : NSObject

@property (nonatomic, readonly) GLuint program;
@property (nonatomic, readonly) NSDictionary *uniforms;

- (instancetype)initWithVertexShader:(NSString *)vertexShader fragmentShader:(NSString *)fragmentShader attributes:(NSArray *)attributes uniforms:(NSArray *)uniforms;

- (GLuint)uniformForKey:(NSString *)key;

- (void)cleanResources;

@end
