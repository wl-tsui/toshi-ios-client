//
//  UIImage+Utils.h
//  Toshi
//
//  Created by Yuliia Veresklia on 28/09/2017.
//  Copyright © 2017 Bakken&Baeck. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Utils)

UIImage *ScaleImageToPixelSize(UIImage *image, CGSize size);
CGSize TGFitSize(CGSize size, CGSize maxSize);
CGSize TGFitSizeF(CGSize size, CGSize maxSize);

@end
