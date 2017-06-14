#import "Common.h"

#include <sys/sysctl.h>
#include <mach/mach.h>
#include <mach/mach_time.h>

#import <UIKit/UIKit.h>

#import <CommonCrypto/CommonDigest.h>

#import <CoreMotion/CoreMotion.h>

int cpuCoreCount()
{
    static int count = 0;
    if (count == 0)
    {
        size_t len;
        unsigned int ncpu;
        
        len = sizeof(ncpu);
        sysctlbyname("hw.ncpu", &ncpu, &len, NULL, 0);
        count = ncpu;
    }
    
    return count;
}

bool hasModernCpu()
{
    return iosMajorVersion() >= 7 && [CMMotionActivityManager isActivityAvailable];
}

int deviceMemorySize()
{
    static int memorySize = 0;
    if (memorySize == 0)
    {
        size_t len;
        __int64_t nmem;
        
        len = sizeof(nmem);
        sysctlbyname("hw.memsize", &nmem, &len, NULL, 0);
        memorySize = (int)(nmem / (1024 * 1024));
    }
    return memorySize;
}

bool TGObjectCompare(id obj1, id obj2)
{
    if (obj1 == nil && obj2 == nil)
        return true;
    
    return [obj1 isEqual:obj2];
}

bool StringCompare(NSString *s1, NSString *s2)
{
    if (s1.length == 0 && s2.length == 0)
        return true;
    
    if ((s1 == nil) != (s2 == nil))
        return false;
    
    return s1 == nil || [s1 isEqualToString:s2];
}

NSTimeInterval TGCurrentSystemTime()
{
    static mach_timebase_info_data_t timebase;
    if (timebase.denom == 0)
        mach_timebase_info(&timebase);
    
    return ((double)mach_absolute_time()) * ((double)timebase.numer) / ((double)timebase.denom) / 1e9;
}

int iosMajorVersion()
{
    static bool initialized = false;
    static int version = 7;
    if (!initialized)
    {
        switch ([[[UIDevice currentDevice] systemVersion] intValue])
        {
            case 4:
                version = 4;
                break;
            case 5:
                version = 5;
                break;
            case 6:
                version = 6;
                break;
            case 7:
                version = 7;
                break;
            case 8:
                version = 8;
                break;
            case 9:
                version = 9;
                break;
            case 10:
                version = 10;
                break;
            case 11:
                version = 11;
                break;
            default:
                version = 9;
                break;
        }
        
        initialized = true;
    }
    return version;
}
void DispatchOnMainThread(dispatch_block_t block)
{
    if ([NSThread isMainThread])
    block();
    else
    dispatch_async(dispatch_get_main_queue(), block);
}

void DispatchAfter(double delay, dispatch_queue_t queue, dispatch_block_t block)
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((delay) * NSEC_PER_SEC)), queue, block);
}

CFAbsoluteTime MTAbsoluteSystemTime()
{
    static mach_timebase_info_data_t s_timebase_info;
    if (s_timebase_info.denom == 0)
        mach_timebase_info(&s_timebase_info);
    
    return ((CFAbsoluteTime)(mach_absolute_time() * s_timebase_info.numer)) / (s_timebase_info.denom * NSEC_PER_SEC);
}

UIUserInterfaceSizeClass CurrentSizeClass()
{
    UIUserInterfaceSizeClass sizeClass = UIUserInterfaceSizeClassUnspecified;
    if (iosMajorVersion() >= 8)
    {
        sizeClass = UIUserInterfaceSizeClassCompact;
    }
    else
    {
        switch ([UIDevice currentDevice].userInterfaceIdiom)
        {
            case UIUserInterfaceIdiomPad:
                sizeClass = UIUserInterfaceSizeClassRegular;
                break;
                
            default:
                sizeClass = UIUserInterfaceSizeClassCompact;
                break;
        }
    }
    
    return sizeClass;
}

int iosMinorVersion()
{
    static bool initialized = false;
    static int version = 0;
    if (!initialized)
    {
        NSString *versionString = [[UIDevice currentDevice] systemVersion];
        NSRange range = [versionString rangeOfString:@"."];
        if (range.location != NSNotFound)
            version = [[versionString substringFromIndex:range.location + 1] intValue];
        
        initialized = true;
    }
    return version;
}

void printMemoryUsage(NSString *tag)
{
    struct task_basic_info info;
    
    mach_msg_type_number_t size = sizeof(info);
    
    kern_return_t kerr = task_info(mach_task_self(),
                                   
                                   TASK_BASIC_INFO,
                                   
                                   (task_info_t)&info,
                                   
                                   &size);
    if( kerr == KERN_SUCCESS )
    {
        TGLog(@"===== %@: Memory used: %u", tag, info.resident_size / 1024 / 1024);
    }
    else
    {
        TGLog(@"===== %@: Error: %s", tag, mach_error_string(kerr));
    }
}

void TGDumpViews(UIView *view, NSString *indent)
{
    TGLog(@"%@%@", indent, view);
    NSString *newIndent = [[NSString alloc] initWithFormat:@"%@    ", indent];
    for (UIView *child in view.subviews)
        TGDumpViews(child, newIndent);
}

NSString *TGEncodeText(NSString *string, int key)
{
    NSMutableString *result = [[NSMutableString alloc] init];
    
    for (int i = 0; i < (int)[string length]; i++)
    {
        unichar c = [string characterAtIndex:i];
        c += key;
        [result appendString:[NSString stringWithCharacters:&c length:1]];
    }
    
    return result;
}

NSString *StringMD5(NSString *string)
{
    const char *ptr = [string UTF8String];
    unsigned char md5Buffer[16];
    CC_MD5(ptr, (CC_LONG)[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding], md5Buffer);
    NSString *output = [[NSString alloc] initWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x", md5Buffer[0], md5Buffer[1], md5Buffer[2], md5Buffer[3], md5Buffer[4], md5Buffer[5], md5Buffer[6], md5Buffer[7], md5Buffer[8], md5Buffer[9], md5Buffer[10], md5Buffer[11], md5Buffer[12], md5Buffer[13], md5Buffer[14], md5Buffer[15]];

    return output;
}

@implementation NSNumber (IntegerTypes)

- (int32_t)int32Value
{
    return (int32_t)[self intValue];
}

- (int64_t)int64Value
{
    return (int64_t)[self longLongValue];
}

@end

int TGLocalizedStaticVersion = 0;

static NSBundle *customLocalizationBundle = nil;

static NSString *customLocalizationBundlePath()
{
    return @"";//[[TGAppDelegate documentsPath] stringByAppendingPathComponent:@"CustomLocalization.bundle"];
}

void TGSetLocalizationFromFile(NSString *filePath)
{
    TGResetLocalization();
    
    [[NSFileManager defaultManager] createDirectoryAtPath:customLocalizationBundlePath() withIntermediateDirectories:true attributes:nil error:nil];
    
    NSString *stringsFilePath = [customLocalizationBundlePath() stringByAppendingPathComponent:@"Localizable.strings"];
    [[NSFileManager defaultManager] removeItemAtPath:stringsFilePath error:nil];
    
    if ([[NSFileManager defaultManager] copyItemAtPath:filePath toPath:stringsFilePath error:nil])
    {
        NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSString alloc] initWithFormat:@"localiation-%d", (int)arc4random()]];
        [[NSFileManager defaultManager] copyItemAtPath:customLocalizationBundlePath() toPath:tempPath error:nil];
        customLocalizationBundle = [NSBundle bundleWithPath:tempPath];
    }
}

bool TGIsCustomLocalizationActive()
{
    return customLocalizationBundle != nil;
}

void TGResetLocalization()
{
    customLocalizationBundle = nil;
    [[NSFileManager defaultManager] removeItemAtPath:customLocalizationBundlePath() error:nil];
    
    TGLocalizedStaticVersion++;
}

NSString *TGLocalized(NSString *s)
{
    return s;
}

