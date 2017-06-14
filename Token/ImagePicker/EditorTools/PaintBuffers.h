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

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <QuartzCore/QuartzCore.h>

@interface PaintBuffers : NSObject

@property (nonatomic, weak) EAGLContext *context;
@property (nonatomic, readonly) CAEAGLLayer *layer;
@property (nonatomic, readonly) GLuint renderbuffer;
@property (nonatomic, readonly) GLuint framebuffer;
@property (nonatomic, readonly) GLuint stencilBuffer;
@property (nonatomic, readonly) GLint width;
@property (nonatomic, readonly) GLint height;

- (bool)update;
- (void)present;

+ (instancetype)buffersWithGLContext:(EAGLContext *)context layer:(CAEAGLLayer *)layer;

@end
