#import "BlurEffect.h"
#import <objc/runtime.h>

@interface TGCropBlur : BlurEffect

@end

@implementation TGCropBlur

+ (instancetype)effectWithStyle:(UIBlurEffectStyle)style
{
    id result = [super effectWithStyle:style radius:20.0f];
    object_setClass(result, self);
    
    return result;
}

- (id)effectSettings
{
    id settings = [super effectSettings];
    [settings setValue:@1.0f forKey:@"saturationDeltaFactor"];
    [settings setValue:@false forKey:@"blursWithHardEdges"];
    [settings setValue:@false forKey:@"usesGrayscaleTintView"];
    return settings;
}

- (id)copyWithZone:(NSZone *)zone
{
    id result = [super copyWithZone:zone];
    object_setClass(result, [self class]);
    return result;
}

@end


@interface TGItemPreviewBlur : BlurEffect

@end

@implementation TGItemPreviewBlur

+ (instancetype)effectWithStyle:(UIBlurEffectStyle)style
{
    id result = [super effectWithStyle:style radius:10.0f];
    object_setClass(result, self);
    
    return result;
}

- (id)effectSettings
{
    id settings = [super effectSettings];
    [settings setValue:@1.2f forKey:@"saturationDeltaFactor"];
    [settings setValue:@true forKey:@"blursWithHardEdges"];
    return settings;
}

- (id)copyWithZone:(NSZone *)zone
{
    id result = [super copyWithZone:zone];
    object_setClass(result, [self class]);
    return result;
}

@end


@interface TGCallBlur : BlurEffect

@end

@implementation TGCallBlur

+ (instancetype)effectWithStyle:(UIBlurEffectStyle)style
{
    id result = [super effectWithStyle:style radius:20.0f];
    object_setClass(result, self);
    
    return result;
}

- (id)effectSettings
{
    id settings = [super effectSettings];
    [settings setValue:@0.8f forKey:@"saturationDeltaFactor"];
    [settings setValue:@false forKey:@"blursWithHardEdges"];
    [settings setValue:@false forKey:@"usesGrayscaleTintView"];
    return settings;
}

- (id)copyWithZone:(NSZone *)zone
{
    id result = [super copyWithZone:zone];
    object_setClass(result, [self class]);
    return result;
}

@end


@interface BlurEffect ()
{
    CGFloat _radius;
}
@end

@implementation BlurEffect

+ (instancetype)effectWithStyle:(UIBlurEffectStyle)style radius:(CGFloat)radius
{
    id result = [super effectWithStyle:style];
    object_setClass(result, self);
    ((BlurEffect *)result)->_radius = radius;
    
    return result;
}

- (id)effectSettings
{
    id settings = [super effectSettings];
    [settings setValue:@(_radius) forKey:@"blurRadius"];
    return settings;
}

- (id)copyWithZone:(NSZone*)zone
{
    id result = [super copyWithZone:zone];
    object_setClass(result, [self class]);
    ((BlurEffect *)result)->_radius = _radius;
    return result;
}

+ (instancetype)forceTouchBlurEffect
{
    return (BlurEffect *)[TGItemPreviewBlur effectWithStyle:UIBlurEffectStyleLight];
}

+ (instancetype)cropBlurEffect
{
    return (BlurEffect *)[TGCropBlur effectWithStyle:UIBlurEffectStyleDark];
}

+ (instancetype)callBlurEffect
{
    return (BlurEffect *)[TGCallBlur effectWithStyle:UIBlurEffectStyleDark];
}


@end

