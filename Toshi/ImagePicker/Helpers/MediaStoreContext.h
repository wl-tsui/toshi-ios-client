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

#import "ModernCache.h"
#import <UIKit/UIKit.h>

@interface MediaStoreContext : NSObject

+ (MediaStoreContext *)instance;

- (ModernCache *)temporaryFilesCache;

- (NSNumber *)mediaImageAverageColor:(NSString *)key;
- (void)setMediaImageAverageColorForKey:(NSString *)key averageColor:(NSNumber *)averageColor;

- (UIImage *)mediaReducedImage:(NSString *)key attributes:(__autoreleasing NSDictionary **)attributes;
- (void)setMediaReducedImageForKey:(NSString *)key reducedImage:(UIImage *)reducedImage attributes:(NSDictionary *)attributes;

- (UIImage *)mediaImage:(NSString *)key attributes:(__autoreleasing NSDictionary **)attributes;
- (void)setMediaImageForKey:(NSString *)key image:(UIImage *)image attributes:(NSDictionary *)attributes;

- (void)inMediaReducedImageCacheGenerationQueue:(dispatch_block_t)block;

@end
