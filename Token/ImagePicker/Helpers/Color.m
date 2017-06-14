#import "Color.h"

UIColor *ColorWithHex(int hex)
{
    return [[UIColor alloc] initWithRed:(((hex >> 16) & 0xff) / 255.0f) green:(((hex >> 8) & 0xff) / 255.0f) blue:(((hex) & 0xff) / 255.0f) alpha:1.0f];
}

UIColor *ColorWithHexAndAlpha(int hex, CGFloat alpha)
{
    return [[UIColor alloc] initWithRed:(((hex >> 16) & 0xff) / 255.0f) green:(((hex >> 8) & 0xff) / 255.0f) blue:(((hex) & 0xff) / 255.0f) alpha:alpha];
}

UIColor *TGAccentColor()
{
    static UIColor *color = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        color = ColorWithHex(0x007ee5);
    });
    return color;
}

UIColor *TGDestructiveAccentColor()
{
    static UIColor *color = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        color = ColorWithHex(0xff3b30);
    });
    return color;
}

UIColor *TGSelectionColor()
{
    static UIColor *color = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
            color = ColorWithHex(0xe4e4e4);
        else
            color = ColorWithHex(0xd9d9d9);
    });
    return color;
}

UIColor *TGSeparatorColor()
{
    static UIColor *color = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        color = ColorWithHex(0xc8c7cc);
    });
    return color;
}
