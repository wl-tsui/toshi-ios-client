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

typedef enum
{
    TGMediaVideoConversionPresetCompressedDefault,
    TGMediaVideoConversionPresetCompressedVeryLow,
    TGMediaVideoConversionPresetCompressedLow,
    TGMediaVideoConversionPresetCompressedMedium,
    TGMediaVideoConversionPresetCompressedHigh,
    TGMediaVideoConversionPresetCompressedVeryHigh,
    TGMediaVideoConversionPresetAnimation
} TGMediaVideoConversionPreset;

@interface TGVideoEditAdjustments : NSObject <MediaEditAdjustments>

@property (nonatomic, readonly) NSTimeInterval trimStartValue;
@property (nonatomic, readonly) NSTimeInterval trimEndValue;
@property (nonatomic, readonly) TGMediaVideoConversionPreset preset;
@property (nonatomic, readonly) bool sendAsGif;

- (CMTimeRange)trimTimeRange;

- (bool)trimApplied;

- (bool)isCropAndRotationEqualWith:(id<MediaEditAdjustments>)adjustments;

- (NSDictionary *)dictionary;

- (instancetype)editAdjustmentsWithPreset:(TGMediaVideoConversionPreset)preset maxDuration:(NSTimeInterval)maxDuration;
+ (instancetype)editAdjustmentsWithOriginalSize:(CGSize)originalSize preset:(TGMediaVideoConversionPreset)preset;

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
                                         preset:(TGMediaVideoConversionPreset)preset;

@end

typedef TGVideoEditAdjustments TGMediaVideoEditAdjustments;

extern const NSTimeInterval TGVideoEditMinimumTrimmableDuration;
extern const NSTimeInterval TGVideoEditMaximumGifDuration;
