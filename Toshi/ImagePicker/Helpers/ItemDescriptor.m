#import "ItemDescriptor.h"
#import <UIKit/UIKit.h>
#import "MediaAsset.h"
#import "ViewController.h"
#import "Common.h"
#import "VideoEditAdjustments.h"
#import "DocumentAttributeFilename.h"
#import "DocumentAttributeAnimated.h"
#import "DocumentAttributeVideo.h"
#import "MediaAssetsController.h"
#import "ImageUtils.h"

@implementation ItemDescriptor

+ (NSDictionary *)descriptionForItem:(id)item caption:(NSString *)caption hash:(NSString *)hash
{
    if (item == nil)
        return nil;
    
    NSDictionary *result = nil;
    
    if ([item isKindOfClass:[UIImage class]])
    {
        return [self imageDescriptionFromImage:(UIImage *)item stickers:nil caption:caption optionalAssetUrl:hash != nil ? [[NSString alloc] initWithFormat:@"image-%@", hash] : nil];
    }
    else if ([item isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *dict = (NSDictionary *)item;
        NSString *type = dict[@"type"];
        
        if ([type isEqualToString:@"editedPhoto"]) {
            result = [self imageDescriptionFromImage:dict[@"image"] stickers:dict[@"stickers"] caption:caption optionalAssetUrl:hash != nil ? [[NSString alloc] initWithFormat:@"image-%@", hash] : nil];
        }
        if ([type isEqualToString:@"cloudPhoto"])
        {
            result = [self imageDescriptionFromMediaAsset:dict[@"asset"] previewImage:dict[@"previewImage"] document:[dict[@"document"] boolValue] fileName:dict[@"fileName"] caption:caption];
        }
        else if ([type isEqualToString:@"video"])
        {
            result = [self videoDescriptionFromMediaAsset:dict[@"asset"] previewImage:dict[@"previewImage"] adjustments:dict[@"adjustments"] document:[dict[@"document"] boolValue] fileName:dict[@"fileName"] stickers:dict[@"stickers"] caption:caption];
        }
        else if ([type isEqualToString:@"file"])
        {
            result = [self documentDescriptionFromFileAtTempUrl:dict[@"tempFileUrl"] fileName:dict[@"fileName"] mimeType:dict[@"mimeType"] isAnimation:dict[@"isAnimation"] caption:caption];
        }
    }
    
    return result;
}

+ (CGSize)preferredInlineThumbnailSize
{
    return [ViewController isWidescreen] ? CGSizeMake(220, 220) : CGSizeMake(180, 180);
}

+ (NSDictionary *)documentDescriptionFromFileAtTempUrl:(NSURL *)url fileName:(NSString *)fileName mimeType:(NSString *)mimeType isAnimation:(bool)isAnimation caption:(NSString *)caption
{
    NSMutableDictionary *desc = [[NSMutableDictionary alloc] init];
    desc[@"url"] = url;
    if (fileName.length != 0)
        desc[@"fileName"] = fileName;
    
    if (mimeType.length != 0)
        desc[@"mimeType"] = mimeType;
    
    desc[@"isAnimation"] = @(isAnimation);
    
    if (caption != nil)
        desc[@"caption"] = caption;
    
    desc[@"forceAsFile"] = @true;
    
    return desc;
}

+ (NSDictionary *)videoDescriptionFromMediaAsset:(MediaAsset *)asset previewImage:(UIImage *)previewImage adjustments:(VideoEditAdjustments *)adjustments document:(bool)document fileName:(NSString *)fileName stickers:(NSArray *)stickers caption:(NSString *)caption
{
    if (asset == nil)
        return nil;
    
    NSData *thumbnailData = UIImageJPEGRepresentation(previewImage, 0.54f);
    
    NSTimeInterval duration = asset.videoDuration;
    CGSize dimensions = asset.dimensions;
    if (!CGSizeEqualToSize(dimensions, CGSizeZero))
        dimensions = TGFitSize(dimensions, CGSizeMake(640, 640));
    else
        dimensions = TGFitSize(previewImage.size, CGSizeMake(640, 640));
    
    if (adjustments != nil)
    {
        if (adjustments.trimApplied)
            duration = adjustments.trimEndValue - adjustments.trimStartValue;
        if ([adjustments cropAppliedForAvatar:false])
        {
            CGSize size = adjustments.cropRect.size;
            if (adjustments.cropOrientation != UIImageOrientationUp && adjustments.cropOrientation != UIImageOrientationDown)
                size = CGSizeMake(size.height, size.width);
            dimensions = TGFitSize(size, CGSizeMake(640, 640));
        }
    }
    
    bool isAnimation = adjustments.sendAsGif;
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:@
                                 {
                                     @"assetIdentifier": asset.uniqueIdentifier,
                                     @"duration": @(duration),
                                     @"dimensions": [NSValue valueWithCGSize:dimensions],
                                     @"thumbnailData": thumbnailData,
                                     @"thumbnailSize": [NSValue valueWithCGSize:dimensions],
                                     @"document": @(document || isAnimation)
                                 }];
    
    if (adjustments != nil)
        dict[@"adjustments"] = adjustments;
    
    NSMutableArray *attributes = [[NSMutableArray alloc] init];
    if (isAnimation)
    {
        dict[@"mimeType"] = @"video/mp4";
        [attributes addObject:[[DocumentAttributeFilename alloc] initWithFilename:@"animation.mp4"]];
        [attributes addObject:[[DocumentAttributeAnimated alloc] init]];
    }
    else
    {
        if (fileName.length > 0)
            [attributes addObject:[[DocumentAttributeFilename alloc] initWithFilename:fileName]];
    }
    
    if (!document)
        [attributes addObject:[[DocumentAttributeVideo alloc] initWithSize:dimensions duration:(int32_t)duration]];
    
    if ((document || isAnimation) && attributes.count > 0)
        dict[@"attributes"] = attributes;
    
    if (caption != nil)
        dict[@"caption"] = caption;
    
    if (stickers != nil)
        dict[@"stickerDocuments"] = stickers;
    
    return @{@"assetVideo": dict};
}

+ (NSDictionary *)imageDescriptionFromMediaAsset:(MediaAsset *)asset previewImage:(UIImage *)previewImage document:(bool)document fileName:(NSString *)fileName caption:(NSString *)caption
{
    if (asset == nil)
        return nil;
    
    NSData *thumbnailData = UIImageJPEGRepresentation(previewImage, 0.54f);
    CGSize dimensions = asset.dimensions;
    if (CGSizeEqualToSize(dimensions, CGSizeZero))
        dimensions = previewImage.size;
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:@
                                 {
                                     @"assetIdentifier": asset.uniqueIdentifier,
                                     @"thumbnailData": thumbnailData,
                                     @"thumbnailSize": [NSValue valueWithCGSize:dimensions],
                                     @"document": @(document)
                                 }];
    
    NSMutableArray *attributes = [[NSMutableArray alloc] init];
    if (fileName.length > 0)
        [attributes addObject:[[DocumentAttributeFilename alloc] initWithFilename:fileName]];
    
    if (document && attributes.count > 0)
        dict[@"attributes"] = attributes;
    
    if (caption != nil)
        dict[@"caption"] = caption;
    
    return @{@"assetImage": dict};
}

+ (NSDictionary *)imageDescriptionFromImage:(UIImage *)image stickers:(NSArray *)stickers caption:(NSString *)caption optionalAssetUrl:(NSString *)assetUrl
{
    if (image == nil)
        return nil;
    
    CGSize originalSize = image.size;
    originalSize.width *= image.scale;
    originalSize.height *= image.scale;
    
    CGSize imageSize = TGFitSize(originalSize, CGSizeMake(1280, 1280));
    CGSize thumbnailSize = TGFitSize(originalSize, CGSizeMake(90, 90));
    
    UIImage *fullImage = MAX(image.size.width, image.size.height) > 1280.0f ? ScaleImageToPixelSize(image, imageSize) : image;
    NSData *imageData = UIImageJPEGRepresentation(fullImage, 0.52f);
    
    UIImage *previewImage = ScaleImageToPixelSize(fullImage, TGFitSize(originalSize, [self preferredInlineThumbnailSize]));
    NSData *thumbnailData = UIImageJPEGRepresentation(previewImage, 0.9f);
    
    previewImage = nil;
    fullImage = nil;
    
    if (imageData != nil && thumbnailData != nil)
    {
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:@
                                     {
                                         @"imageSize": [NSValue valueWithCGSize:imageSize],
                                         @"thumbnailSize": [NSValue valueWithCGSize:thumbnailSize],
                                         @"imageData": imageData,
                                         @"thumbnailData": thumbnailData
                                     }];
        
        if (stickers != nil)
            dict[@"stickerDocuments"] = stickers;
        
        if (caption != nil)
            dict[@"caption"] = caption;
        
        if (assetUrl != nil)
            dict[@"assetUrl"] = assetUrl;
        
        return @{@"localImage": dict};
    }
    
    return nil;
}

@end
