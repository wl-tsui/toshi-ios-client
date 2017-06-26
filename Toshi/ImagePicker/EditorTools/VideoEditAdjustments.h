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

#import <AVFoundation/AVFoundation.h>
#import "MediaEditingContext.h"
#import <UIKit/UIKit.h>

typedef enum
{
    MediaVideoConversionPresetCompressedDefault,
    MediaVideoConversionPresetCompressedVeryLow,
    MediaVideoConversionPresetCompressedLow,
    MediaVideoConversionPresetCompressedMedium,
    MediaVideoConversionPresetCompressedHigh,
    MediaVideoConversionPresetCompressedVeryHigh,
    MediaVideoConversionPresetAnimation
} MediaVideoConversionPreset;

@interface VideoEditAdjustments : NSObject <MediaEditAdjustments>

@property (nonatomic, readonly) NSTimeInterval trimStartValue;
@property (nonatomic, readonly) NSTimeInterval trimEndValue;
@property (nonatomic, readonly) MediaVideoConversionPreset preset;
@property (nonatomic, readonly) bool sendAsGif;

- (CMTimeRange)trimTimeRange;

- (bool)trimApplied;

- (bool)isCropAndRotationEqualWith:(id<MediaEditAdjustments>)adjustments;

- (NSDictionary *)dictionary;

- (instancetype)editAdjustmentsWithPreset:(MediaVideoConversionPreset)preset maxDuration:(NSTimeInterval)maxDuration;
+ (instancetype)editAdjustmentsWithOriginalSize:(CGSize)originalSize preset:(MediaVideoConversionPreset)preset;

+ (instancetype)editAdjustmentsWithDictionary:(NSDictionary *)dictionary;

+ (instancetype)editAdjustmentsWithOriginalSize:(CGSize)originalSize
                                       cropRect:(CGRect)cropRect
                                cropOrientation:(UIImageOrientation)cropOrientation
                          cropLockedAspectRatio:(CGFloat)cropLockedAspectRatio
                                   cropMirrored:(bool)cropMirrored
                                 trimStartValue:(NSTimeInterval)trimStartValue
                                   trimEndValue:(NSTimeInterval)trimEndValue
                                   paintingData:(PaintingData *)paintingData
                                      sendAsGif:(bool)sendAsGif
                                         preset:(MediaVideoConversionPreset)preset;

@end

typedef VideoEditAdjustments MediaVideoEditAdjustments;

extern const NSTimeInterval VideoEditMinimumTrimmableDuration;
extern const NSTimeInterval VideoEditMaximumGifDuration;
