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
#import "GPUImageContext.h"

typedef struct
{
    GLubyte red;
    GLubyte green;
    GLubyte blue;
    GLubyte alpha;
} PGByteColorVector;

@protocol GPURawDataProcessor;

@interface PhotoEditorRawDataOutput : NSObject <GPUImageInput>
{
    GPUImageRotationMode inputRotation;
    bool outputBGRA;
}

@property (nonatomic, readonly) GLubyte *rawBytesForImage;
@property (nonatomic, copy) void(^newFrameAvailableBlock)(void);
@property (nonatomic, assign) bool enabled;
@property (nonatomic, assign) CGSize imageSize;

- (instancetype)initWithImageSize:(CGSize)newImageSize resultsInBGRAFormat:(bool)resultsInBGRAFormat;

- (PGByteColorVector)colorAtLocation:(CGPoint)locationInImage;
- (NSUInteger)bytesPerRowInOutput;

- (void)lockFramebufferForReading;
- (void)unlockFramebufferAfterReading;

@end
