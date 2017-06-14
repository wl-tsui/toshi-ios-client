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

#import "GPUImageOutput.h"

typedef enum {
    GPUPixelFormatBGRA = GL_BGRA,
    GPUPixelFormatRGBA = GL_RGBA,
    GPUPixelFormatRGB = GL_RGB
} GPUPixelFormat;

typedef enum {
    GPUPixelTypeUByte = GL_UNSIGNED_BYTE,
    GPUPixelTypeFloat = GL_FLOAT
} GPUPixelType;

@interface PhotoEditorRawDataInput : GPUImageOutput

- (instancetype)initWithBytes:(GLubyte *)bytesToUpload size:(CGSize)imageSize;
- (instancetype)initWithBytes:(GLubyte *)bytesToUpload size:(CGSize)imageSize pixelFormat:(GPUPixelFormat)pixelFormat;
- (instancetype)initWithBytes:(GLubyte *)bytesToUpload size:(CGSize)imageSize pixelFormat:(GPUPixelFormat)pixelFormat type:(GPUPixelType)pixelType;

@property (nonatomic, assign) GPUPixelFormat pixelFormat;
@property (nonatomic, assign) GPUPixelType   pixelType;

- (void)updateDataWithBytes:(GLubyte *)bytesToUpload size:(CGSize)imageSize;
- (void)processData;
- (void)processDataForTimestamp:(CMTime)frameTime;
- (CGSize)outputImageSize;
- (void)invalidate;

@end
