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
#import <CoreGraphics/CoreGraphics.h>
#import <OpenGLES/ES2/gl.h>
#import <UIKit/UIKit.h>

#define TGLog(frmt, ...) NSLog(frmt, ##__VA_ARGS__)

void PaintHasGLError_(const char *file, int line);
#define PaintHasGLError() PaintHasGLError_(__FILE__, __LINE__)

void TGSetupColorUniform(GLint location, UIColor *color);

UIImage *PaintCombineImages(UIImage *background, UIImage *foreground, bool opaque);
UIImage *PaintCombineCroppedImages(UIImage *background, UIImage *foreground, bool opaque, CGSize originalSize, CGRect cropRect, UIImageOrientation cropOrientation, CGFloat rotation, bool mirrored);

NSData *PaintGZipInflate(NSData *data);
NSData *PaintGZipDeflate(NSData *data);

static inline CGPoint PaintAddPoints(CGPoint a, CGPoint b)
{
    return CGPointMake(a.x + b.x, a.y + b.y);
}

static inline CGPoint PaintSubtractPoints(CGPoint a, CGPoint b)
{
    return CGPointMake(a.x - b.x, a.y - b.y);
}

static inline CGPoint PaintMultiplyPoint(CGPoint p, CGFloat s)
{
    return CGPointMake(p.x * s, p.y * s);
}

static inline CGFloat PaintDistance(CGPoint a, CGPoint b)
{
    CGFloat xd = (a.x - b.x);
    CGFloat yd = (a.y - b.y);
    
    return sqrt(xd * xd + yd * yd);
}

static inline CGPoint PaintCenterOfRect(CGRect rect)
{
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}

static inline CGRect PaintUnionRect(CGRect a, CGRect b)
{
    if (CGRectEqualToRect(a, CGRectZero))
        return b;
    else if (CGRectEqualToRect(b, CGRectZero))
        return a;
    
    return CGRectUnion(a, b);
}

static inline CGRect PaintMultiplyRectScalar(CGRect rect, CGFloat scale)
{
    return CGRectMake(rect.origin.x * scale, rect.origin.y * scale, rect.size.width * scale, rect.size.height * scale);
}

static inline CGSize PaintMultiplySizeScalar(CGSize size, CGFloat scale)
{
    return CGSizeMake(size.width * scale, size.height * scale);
}

typedef void(^dispatch_cancelable_block_t)(BOOL cancel);

static dispatch_cancelable_block_t dispatch_after_delay(NSTimeInterval delay, dispatch_queue_t queue, dispatch_block_t block)
{
    if (block == nil)
        return nil;
    
    __block dispatch_cancelable_block_t cancelableBlock = nil;
    __block dispatch_block_t originalBlock = [block copy];
    
    dispatch_cancelable_block_t delayBlock = ^(BOOL cancel)
    {
        if (!cancel && originalBlock)
            dispatch_async(queue, originalBlock);
        
        originalBlock = nil;
        cancelableBlock = nil;
    };
    
    cancelableBlock = [delayBlock copy];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)delay * NSEC_PER_SEC), queue, ^
    {
        if (cancelableBlock)
            cancelableBlock(false);
    });
    
    return cancelableBlock;
}

static void cancel_block(dispatch_cancelable_block_t block)
{
    if (block == nil)
        return;
    
    block(true);
}
