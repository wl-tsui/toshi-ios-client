#import "PhotoHistogram.h"

@interface PhotoHistogramBins ()
{
    NSArray *_bins;
    NSUInteger _max;
}
@end

@implementation PhotoHistogramBins

- (instancetype)initWithCArray:(NSUInteger *)array
{
    self = [super init];
    if (self != nil)
    {
        _max = 1;
        
        NSMutableArray *bins = [[NSMutableArray alloc] init];
        for (NSUInteger i = 0; i < 256; i++)
        {
            [bins addObject:@(array[i])];
            if (i != 0)
            {
                if (array[i] > _max)
                    _max = array[i];
            }
        }
        
        _bins = bins;
    }
    return self;
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx
{
    if (idx == 0)
        return @0;
    
    if (idx < _bins.count)
        return @([_bins[idx] floatValue] / (CGFloat)_max);
    
    return nil;
}

- (NSUInteger)count
{
    return _bins.count;
}

@end

@interface PhotoHistogram ()
{
    PhotoHistogramBins *_luminance;
    PhotoHistogramBins *_red;
    PhotoHistogramBins *_green;
    PhotoHistogramBins *_blue;
}
@end

@implementation PhotoHistogram

- (instancetype)initWithLuminanceCArray:(NSUInteger *)luminanceArray redCArray:(NSUInteger *)redArray greenCArray:(NSUInteger *)greenArray blueCArray:(NSUInteger *)blueArray
{
    self = [super init];
    if (self != nil)
    {
        _luminance = [[PhotoHistogramBins alloc] initWithCArray:luminanceArray];
        _red = [[PhotoHistogramBins alloc] initWithCArray:redArray];
        _green = [[PhotoHistogramBins alloc] initWithCArray:greenArray];
        _blue = [[PhotoHistogramBins alloc] initWithCArray:blueArray];
    }
    return self;
}

- (PhotoHistogramBins *)histogramBinsForType:(PGCurvesType)type
{
    switch (type)
    {
        case PGCurvesTypeLuminance:
            return _luminance;
            
        case PGCurvesTypeRed:
            return _red;
            
        case PGCurvesTypeGreen:
            return _green;
            
        case PGCurvesTypeBlue:
            return _blue;
            
        default:
            break;
    }
}

@end
