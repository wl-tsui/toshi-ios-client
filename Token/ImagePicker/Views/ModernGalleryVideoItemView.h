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

#import "ModernGalleryItemView.h"
#import "ModernGalleryZoomableItemView.h"

@class ImageView;
@class AVPlayer;

@interface ModernGalleryVideoItemView : ModernGalleryItemView

@property (nonatomic, strong) ImageView *imageView;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic) CGSize videoDimensions;

- (bool)shouldLoopVideo:(NSUInteger)currentLoopCount;

- (void)play;
- (void)loadAndPlay;
- (void)hidePlayButton;
- (void)stop;
- (void)stopForOutTransition;

- (void)_willPlay;

@end
