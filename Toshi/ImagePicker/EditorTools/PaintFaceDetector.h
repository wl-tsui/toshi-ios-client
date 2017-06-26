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
#import <UIKit/UIKit.h>

@interface PaintFaceFeature : NSObject
{
    CGPoint _position;
}

@property (nonatomic, readonly) CGPoint position;

@end


@interface PaintFaceEye : PaintFaceFeature

@property (nonatomic, readonly, getter=isClosed) bool closed;

@end


@interface PaintFaceMouth : PaintFaceFeature

@property (nonatomic, readonly, getter=isSmiling) bool smiling;

@end


@interface PaintFace : NSObject

@property (nonatomic, readonly) NSInteger uuid;

@property (nonatomic, readonly) CGRect bounds;
@property (nonatomic, readonly) CGFloat angle;

@property (nonatomic, readonly) PaintFaceEye *leftEye;
@property (nonatomic, readonly) PaintFaceEye *rightEye;
@property (nonatomic, readonly) PaintFaceMouth *mouth;

- (CGPoint)foreheadPoint;
- (CGPoint)eyesCenterPointAndDistance:(CGFloat *)distance;
- (CGFloat)eyesAngle;
- (CGPoint)mouthPoint;
- (CGPoint)chinPoint;

@end


@interface PaintFaceDetector : NSObject

+ (SSignal *)detectFacesInImage:(UIImage *)image originalSize:(CGSize)originalSize;

@end


@interface PaintFaceUtils : NSObject

+ (CGFloat)transposeWidth:(CGFloat)width paintingSize:(CGSize)paintingSize originalSize:(CGSize)originalSize;
+ (CGPoint)transposePoint:(CGPoint)point paintingSize:(CGSize)paintingSize originalSize:(CGSize)originalSize;
+ (CGRect)transposeRect:(CGRect)rect paintingSize:(CGSize)paintingSize originalSize:(CGSize)originalSize;

@end
