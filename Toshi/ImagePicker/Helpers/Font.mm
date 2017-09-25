#import "Font.h"

#import "NSObject+TGLock.h"
#import "Common.h"
#import <map>

UIFont *TGSystemFontOfSize(CGFloat size)
{
    return [UIFont systemFontOfSize:size];
}

UIFont *TGMediumSystemFontOfSize(CGFloat size)
{
    return [UIFont systemFontOfSize:size weight:UIFontWeightMedium];
}

UIFont *TGBoldSystemFontOfSize(CGFloat size)
{
    return [UIFont boldSystemFontOfSize:size];
}

UIFont *TGLightSystemFontOfSize(CGFloat size)
{
    return [UIFont systemFontOfSize:size weight:UIFontWeightLight];
}

UIFont *TGUltralightSystemFontOfSize(CGFloat size)
{
    return [UIFont fontWithName:@"HelveticaNeue-Thin" size:size];
}

UIFont *TGItalicSystemFontOfSize(CGFloat size)
{
    return [UIFont italicSystemFontOfSize:size];
}

@implementation Font

+ (UIFont *)systemFontOfSize:(CGFloat)size
{
    return TGSystemFontOfSize(size);
}

+ (UIFont *)boldSystemFontOfSize:(CGFloat)size
{
    return TGBoldSystemFontOfSize(size);
}

@end

static std::map<int, CTFontRef> systemFontCache;
static std::map<int, CTFontRef> lightFontCache;
static std::map<int, CTFontRef> mediumFontCache;
static std::map<int, CTFontRef> boldFontCache;
static std::map<int, CTFontRef> fixedFontCache;
static std::map<int, CTFontRef> italicFontCache;
static TG_SYNCHRONIZED_DEFINE(systemFontCache) = PTHREAD_MUTEX_INITIALIZER;

CTFontRef TGCoreTextSystemFontOfSize(CGFloat size)
{
    int key = (int)(size * 2.0f);
    CTFontRef result = NULL;
    
    TG_SYNCHRONIZED_BEGIN(systemFontCache);
    auto it = systemFontCache.find(key);
    if (it != systemFontCache.end())
        result = it->second;
    else
    {
        result = CTFontCreateWithFontDescriptor((__bridge CTFontDescriptorRef)[TGSystemFontOfSize(size) fontDescriptor], 0.0f, NULL);

        systemFontCache[key] = result;
    }
    TG_SYNCHRONIZED_END(systemFontCache);
    
    return result;
}

CTFontRef TGCoreTextLightFontOfSize(CGFloat size)
{
    int key = (int)(size * 2.0f);
    CTFontRef result = NULL;
    
    TG_SYNCHRONIZED_BEGIN(systemFontCache);
    auto it = lightFontCache.find(key);
    if (it != lightFontCache.end())
        result = it->second;
    else
    {
        result = CTFontCreateWithFontDescriptor((__bridge CTFontDescriptorRef)[TGLightSystemFontOfSize(size) fontDescriptor], 0.0f, NULL);

        lightFontCache[key] = result;
    }
    TG_SYNCHRONIZED_END(systemFontCache);
    
    return result;
}

CTFontRef TGCoreTextMediumFontOfSize(CGFloat size)
{
    int key = (int)(size * 2.0f);
    CTFontRef result = NULL;
    
    TG_SYNCHRONIZED_BEGIN(systemFontCache);
    auto it = mediumFontCache.find(key);
    if (it != mediumFontCache.end())
        result = it->second;
    else
    {
        result = CTFontCreateWithFontDescriptor((__bridge CTFontDescriptorRef)[TGMediumSystemFontOfSize(size) fontDescriptor], 0.0f, NULL);

        mediumFontCache[key] = result;
    }
    TG_SYNCHRONIZED_END(systemFontCache);
    
    return result;
}

CTFontRef TGCoreTextBoldFontOfSize(CGFloat size)
{
    int key = (int)(size * 2.0f);
    CTFontRef result = NULL;
    
    TG_SYNCHRONIZED_BEGIN(systemFontCache);
    auto it = boldFontCache.find(key);
    if (it != boldFontCache.end())
        result = it->second;
    else
    {
        result = CTFontCreateWithFontDescriptor((__bridge CTFontDescriptorRef)[TGBoldSystemFontOfSize(size) fontDescriptor], 0.0f, NULL);

        boldFontCache[key] = result;
    }
    TG_SYNCHRONIZED_END(systemFontCache);
    
    return result;
}

CTFontRef TGCoreTextFixedFontOfSize(CGFloat size)
{
    int key = (int)(size * 2.0f);
    CTFontRef result = NULL;
    
    TG_SYNCHRONIZED_BEGIN(systemFontCache);
    auto it = fixedFontCache.find(key);
    if (it != fixedFontCache.end())
        result = it->second;
    else
    {
        result = CTFontCreateWithName(CFSTR("Courier"), floor(size * 2.0f) / 2.0f, NULL);
        fixedFontCache[key] = result;
    }
    TG_SYNCHRONIZED_END(systemFontCache);
    
    return result;
}

CTFontRef TGCoreTextItalicFontOfSize(CGFloat size)
{
    int key = (int)(size * 2.0f);
    CTFontRef result = NULL;
    
    TG_SYNCHRONIZED_BEGIN(systemFontCache);
    auto it = italicFontCache.find(key);
    if (it != italicFontCache.end())
        result = it->second;
    else
    {
        result = CTFontCreateWithFontDescriptor((__bridge CTFontDescriptorRef)[TGItalicSystemFontOfSize(size) fontDescriptor], 0.0f, NULL);

        italicFontCache[key] = result;
    }
    TG_SYNCHRONIZED_END(systemFontCache);
    
    return result;
}
