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
#import <SSignalKit/SSignalKit.h>

#import "VideoEditAdjustments.h"

@class PhotoEditorPreviewView;
@class PaintingData;

@interface PhotoEditor : NSObject

@property (nonatomic, assign) CGSize originalSize;
@property (nonatomic, assign) CGRect cropRect;
@property (nonatomic, readonly) CGSize rotatedCropSize;
@property (nonatomic, assign) CGFloat cropRotation;
@property (nonatomic, assign) UIImageOrientation cropOrientation;
@property (nonatomic, assign) CGFloat cropLockedAspectRatio;
@property (nonatomic, assign) bool cropMirrored;
@property (nonatomic, strong) PaintingData *paintingData;
@property (nonatomic, assign) NSTimeInterval trimStartValue;
@property (nonatomic, assign) NSTimeInterval trimEndValue;
@property (nonatomic, assign) bool sendAsGif;
@property (nonatomic, assign) MediaVideoConversionPreset preset;

@property (nonatomic, weak) PhotoEditorPreviewView *previewOutput;
@property (nonatomic, readonly) NSArray *tools;

@property (nonatomic, readonly) bool processing;
@property (nonatomic, readonly) bool readyForProcessing;

- (instancetype)initWithOriginalSize:(CGSize)originalSize adjustments:(id<MediaEditAdjustments>)adjustments forVideo:(bool)forVideo;

- (void)cleanup;

- (void)setImage:(UIImage *)image forCropRect:(CGRect)cropRect cropRotation:(CGFloat)cropRotation cropOrientation:(UIImageOrientation)cropOrientation cropMirrored:(bool)cropMirrored fullSize:(bool)fullSize;

- (void)processAnimated:(bool)animated completion:(void (^)(void))completion;

- (void)createResultImageWithCompletion:(void (^)(UIImage *image))completion;
- (UIImage *)currentResultImage;

- (bool)hasDefaultCropping;

- (SSignal *)histogramSignal;

- (id<MediaEditAdjustments>)exportAdjustments;
- (id<MediaEditAdjustments>)exportAdjustmentsWithPaintingData:(PaintingData *)paintingData;

@end
