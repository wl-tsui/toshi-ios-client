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
#import <UIKit/UIKit.h>

@class PaintUndoManager;
@class MediaEditingContext;
@protocol MediaEditableItem;

@interface PaintingData : NSObject

@property (nonatomic, readonly) NSString *imagePath;
@property (nonatomic, readonly) NSString *dataPath;
@property (nonatomic, readonly) NSArray *entities;
@property (nonatomic, readonly) PaintUndoManager *undoManager;
@property (nonatomic, readonly) NSArray *stickers;

@property (nonatomic, readonly) NSData *data;
@property (nonatomic, readonly) UIImage *image;

+ (instancetype)dataWithPaintingData:(NSData *)data image:(UIImage *)image entities:(NSArray *)entities undoManager:(PaintUndoManager *)undoManager;

+ (instancetype)dataWithPaintingImagePath:(NSString *)imagePath;

+ (void)storePaintingData:(PaintingData *)data inContext:(MediaEditingContext *)context forItem:(id<MediaEditableItem>)item forVideo:(bool)video;
+ (void)facilitatePaintingData:(PaintingData *)data;

@end
