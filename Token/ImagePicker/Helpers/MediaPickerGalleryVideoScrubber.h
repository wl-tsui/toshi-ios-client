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

#import <UIKit/UIKit.h>

@protocol MediaPickerGalleryVideoScrubberDelegate;
@protocol MediaPickerGalleryVideoScrubberDataSource;

@interface MediaPickerGalleryVideoScrubber : UIControl

@property (nonatomic, weak) id<MediaPickerGalleryVideoScrubberDelegate> delegate;
@property (nonatomic, weak) id<MediaPickerGalleryVideoScrubberDataSource> dataSource;

@property (nonatomic, readonly) NSTimeInterval duration;

@property (nonatomic, assign) bool allowsTrimming;
@property (nonatomic, readonly) bool hasTrimming;
@property (nonatomic, assign) NSTimeInterval trimStartValue;
@property (nonatomic, assign) NSTimeInterval trimEndValue;

@property (nonatomic, assign) NSTimeInterval maximumLength;


@property (nonatomic, assign) bool isPlaying;
@property (nonatomic, assign) NSTimeInterval value;
- (void)setValue:(NSTimeInterval)value resetPosition:(bool)resetPosition;

- (void)setTrimApplied:(bool)trimApplied;

- (void)resetToStart;

- (void)reloadData;
- (void)reloadDataAndReset:(bool)reset;

- (void)reloadThumbnails;
- (void)ignoreThumbnails;
- (void)resetThumbnails;

- (void)setThumbnailImage:(UIImage *)image forTimestamp:(NSTimeInterval)timestamp isSummaryThubmnail:(bool)isSummaryThumbnail;

@end

@protocol MediaPickerGalleryVideoScrubberDelegate <NSObject>

- (void)videoScrubberDidBeginScrubbing:(MediaPickerGalleryVideoScrubber *)videoScrubber;
- (void)videoScrubberDidEndScrubbing:(MediaPickerGalleryVideoScrubber *)videoScrubber;
- (void)videoScrubber:(MediaPickerGalleryVideoScrubber *)videoScrubber valueDidChange:(NSTimeInterval)position;

- (void)videoScrubberDidBeginEditing:(MediaPickerGalleryVideoScrubber *)videoScrubber;
- (void)videoScrubberDidEndEditing:(MediaPickerGalleryVideoScrubber *)videoScrubber;
- (void)videoScrubber:(MediaPickerGalleryVideoScrubber *)videoScrubber editingStartValueDidChange:(NSTimeInterval)startValue;
- (void)videoScrubber:(MediaPickerGalleryVideoScrubber *)videoScrubber editingEndValueDidChange:(NSTimeInterval)endValue;

- (void)videoScrubberDidFinishRequestingThumbnails:(MediaPickerGalleryVideoScrubber *)videoScrubber;
- (void)videoScrubberDidCancelRequestingThumbnails:(MediaPickerGalleryVideoScrubber *)videoScrubber;

@end

@protocol MediaPickerGalleryVideoScrubberDataSource <NSObject>

- (NSTimeInterval)videoScrubberDuration:(MediaPickerGalleryVideoScrubber *)videoScrubber;

- (NSArray *)videoScrubber:(MediaPickerGalleryVideoScrubber *)videoScrubber evenlySpacedTimestamps:(NSInteger)count startingAt:(NSTimeInterval)startTimestamp endingAt:(NSTimeInterval)endTimestamp;

- (void)videoScrubber:(MediaPickerGalleryVideoScrubber *)videoScrubber requestThumbnailImagesForTimestamps:(NSArray *)timestamps size:(CGSize)size isSummaryThumbnails:(bool)isSummaryThumbnails;

- (CGFloat)videoScrubberThumbnailAspectRatio:(MediaPickerGalleryVideoScrubber *)videoScrubber;

- (CGSize)videoScrubberOriginalSize:(MediaPickerGalleryVideoScrubber *)videoScrubber cropRect:(CGRect *)cropRect cropOrientation:(UIImageOrientation *)cropOrientation cropMirrored:(bool *)cropMirrored;

@end
