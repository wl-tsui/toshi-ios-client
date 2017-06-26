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

@class TGTemporaryImage;

UIImage *TGAverageColorImage(UIColor *color);
UIImage *TGAverageColorRoundImage(UIColor *color, CGSize size);
UIImage *TGAverageColorAttachmentImage(UIColor *color, bool attachmentBorder);
UIImage *TGAverageColorAttachmentWithCornerRadiusImage(UIColor *color, bool attachmentBorder, int cornerRadius);
UIImage *TGBlurredAttachmentImage(UIImage *source, CGSize size, uint32_t *averageColor, bool attachmentBorder);
UIImage *TGSecretBlurredAttachmentImage(UIImage *source, CGSize size, uint32_t *averageColor, bool attachmentBorder);
UIImage *TGBlurredFileImage(UIImage *source, CGSize size, uint32_t *averageColor, int borderRadius);
UIImage *TGLoadedAttachmentImage(UIImage *source, CGSize size, uint32_t *averageColor, bool attachmentBorder);
UIImage *TGAnimationFrameAttachmentImage(UIImage *source, CGSize size, CGSize renderSize);
UIImage *TGLoadedFileImage(UIImage *source, CGSize size, uint32_t *averageColor, int borderRadius);
UIImage *TGReducedAttachmentImage(UIImage *source, CGSize originalSize, bool attachmentBorder);
UIImage *TGBlurredBackgroundImage(UIImage *source, CGSize size);
UIImage *RoundImage(UIImage *source, CGSize size);
UIImage *TGBlurredAlphaImage(UIImage *source, CGSize size);
UIImage *TGBlurredRectangularImage(UIImage *source, CGSize size, CGSize renderSize, uint32_t *averageColor, void (^pixelProcessingBlock)(void *, int, int, int));

UIImage *TGCropBackdropImage(UIImage *source, CGSize size);
UIImage *CameraPositionSwitchImage(UIImage *source, CGSize size);
UIImage *CameraModeSwitchImage(UIImage *source, CGSize size);

UIImage *TGBlurredAttachmentWithCornerRadiusImage(UIImage *source, CGSize size, uint32_t *averageColor, bool attachmentBorder, int cornerRadius);
UIImage *TGLoadedAttachmentWithCornerRadiusImage(UIImage *source, CGSize size, uint32_t *averageColor, bool attachmentBorder, int cornerRadius);
UIImage *TGReducedAttachmentWithCornerRadiusImage(UIImage *source, CGSize originalSize, bool attachmentBorder, int cornerRadius);

void TGPlainImageAverageColor(UIImage *source, uint32_t *averageColor);
UIImage *ScaleAndCropImageToPixelSize(UIImage *source, CGSize size, CGSize renderSize, uint32_t *averageColor, void (^pixelProcessingBlock)(void *, int, int, int));

NSArray *TGBlurredBackgroundImages(UIImage *source, CGSize size);

void TGAddImageCorners(void *memory, const unsigned int width, const unsigned int height, const unsigned int stride, int radius);

void telegramFastBlur(int imageWidth, int imageHeight, int imageStride, void *pixels);
