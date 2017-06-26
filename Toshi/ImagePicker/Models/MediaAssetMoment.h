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

#import <Photos/Photos.h>

@class MediaAssetFetchResult;

@interface MediaAssetMoment : NSObject

@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSDate *startDate;
@property (nonatomic, readonly) NSDate *endDate;
@property (nonatomic, readonly) CLLocation *location;
@property (nonatomic, readonly) NSArray *locationNames;
@property (nonatomic, readonly) NSUInteger assetCount;

@property (nonatomic, readonly) MediaAssetFetchResult *fetchResult;

- (instancetype)initWithPHAssetCollection:(PHAssetCollection *)collection;

@end
