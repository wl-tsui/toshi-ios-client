#import "ModernClockProgressViewModel.h"

#import "ModernClockProgressView.h"

#import "ImageUtils.h"

@interface ModernClockProgressViewModel ()
{
    ModernClockProgressType _type;
}

@end

@implementation ModernClockProgressViewModel

- (instancetype)initWithType:(ModernClockProgressType)type
{
    self = [super init];
    if (self != nil)
    {
        _type = type;
    }
    return self;
}

- (Class)viewClass
{
    return [ModernClockProgressView class];
}

+ (CGImageRef)frameImageForType:(ModernClockProgressType)type
{
    switch (type)
    {
        case ModernClockProgressTypeOutgoingClock:
        {
            static CGImageRef image = NULL;
            
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^
            {
                UIImage *rawImage =[UIImage imageNamed:@"ClockFrame.png"];
                image = CGImageRetain(ScaleAndRoundCorners(rawImage, CGSizeMake(rawImage.size.width, rawImage.size.height), CGSizeZero, 0, nil, false, nil).CGImage);
            });
            
            return image;
        }
        case ModernClockProgressTypeOutgoingMediaClock:
        {
            static CGImageRef image = NULL;
            
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^
            {
                UIImage *rawImage =[UIImage imageNamed:@"ClockWhiteFrame.png"];
                image = CGImageRetain(ScaleAndRoundCorners(rawImage, CGSizeMake(rawImage.size.width, rawImage.size.height), CGSizeZero, 0, nil, false, nil).CGImage);
            });
            
            return image;
        }
        case ModernClockProgressTypeIncomingClock:
        {
            static CGImageRef image = NULL;
            
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^
            {
                UIImage *rawImage =[UIImage imageNamed:@"ClockIncomingFrame.png"];
                image = CGImageRetain(ScaleAndRoundCorners(rawImage, CGSizeMake(rawImage.size.width, rawImage.size.height), CGSizeZero, 0, nil, false, nil).CGImage);
            });
            
            return image;
        }
    }
    
    return nil;
}

+ (CGImageRef)minImageForType:(ModernClockProgressType)type
{
    switch (type)
    {
        case ModernClockProgressTypeOutgoingClock:
        {
            static CGImageRef image = NULL;
            
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^
            {
                UIImage *rawImage =[UIImage imageNamed:@"ClockMin.png"];
                image = CGImageRetain(ScaleAndRoundCorners(rawImage, CGSizeMake(rawImage.size.width, rawImage.size.height), CGSizeZero, 0, nil, false, nil).CGImage);
            });
            
            return image;
        }
        case ModernClockProgressTypeOutgoingMediaClock:
        {
            static CGImageRef image = NULL;
            
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^
            {
                UIImage *rawImage =[UIImage imageNamed:@"ClockWhiteMin.png"];
                image = CGImageRetain(ScaleAndRoundCorners(rawImage, CGSizeMake(rawImage.size.width, rawImage.size.height), CGSizeZero, 0, nil, false, nil).CGImage);
            });
            
            return image;
        }
        case ModernClockProgressTypeIncomingClock:
        {
            static CGImageRef image = NULL;
            
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^
            {
                UIImage *rawImage =[UIImage imageNamed:@"ClockIncomingMin.png"];
                image = CGImageRetain(ScaleAndRoundCorners(rawImage, CGSizeMake(rawImage.size.width, rawImage.size.height), CGSizeZero, 0, nil, false, nil).CGImage);
            });

            return image;
        }
        default:
            break;
    }
}

+ (CGImageRef)hourImageForType:(ModernClockProgressType)type
{
    switch (type)
    {
        case ModernClockProgressTypeOutgoingClock:
        {
            static CGImageRef image = NULL;
            
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^
            {
                UIImage *rawImage =[UIImage imageNamed:@"ClockHour.png"];
                image = CGImageRetain(ScaleAndRoundCorners(rawImage, CGSizeMake(rawImage.size.width, rawImage.size.height), CGSizeZero, 0, nil, false, nil).CGImage);
            });
            
            return image;
        }
        case ModernClockProgressTypeOutgoingMediaClock:
        {
            static CGImageRef image = NULL;
            
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^
            {
                UIImage *rawImage =[UIImage imageNamed:@"ClockWhiteHour.png"];
                image = CGImageRetain(ScaleAndRoundCorners(rawImage, CGSizeMake(rawImage.size.width, rawImage.size.height), CGSizeZero, 0, nil, false, nil).CGImage);
            });
            
            return image;
        }
        case ModernClockProgressTypeIncomingClock:
        {
            static CGImageRef image = NULL;
            
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^
            {
                UIImage *rawImage = [UIImage imageNamed:@"ClockIncomingHour.png"];
                image = CGImageRetain(ScaleAndRoundCorners(rawImage, CGSizeMake(rawImage.size.width, rawImage.size.height), CGSizeZero, 0, nil, false, nil).CGImage);
            });
            
            return image;
        }
    }
}

- (void)bindViewToContainer:(UIView *)container viewStorage:(ModernViewStorage *)viewStorage
{
    [super bindViewToContainer:container viewStorage:viewStorage];
    
    ModernClockProgressView *view = (ModernClockProgressView *)[self boundView];

    [view setFrameImage:[ModernClockProgressViewModel frameImageForType:_type] hourImage:[ModernClockProgressViewModel hourImageForType:_type] minImage:[ModernClockProgressViewModel minImageForType:_type]];
}

+ (void)setupView:(ModernClockProgressView *)view forType:(ModernClockProgressType)type {
    [view setFrameImage:[ModernClockProgressViewModel frameImageForType:type] hourImage:[ModernClockProgressViewModel hourImageForType:type] minImage:[ModernClockProgressViewModel minImageForType:type]];
}

- (void)drawInContext:(CGContextRef)context
{
    [super drawInContext:context];
    
    if (!self.skipDrawInContext)
    {
        CGContextTranslateCTM(context, 15.0f / 2.0f, 15.0f / 2.0f);
        CGContextScaleCTM(context, 1.0f, -1.0f);
        CGContextTranslateCTM(context, -15.0f / 2.0f, -15.0f / 2.0f);
        
        CGImageRef frameImage = [ModernClockProgressViewModel frameImageForType:_type];
        if (frameImage != NULL)
            CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, 15.0f, 15.0f), frameImage);
        
        CGImageRef hourImage = [ModernClockProgressViewModel hourImageForType:_type];
        if (hourImage != NULL)
            CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, 15.0f, 15.0f), hourImage);

        CGImageRef minImage = [ModernClockProgressViewModel minImageForType:_type];
        if (minImage != NULL)
            CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, 15.0f, 15.0f), minImage);
        
        CGContextTranslateCTM(context, 15.0f / 2.0f, 15.0f / 2.0f);
        CGContextScaleCTM(context, 1.0f, -1.0f);
        CGContextTranslateCTM(context, -15.0f / 2.0f, -15.0f / 2.0f);
    }
}

- (void)sizeToFit
{
    CGRect frame = self.frame;
    frame.size = CGSizeMake(15.0f, 15.0f);
    self.frame = frame;
}

@end
