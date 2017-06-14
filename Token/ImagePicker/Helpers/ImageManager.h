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

#import "DataResource.h"

@interface ImageManager : NSObject

+ (ImageManager *)instance;

- (UIImage *)loadImageSyncWithUri:(NSString *)uri canWait:(bool)canWait decode:(bool)decode acceptPartialData:(bool)acceptPartialData asyncTaskId:(__autoreleasing id *)asyncTaskId progress:(void (^)(float))progress partialCompletion:(void (^)(UIImage *))partialCompletion completion:(void (^)(UIImage *))completion;
- (id)beginLoadingImageAsyncWithUri:(NSString *)uri decode:(bool)decode progress:(void (^)(float))progress partialCompletion:(void (^)(UIImage *))partialCompletion completion:(void (^)(UIImage *))completion;

- (DataResource *)loadDataSyncWithUri:(NSString *)uri canWait:(bool)canWait acceptPartialData:(bool)acceptPartialData asyncTaskId:(__autoreleasing id *)asyncTaskId progress:(void (^)(float))progress partialCompletion:(void (^)(DataResource *))partialCompletion completion:(void (^)(DataResource *))completion;
- (id)loadAttributeSyncForUri:(NSString *)uri attribute:(NSString *)attribute;

- (void)cancelTaskWithId:(id)taskId;

@end
