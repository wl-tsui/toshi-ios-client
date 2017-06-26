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

@interface VideoInfo : NSObject <NSCoding>

- (void)addVideoWithQuality:(int)quality url:(NSString *)url size:(int)size;
- (NSString *)urlWithQuality:(int)quality actualQuality:(int *)actualQuality actualSize:(int *)actualSize;

- (void)serialize:(NSMutableData *)data;
+ (VideoInfo *)deserialize:(NSInputStream *)is;

@end
