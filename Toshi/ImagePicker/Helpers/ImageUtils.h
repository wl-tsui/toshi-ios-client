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

#ifdef __cplusplus
extern "C" {
#endif
    
typedef enum {
    ScaleImageFlipVerical = 1,
    ScaleImageScaleOverlay = 2,
    ScaleImageRoundCornersByOuterBounds = 4,
    ScaleImageScaleSharper = 8
} ScaleImageFlags;

//UIImage *ScaleImage(UIImage *image, CGSize size);
UIImage *ScaleAndRoundCorners(UIImage *image, CGSize size, CGSize imageSize, int radius, UIImage *overlay, bool opaque, UIColor *backgroundColor);
UIImage *ScaleAndRoundCornersWithOffset(UIImage *image, CGSize size, CGPoint offset, CGSize imageSize, int radius, UIImage *overlay, bool opaque, UIColor *backgroundColor);
UIImage *ScaleAndRoundCornersWithOffsetAndFlags(UIImage *image, CGSize size, CGPoint offset, CGSize imageSize, int radius, UIImage *overlay, bool opaque, UIColor *backgroundColor, int flags);
    
inline bool TGEnableBlur() { return false; }
UIImage *ScaleAndBlurImage(NSData *data, CGSize size, __autoreleasing NSData **blurredData);

UIImage *ScaleImageToPixelSize(UIImage *image, CGSize size);
UIImage *TGRotateAndScaleImageToPixelSize(UIImage *image, CGSize size);

UIImage *TGFixOrientationAndCrop(UIImage *source, CGRect cropFrame, CGSize imageSize);
UIImage *TGRotateAndCrop(UIImage *source, CGRect cropFrame, CGSize imageSize);
    
UIImage *AttachmentImage(UIImage *source, CGSize sourceSize, CGSize size, bool incoming, bool location);
UIImage *TGSecretAttachmentImage(UIImage *source, CGSize sourceSize, CGSize size);
    
UIImage *TGIdenticonImage(NSData *data, NSData *additionalData, CGSize size);
    
UIImage *TGCircleImage(CGFloat radius, UIColor *color);
    
UIImage *TGTintedImage(UIImage *image, UIColor *color);
    
NSString *ImageHash(NSData *data);
    
#ifdef __cplusplus
}
#endif

@interface UIImage (Preloading)

- (UIImage *)preloadedImage;
- (UIImage *)preloadedImageWithAlpha;
- (void)tgPreload;

- (void)setMediumImage:(UIImage *)image;
- (UIImage *)mediumImage;

- (CGSize)screenSize;
- (CGSize)pixelSize;

@end

#ifdef __cplusplus
extern "C" {
#endif

CGSize TGFitSize(CGSize size, CGSize maxSize);
CGSize TGFitSizeF(CGSize size, CGSize maxSize);
CGSize TGFillSize(CGSize size, CGSize maxSize);
CGSize TGFillSizeF(CGSize size, CGSize maxSize);
CGSize TGCropSize(CGSize size, CGSize maxSize);
CGSize ScaleToFill(CGSize size, CGSize boundsSize);
CGSize ScaleToFit(CGSize size, CGSize boundsSize);
    
CGFloat TGRetinaFloor(CGFloat value);
CGFloat TGRetinaCeil(CGFloat value);
CGFloat TGScreenPixelFloor(CGFloat value);
    
bool TGIsRetina();
CGFloat TGScreenScaling();
bool TGIsPad();
    
CGFloat TGSeparatorHeight();

    
CGSize TGScreenSize();
CGSize TGNativeScreenSize();
    
extern CGFloat TGRetinaPixel;
extern CGFloat TGScreenPixel;
    
void TGDrawSvgPath(CGContextRef context, NSString *path);

#ifdef __cplusplus
}
#endif
