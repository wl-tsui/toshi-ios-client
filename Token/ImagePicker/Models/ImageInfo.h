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

@interface ImageInfo : NSObject <NSCoding>

- (void)addImageWithSize:(CGSize)size url:(NSString *)url;
- (void)addImageWithSize:(CGSize)size url:(NSString *)url fileSize:(int)fileSize;

- (NSString *)closestImageUrlWithWidth:(int)width resultingSize:(CGSize *)resultingSize;
- (NSString *)closestImageUrlWithHeight:(int)height resultingSize:(CGSize *)resultingSize;
- (NSString *)closestImageUrlWithSize:(CGSize)size resultingSize:(CGSize *)resultingSize;
- (NSString *)closestImageUrlWithSize:(CGSize)size resultingSize:(CGSize *)resultingSize pickLargest:(bool)pickLargest;
- (NSString *)closestImageUrlWithSize:(CGSize)size resultingSize:(CGSize *)resultingSize resultingFileSize:(int *)resultingFileSize;
- (NSString *)closestImageUrlWithSize:(CGSize)size resultingSize:(CGSize *)resultingSize resultingFileSize:(int *)resultingFileSize pickLargest:(bool)pickLargest;
- (NSString *)imageUrlWithExactSize:(CGSize)size;
- (NSString *)imageUrlForLargestSize:(CGSize *)actualSize;
- (NSString *)imageUrlForSizeLargerThanSize:(CGSize)size actualSize:(CGSize *)actualSize;

- (bool)containsSizeWithUrl:(NSString *)url;

- (NSDictionary *)allSizes;
- (bool)empty;

- (void)serialize:(NSMutableData *)data;
+ (ImageInfo *)deserialize:(NSInputStream *)is;

@end
