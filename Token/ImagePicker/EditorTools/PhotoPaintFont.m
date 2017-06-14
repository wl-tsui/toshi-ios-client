#import "PhotoPaintFont.h"

@implementation PhotoPaintFont

- (BOOL)isEqual:(id)object
{
    if (object == self)
        return true;
    
    if (!object || ![object isKindOfClass:[self class]])
        return false;
    
    PhotoPaintFont *font = (PhotoPaintFont *)object;
    return [font.title isEqualToString:self.title];
}

+ (instancetype)fontWithTitle:(NSString *)title titleInset:(CGFloat)titleInset fontName:(NSString *)fontName previewFontName:(NSString *)previewFontName sizeCorrection:(CGFloat)sizeCorrection
{
    PhotoPaintFont *font = [[PhotoPaintFont alloc] init];
    font->_title = title;
    font->_titleInset = titleInset;
    font->_fontName = fontName;
    font->_previewFontName = previewFontName;
    font->_sizeCorrection = sizeCorrection;
    return font;
}

+ (NSArray *)availableFonts
{
    return @
    [
        [PhotoPaintFont fontWithTitle:@"Main" titleInset:0 fontName:@"Helvetica-Bold" previewFontName:@"Helvetica" sizeCorrection:0]
    ];
}

@end
