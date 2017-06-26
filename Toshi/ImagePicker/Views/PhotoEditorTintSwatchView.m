#import "PhotoEditorTintSwatchView.h"
#import "PhotoEditorInterfaceAssets.h"

const CGFloat PhotoEditorTintSwatchRadius = 9.0f;
const CGFloat PhotoEditorTintSwatchSelectedRadius = 9.0f;
const CGFloat PhotoEditorTintSwatchSelectionRadius = 12.0f;
const CGFloat PhotoEditorTintSwatchSelectionThickness = 1.5f;
const CGFloat PhotoEditorTintSwatchSize = 25.0f;

@implementation PhotoEditorTintSwatchView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {
        self.backgroundColor = [UIColor clearColor];
        self.contentMode = UIViewContentModeRedraw;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    bool isClearColor = [self.color isEqual:[UIColor clearColor]];
    UIColor *color = isClearColor ? [UIColor whiteColor] : self.color;
    
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetLineWidth(context, PhotoEditorTintSwatchSelectionThickness);
    
    if (self.isSelected)
    {
        CGContextFillEllipseInRect(context, CGRectMake(rect.size.width / 2 - PhotoEditorTintSwatchSelectedRadius, rect.size.height / 2 - PhotoEditorTintSwatchSelectedRadius, PhotoEditorTintSwatchSelectedRadius * 2, PhotoEditorTintSwatchSelectedRadius * 2));
        
        CGContextSetStrokeColorWithColor(context, [PhotoEditorInterfaceAssets accentColor].CGColor);
        CGContextStrokeEllipseInRect(context, CGRectMake(rect.size.width / 2 - PhotoEditorTintSwatchSelectionRadius + PhotoEditorTintSwatchSelectionThickness / 2, rect.size.height / 2 - PhotoEditorTintSwatchSelectionRadius + PhotoEditorTintSwatchSelectionThickness / 2, PhotoEditorTintSwatchSelectionRadius * 2 - PhotoEditorTintSwatchSelectionThickness, PhotoEditorTintSwatchSelectionRadius * 2 - PhotoEditorTintSwatchSelectionThickness));
    }
    else
    {
        if (isClearColor)
        {
            CGContextStrokeEllipseInRect(context, CGRectMake(rect.size.width / 2 - PhotoEditorTintSwatchRadius + PhotoEditorTintSwatchSelectionThickness / 2, rect.size.height / 2 - PhotoEditorTintSwatchRadius + PhotoEditorTintSwatchSelectionThickness / 2, PhotoEditorTintSwatchRadius * 2 - PhotoEditorTintSwatchSelectionThickness, PhotoEditorTintSwatchRadius * 2 - PhotoEditorTintSwatchSelectionThickness));
        }
        else
        {
            CGContextFillEllipseInRect(context, CGRectMake(rect.size.width / 2 - PhotoEditorTintSwatchRadius, rect.size.height / 2 - PhotoEditorTintSwatchRadius, PhotoEditorTintSwatchRadius * 2, PhotoEditorTintSwatchRadius * 2));
        }
    }
}

- (void)setColor:(UIColor *)color
{
    _color = color;
    
    [self setNeedsDisplay];
}

- (void)setSelected:(bool)selected
{
    [super setSelected:selected];
    
    [self setNeedsDisplay];
}

@end
