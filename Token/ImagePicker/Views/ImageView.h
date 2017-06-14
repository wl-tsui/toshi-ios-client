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

#import <SSignalKit/SSignalKit.h>

extern NSString *ImageViewOptionKeepCurrentImageAsPlaceholder;
extern NSString *ImageViewOptionEmbeddedImage;
extern NSString *ImageViewOptionSynchronous;

@interface ImageView : UIImageView
{
    UIImageView *_extendedInsetsImageView;
}

@property (nonatomic) bool expectExtendedEdges;
@property (nonatomic) bool legacyAutomaticProgress;

- (void)loadUri:(NSString *)uri withOptions:(NSDictionary *)options;
- (void)reset;

- (void)performTransitionToImage:(UIImage *)image partial:(bool)partial duration:(NSTimeInterval)duration;
- (void)performProgressUpdate:(CGFloat)progress;
- (UIImage *)currentImage;

- (void)setSignal:(SSignal *)signal;

- (void)_commitImage:(UIImage *)image partial:(bool)partial loadTime:(NSTimeInterval)loadTime;
- (void)_updateProgress:(float)value;

@end
