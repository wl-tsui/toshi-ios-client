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

#import <SSignalKit/SSignalKit.h>

#import "VideoEditAdjustments.h"

@interface MediaVideoFileWatcher : NSObject
{
    NSURL *_fileURL;
}

- (void)setupWithFileURL:(NSURL *)fileURL;
- (id)fileUpdated:(bool)completed;

@end


@interface MediaVideoConverter : NSObject

+ (SSignal *)convertAVAsset:(AVAsset *)avAsset adjustments:(MediaVideoEditAdjustments *)adjustments watcher:(MediaVideoFileWatcher *)watcher;
+ (SSignal *)convertAVAsset:(AVAsset *)avAsset adjustments:(MediaVideoEditAdjustments *)adjustments watcher:(MediaVideoFileWatcher *)watcher inhibitAudio:(bool)inhibitAudio;
+ (SSignal *)hashForAVAsset:(AVAsset *)avAsset adjustments:(MediaVideoEditAdjustments *)adjustments;

+ (NSUInteger)estimatedSizeForPreset:(MediaVideoConversionPreset)preset duration:(NSTimeInterval)duration hasAudio:(bool)hasAudio;
+ (MediaVideoConversionPreset)bestAvailablePresetForDimensions:(CGSize)dimensions;

@end


@interface MediaVideoConversionResult : NSObject

@property (nonatomic, readonly) NSURL *fileURL;
@property (nonatomic, readonly) NSUInteger fileSize;
@property (nonatomic, readonly) NSTimeInterval duration;
@property (nonatomic, readonly) CGSize dimensions;
@property (nonatomic, readonly) UIImage *coverImage;
@property (nonatomic, readonly) id liveUploadData;

- (NSDictionary *)dictionary;

@end
