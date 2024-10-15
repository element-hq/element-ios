/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKTools.h"

@import MatrixSDK;
@import Contacts;
@import libPhoneNumber_iOS;
@import DTCoreText;

#import "MXKConstants.h"
#import "NSBundle+MatrixKit.h"
#import "MXKAppSettings.h"
#import <MatrixSDK/MXTools.h>
#import "MXKSwiftHeader.h"

#pragma mark - Constants definitions

// Temporary background color used to identify blockquote blocks with DTCoreText.
#define kMXKToolsBlockquoteMarkColor [UIColor magentaColor]

// Attribute in an NSAttributeString that marks a blockquote block that was in the original HTML string.
NSString *const kMXKToolsBlockquoteMarkAttribute = @"kMXKToolsBlockquoteMarkAttribute";

// Regex expression for permalink detection
NSString *const kMXKToolsRegexStringForPermalink = @"\\/#\\/(?:(?:room|user)\\/)?([^\\s]*)";


#pragma mark - MXKTools static private members
// The regex used to find matrix ids.
static NSRegularExpression *userIdRegex;
static NSRegularExpression *roomIdRegex;
static NSRegularExpression *roomAliasRegex;
static NSRegularExpression *eventIdRegex;
// A regex to find http URLs.
static NSRegularExpression *httpLinksRegex;
// A regex to find all HTML tags
static NSRegularExpression *htmlTagsRegex;
static NSDataDetector *linkDetector;
// A regex to detect permalinks
static NSRegularExpression* permalinkRegex;

@implementation MXKTools

+ (void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        userIdRegex = [NSRegularExpression regularExpressionWithPattern:kMXToolsRegexStringForMatrixUserIdentifier options:NSRegularExpressionCaseInsensitive error:nil];
        roomIdRegex = [NSRegularExpression regularExpressionWithPattern:kMXToolsRegexStringForMatrixRoomIdentifier options:NSRegularExpressionCaseInsensitive error:nil];
        roomAliasRegex = [NSRegularExpression regularExpressionWithPattern:kMXToolsRegexStringForMatrixRoomAlias options:NSRegularExpressionCaseInsensitive error:nil];
        eventIdRegex = [NSRegularExpression regularExpressionWithPattern:kMXToolsRegexStringForMatrixEventIdentifier options:NSRegularExpressionCaseInsensitive error:nil];
        
        httpLinksRegex = [NSRegularExpression regularExpressionWithPattern:@"(?i)\\b(https?://\\S*)\\b" options:NSRegularExpressionCaseInsensitive error:nil];
        htmlTagsRegex  = [NSRegularExpression regularExpressionWithPattern:@"<(\\w+)[^>]*>" options:NSRegularExpressionCaseInsensitive error:nil];
        linkDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
               
        // if we have a custom clientPermalinkBaseUrl, we also need to support matrix.to permalinks
        NSString *permalinkPattern = [NSString stringWithFormat:@"(?:%@|%@)%@", BuildSettings.clientPermalinkBaseUrl, kMXMatrixDotToUrl, kMXKToolsRegexStringForPermalink];
        permalinkRegex = [NSRegularExpression regularExpressionWithPattern:permalinkPattern options:NSRegularExpressionCaseInsensitive error:nil];
    });
}

#pragma mark - Strings

+ (BOOL)isSingleEmojiString:(NSString *)string
{
    return [MXKTools isEmojiString:string singleEmoji:YES];
}

+ (BOOL)isEmojiOnlyString:(NSString *)string
{
    return [MXKTools isEmojiString:string singleEmoji:NO];
}

// Highly inspired from https://stackoverflow.com/a/34659249
+ (BOOL)isEmojiString:(NSString*)string singleEmoji:(BOOL)singleEmoji
{
    if (string.length == 0)
    {
        return NO;
    }

    __block BOOL result = YES;

    NSRange stringRange = NSMakeRange(0, [string length]);

    [string enumerateSubstringsInRange:stringRange
                               options:NSStringEnumerationByComposedCharacterSequences
                            usingBlock:^(NSString *substring,
                                         NSRange substringRange,
                                         NSRange enclosingRange,
                                         BOOL *stop)
     {
         BOOL isEmoji = NO;

         if (singleEmoji && !NSEqualRanges(stringRange, substringRange))
         {
             // The string contains several characters. Go out
             result = NO;
             *stop = YES;
             return;
         }

         const unichar hs = [substring characterAtIndex:0];
         // Surrogate pair
         if (0xd800 <= hs &&
             hs <= 0xdbff)
         {
             if (substring.length > 1)
             {
                 const unichar ls = [substring characterAtIndex:1];
                 const int uc = ((hs - 0xd800) * 0x400) + (ls - 0xdc00) + 0x10000;
                 if (0x1d000 <= uc &&
                     uc <= 0x1f9ff)
                 {
                     isEmoji = YES;
                 }
             }
         }
         else if (substring.length > 1)
         {
             const unichar ls = [substring characterAtIndex:1];
             if (ls == 0x20e3 ||
                 ls == 0xfe0f ||
                 ls == 0xd83c)
             {
                 isEmoji = YES;
             }
         }
         else
         {
             // Non surrogate
             if (0x2100 <= hs &&
                 hs <= 0x27ff)
             {
                 isEmoji = YES;
             }
             else if (0x2B05 <= hs &&
                      hs <= 0x2b07)
             {
                 isEmoji = YES;
             }
             else if (0x2934 <= hs &&
                      hs <= 0x2935)
             {
                 isEmoji = YES;
             }
             else if (0x3297 <= hs &&
                      hs <= 0x3299)
             {
                 isEmoji = YES;
             }
             else if (hs == 0xa9 ||
                      hs == 0xae ||
                      hs == 0x303d ||
                      hs == 0x3030 ||
                      hs == 0x2b55 ||
                      hs == 0x2b1c ||
                      hs == 0x2b1b ||
                      hs == 0x2b50)
             {
                 isEmoji = YES;
             }
         }

         if (!isEmoji)
         {
             result = NO;
             *stop = YES;
         }
     }];

    return result;
}

#pragma mark - Time interval

+ (NSString*)formatSecondsInterval:(CGFloat)secondsInterval
{
    NSMutableString* formattedString = [[NSMutableString alloc] init];
    
    if (secondsInterval < 1)
    {
        [formattedString appendFormat:@"< 1%@", [VectorL10n formatTimeS]];
    }
    else if (secondsInterval < 60)
    {
        [formattedString appendFormat:@"%d%@", (int)secondsInterval, [VectorL10n formatTimeS]];
    }
    else if (secondsInterval < 3600)
    {
        [formattedString appendFormat:@"%d%@ %2d%@", (int)(secondsInterval/60), [VectorL10n formatTimeM],
         ((int)secondsInterval) % 60, [VectorL10n formatTimeS]];
    }
    else if (secondsInterval >= 3600)
    {
        [formattedString appendFormat:@"%d%@ %d%@ %d%@", (int)(secondsInterval / 3600), [VectorL10n formatTimeH],
         ((int)(secondsInterval) % 3600) / 60, [VectorL10n formatTimeM],
         (int)(secondsInterval) % 60, [VectorL10n formatTimeS]];
    }
    [formattedString appendString:@" left"];
    
    return formattedString;
}

+ (NSString *)formatSecondsIntervalFloored:(CGFloat)secondsInterval
{
    NSString* formattedString;

    if (secondsInterval < 0)
    {
        formattedString = [NSString stringWithFormat:@"0%@", [VectorL10n formatTimeS]];
    }
    else
    {
        NSUInteger seconds = secondsInterval;
        if (seconds < 60)
        {
            formattedString = [NSString stringWithFormat:@"%tu%@", seconds, [VectorL10n formatTimeS]];
        }
        else if (secondsInterval < 3600)
        {
            formattedString = [NSString stringWithFormat:@"%tu%@", seconds / 60, [VectorL10n formatTimeM]];
        }
        else if (secondsInterval < 86400)
        {
            formattedString = [NSString stringWithFormat:@"%tu%@", seconds / 3600, [VectorL10n formatTimeH]];
        }
        else
        {
            formattedString = [NSString stringWithFormat:@"%tu%@", seconds / 86400, [VectorL10n formatTimeD]];
        }
    }

    return formattedString;
}

#pragma mark - Phone number

+ (NSString*)msisdnWithPhoneNumber:(NSString *)phoneNumber andCountryCode:(NSString *)countryCode
{
    NSString *msisdn = nil;
    NBPhoneNumber *phoneNb;
    
    if ([phoneNumber hasPrefix:@"+"] || [phoneNumber hasPrefix:@"00"])
    {
        phoneNb = [[NBPhoneNumberUtil sharedInstance] parse:phoneNumber defaultRegion:nil error:nil];
    }
    else
    {
        // Check whether the provided phone number is a valid msisdn.
        NSString *e164 = [NSString stringWithFormat:@"+%@", phoneNumber];
        phoneNb = [[NBPhoneNumberUtil sharedInstance] parse:e164 defaultRegion:nil error:nil];
        
        if (![[NBPhoneNumberUtil sharedInstance] isValidNumber:phoneNb])
        {
            // Consider the phone number as a national one, and use the country code.
            phoneNb = [[NBPhoneNumberUtil sharedInstance] parse:phoneNumber defaultRegion:countryCode error:nil];
        }
    }
    
    if ([[NBPhoneNumberUtil sharedInstance] isValidNumber:phoneNb])
    {
        NSString *e164 = [[NBPhoneNumberUtil sharedInstance] format:phoneNb numberFormat:NBEPhoneNumberFormatE164 error:nil];
        
        if ([e164 hasPrefix:@"+"])
        {
            msisdn = [e164 substringFromIndex:1];
        }
        else if ([e164 hasPrefix:@"00"])
        {
            msisdn = [e164 substringFromIndex:2];
        }
    }
    
    return msisdn;
}

+ (NSString*)readableMSISDN:(NSString*)msisdn
{
    NSString *e164;
    
    if (([e164 hasPrefix:@"+"]))
    {
        e164 = msisdn;
    }
    else
    {
        e164 = [NSString stringWithFormat:@"+%@", msisdn];
    }
    
    NBPhoneNumber *phoneNb = [[NBPhoneNumberUtil sharedInstance] parse:e164 defaultRegion:nil error:nil];
    return [[NBPhoneNumberUtil sharedInstance] format:phoneNb numberFormat:NBEPhoneNumberFormatINTERNATIONAL error:nil];
}

#pragma mark - Hex color to UIColor conversion

+ (UIColor *)colorWithRGBValue:(NSUInteger)rgbValue
{
    return [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0];
}

+ (UIColor *)colorWithARGBValue:(NSUInteger)argbValue
{
    return [UIColor colorWithRed:((float)((argbValue & 0xFF0000) >> 16))/255.0 green:((float)((argbValue & 0xFF00) >> 8))/255.0 blue:((float)(argbValue & 0xFF))/255.0 alpha:((float)((argbValue & 0xFF000000) >> 24))/255.0];
}

+ (NSUInteger)rgbValueWithColor:(UIColor*)color
{
    CGFloat red, green, blue, alpha;
    
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    
    NSUInteger rgbValue = ((int)(red * 255) << 16) + ((int)(green * 255) << 8) + (blue * 255);
    
    return rgbValue;
}

+ (NSUInteger)argbValueWithColor:(UIColor*)color
{
    CGFloat red, green, blue, alpha;
    
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    
    NSUInteger argbValue = ((int)(alpha * 255) << 24) + ((int)(red * 255) << 16) + ((int)(green * 255) << 8) + (blue * 255);
    
    return argbValue;
}

#pragma mark - Image

+ (UIImage*)forceImageOrientationUp:(UIImage*)imageSrc
{
    if ((imageSrc.imageOrientation == UIImageOrientationUp) || (!imageSrc))
    {
        // Nothing to do
        return imageSrc;
    }
    
    // Draw the entire image in a graphics context, respecting the image’s orientation setting
    UIGraphicsBeginImageContext(imageSrc.size);
    [imageSrc drawAtPoint:CGPointMake(0, 0)];
    UIImage *retImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return retImage;
}

+ (MXKImageCompressionSizes)availableCompressionSizesForImage:(UIImage*)image originalFileSize:(NSUInteger)originalFileSize
{
    MXKImageCompressionSizes compressionSizes;
    memset(&compressionSizes, 0, sizeof(MXKImageCompressionSizes));
    
    // Store the original
    compressionSizes.original.imageSize = image.size;
    compressionSizes.original.fileSize = originalFileSize ? originalFileSize : UIImageJPEGRepresentation(image, 0.9).length;
    
    MXLogDebug(@"[MXKTools] availableCompressionSizesForImage: %f %f - File size: %tu", compressionSizes.original.imageSize.width, compressionSizes.original.imageSize.height, compressionSizes.original.fileSize);
    
    compressionSizes.actualLargeSize = MXKTOOLS_LARGE_IMAGE_SIZE;
    
    // Compute the file size for each compression level
    CGFloat maxSize = MAX(compressionSizes.original.imageSize.width, compressionSizes.original.imageSize.height);
    if (maxSize >= MXKTOOLS_SMALL_IMAGE_SIZE)
    {
        compressionSizes.small.imageSize = [MXKTools resizeImageSize:compressionSizes.original.imageSize toFitInSize:CGSizeMake(MXKTOOLS_SMALL_IMAGE_SIZE, MXKTOOLS_SMALL_IMAGE_SIZE) canExpand:NO];
        
        compressionSizes.small.fileSize = (NSUInteger)[MXTools roundFileSize:(long long)(compressionSizes.small.imageSize.width * compressionSizes.small.imageSize.height * 0.20)];
        
        if (maxSize >= MXKTOOLS_MEDIUM_IMAGE_SIZE)
        {
            compressionSizes.medium.imageSize = [MXKTools resizeImageSize:compressionSizes.original.imageSize toFitInSize:CGSizeMake(MXKTOOLS_MEDIUM_IMAGE_SIZE, MXKTOOLS_MEDIUM_IMAGE_SIZE) canExpand:NO];
            
            compressionSizes.medium.fileSize = (NSUInteger)[MXTools roundFileSize:(long long)(compressionSizes.medium.imageSize.width * compressionSizes.medium.imageSize.height * 0.20)];
            
            if (maxSize >= MXKTOOLS_LARGE_IMAGE_SIZE)
            {
                // In case of panorama the large resolution (1024 x ...) is not relevant. We prefer consider the third of the panarama width.
                compressionSizes.actualLargeSize = maxSize / 3;
                if (compressionSizes.actualLargeSize < MXKTOOLS_LARGE_IMAGE_SIZE)
                {
                    compressionSizes.actualLargeSize = MXKTOOLS_LARGE_IMAGE_SIZE;
                }
                else
                {
                    // Keep a multiple of predefined large size
                    compressionSizes.actualLargeSize = floor(compressionSizes.actualLargeSize / MXKTOOLS_LARGE_IMAGE_SIZE) * MXKTOOLS_LARGE_IMAGE_SIZE;
                }
                
                compressionSizes.large.imageSize = [MXKTools resizeImageSize:compressionSizes.original.imageSize toFitInSize:CGSizeMake(compressionSizes.actualLargeSize, compressionSizes.actualLargeSize) canExpand:NO];
                
                compressionSizes.large.fileSize = (NSUInteger)[MXTools roundFileSize:(long long)(compressionSizes.large.imageSize.width * compressionSizes.large.imageSize.height * 0.20)];
            }
            else
            {
                MXLogDebug(@"    - too small to fit in %d", MXKTOOLS_LARGE_IMAGE_SIZE);
            }
        }
        else
        {
            MXLogDebug(@"    - too small to fit in %d", MXKTOOLS_MEDIUM_IMAGE_SIZE);
        }
    }
    else
    {
        MXLogDebug(@"    - too small to fit in %d", MXKTOOLS_SMALL_IMAGE_SIZE);
    }
    
    return compressionSizes;
}


+ (CGSize)resizeImageSize:(CGSize)originalSize toFitInSize:(CGSize)maxSize canExpand:(BOOL)canExpand
{
    if ((originalSize.width == 0) || (originalSize.height == 0))
    {
        return CGSizeZero;
    }
    
    CGSize resized = originalSize;
    
    if ((maxSize.width > 0) && (maxSize.height > 0) && (canExpand || ((originalSize.width > maxSize.width) || (originalSize.height > maxSize.height))))
    {
        CGFloat ratioX = maxSize.width  / originalSize.width;
        CGFloat ratioY = maxSize.height / originalSize.height;
        
        CGFloat scale = MIN(ratioX, ratioY);
        resized.width  *= scale;
        resized.height *= scale;
        
        // padding
        resized.width  = floorf(resized.width  / 2) * 2;
        resized.height = floorf(resized.height / 2) * 2;
    }
    
    return resized;
}

+ (CGSize)resizeImageSize:(CGSize)originalSize toFillWithSize:(CGSize)maxSize canExpand:(BOOL)canExpand
{
    CGSize resized = originalSize;
    
    if ((maxSize.width > 0) && (maxSize.height > 0) && (canExpand || ((originalSize.width > maxSize.width) && (originalSize.height > maxSize.height))))
    {
        CGFloat ratioX = maxSize.width  / originalSize.width;
        CGFloat ratioY = maxSize.height / originalSize.height;
        
        CGFloat scale = MAX(ratioX, ratioY);
        resized.width  *= scale;
        resized.height *= scale;
        
        // padding
        resized.width  = floorf(resized.width  / 2) * 2;
        resized.height = floorf(resized.height / 2) * 2;
    }
    
    return resized;
}

+ (UIImage *)reduceImage:(UIImage *)image toFitInSize:(CGSize)size
{
    return [self reduceImage:image toFitInSize:size useMainScreenScale:NO];
}

+ (UIImage *)reduceImage:(UIImage *)image toFitInSize:(CGSize)size useMainScreenScale:(BOOL)useMainScreenScale
{
    UIImage *resizedImage;
    
    // Check whether resize is required
    if (size.width && size.height)
    {
        CGFloat width = image.size.width;
        CGFloat height = image.size.height;
        
        if (width > size.width)
        {
            height = (height * size.width) / width;
            height = floorf(height / 2) * 2;
            width = size.width;
        }
        if (height > size.height)
        {
            width = (width * size.height) / height;
            width = floorf(width / 2) * 2;
            height = size.height;
        }
        
        if (width != image.size.width || height != image.size.height)
        {
            // Create the thumbnail
            CGSize imageSize = CGSizeMake(width, height);
            
            // Convert first the provided size in pixels
            
            // The scale factor is set to 0.0 to use the scale factor of the device’s main screen.
            CGFloat scale = useMainScreenScale ? 0.0 : 1.0;
            
            UIGraphicsBeginImageContextWithOptions(imageSize, NO, scale);
            
            //            // set to the top quality
            //            CGContextRef context = UIGraphicsGetCurrentContext();
            //            CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
            
            CGRect thumbnailRect = CGRectMake(0, 0, 0, 0);
            thumbnailRect.origin = CGPointMake(0.0,0.0);
            thumbnailRect.size.width  = imageSize.width;
            thumbnailRect.size.height = imageSize.height;
            
            [image drawInRect:thumbnailRect];
            resizedImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
    }
    else
    {
        resizedImage = image;
    }
    
    return resizedImage;
}

+ (UIImage*)resizeImageWithData:(NSData*)imageData toFitInSize:(CGSize)size
{
    // Create the image source
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);

    // Take the max dimension of size to fit in
    CGFloat maxPixelSize = fmax(size.width, size.height);

    //Create thumbnail options
    CFDictionaryRef options = (__bridge CFDictionaryRef) @{
                                                           (id) kCGImageSourceCreateThumbnailWithTransform : (id)kCFBooleanTrue,
                                                           (id) kCGImageSourceCreateThumbnailFromImageAlways : (id)kCFBooleanTrue,
                                                           (id) kCGImageSourceThumbnailMaxPixelSize : @(maxPixelSize)
                                                           };

    // Generate the thumbnail
    CGImageRef resizedImageRef = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options);

    UIImage *resizedImage = [[UIImage alloc] initWithCGImage:resizedImageRef];

    CGImageRelease(resizedImageRef);
    CFRelease(imageSource);

    return resizedImage;
}

+ (UIImage*)resizeImage:(UIImage *)image toSize:(CGSize)size
{
    UIImage *resizedImage = image;
    
    // Check whether resize is required
    if (size.width && size.height)
    {
        // Convert first the provided size in pixels
        // The scale factor is set to 0.0 to use the scale factor of the device’s main screen.
        UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
        
        [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
        resizedImage = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
    }
    
    return resizedImage;
}

+ (UIImage*)resizeImageWithRoundedCorners:(UIImage *)image toSize:(CGSize)size
{
    UIImage *resizedImage = image;
    
    // Check whether resize is required
    if (size.width && size.height)
    {
        // Convert first the provided size in pixels
        // The scale factor is set to 0.0 to use the scale factor of the device’s main screen.
        UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
        
        // Add a clip to round corners
        [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, size.width, size.height) cornerRadius:size.width/2] addClip];
        
        [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
        resizedImage = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
    }
    
    return resizedImage;
}

+ (UIImage*)paintImage:(UIImage*)image withColor:(UIColor*)color
{
    UIImage *newImage;
    
    const CGFloat *colorComponents = CGColorGetComponents(color.CGColor);
    
    // Create a new image with the same size
    UIGraphicsBeginImageContextWithOptions(image.size, 0, 0);
    
    CGContextRef gc = UIGraphicsGetCurrentContext();
    
    CGRect rect = (CGRect){ .size = image.size};
    
    [image drawInRect:rect
            blendMode:kCGBlendModeNormal
                alpha:1];
    
    // Binarize the image: Transform all colors into the provided color but keep the alpha
    CGContextSetBlendMode(gc, kCGBlendModeSourceIn);
    CGContextSetRGBFillColor(gc, colorComponents[0], colorComponents[1], colorComponents[2], colorComponents[3]);
    CGContextFillRect(gc, rect);
    
    // Retrieve the result into an UIImage
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return newImage;
}

+ (UIImageOrientation)imageOrientationForRotationAngleInDegree:(NSInteger)angle
{
    NSInteger modAngle = angle % 360;
    
    UIImageOrientation orientation = UIImageOrientationUp;
    if (45 <= modAngle && modAngle < 135)
    {
        return UIImageOrientationRight;
    }
    else if (135 <= modAngle && modAngle < 225)
    {
        return UIImageOrientationDown;
    }
    else if (225 <= modAngle && modAngle < 315)
    {
        return UIImageOrientationLeft;
    }
    
    return orientation;
}

static NSMutableDictionary* backgroundByImageNameDict;

+ (UIColor*)convertImageToPatternColor:(NSString*)resourceName backgroundColor:(UIColor*)backgroundColor patternSize:(CGSize)patternSize resourceSize:(CGSize)resourceSize
{
    if (!resourceName)
    {
        return backgroundColor;
    }
    
    if (!backgroundByImageNameDict)
    {
        backgroundByImageNameDict = [[NSMutableDictionary alloc] init];
    }
    
    NSString* key = [NSString stringWithFormat:@"%@ %f %f", resourceName, patternSize.width, resourceSize.width];
    
    UIColor* bgColor = [backgroundByImageNameDict objectForKey:key];
    
    if (!bgColor)
    {
        UIImageView* backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, patternSize.width, patternSize.height)];
        backgroundView.backgroundColor = backgroundColor;
        
        CGFloat offsetX = (patternSize.width - resourceSize.width) / 2.0f;
        CGFloat offsetY = (patternSize.height - resourceSize.height) / 2.0f;
        
        UIImageView* resourceImageView = [[UIImageView alloc] initWithFrame:CGRectMake(offsetX, offsetY, resourceSize.width, resourceSize.height)];
        resourceImageView.backgroundColor = [UIColor clearColor];
        UIImage *resImage = [UIImage imageNamed:resourceName];
        if (CGSizeEqualToSize(resImage.size, resourceSize))
        {
            resourceImageView.image = resImage;
        }
        else
        {
            resourceImageView.image = [MXKTools resizeImage:resImage toSize:resourceSize];
        }
        
        
        [backgroundView addSubview:resourceImageView];
        
        // Create a "canvas" (image context) to draw in.
        UIGraphicsBeginImageContextWithOptions(backgroundView.frame.size, NO, 0);
        
        // set to the top quality
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
        [[backgroundView layer] renderInContext: UIGraphicsGetCurrentContext()];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        
        bgColor = [[UIColor alloc] initWithPatternImage:image];
        [backgroundByImageNameDict setObject:bgColor forKey:key];
    }
    
    return bgColor;
}

#pragma mark - Video Conversion

+ (UIAlertController*)videoConversionPromptForVideoAsset:(AVAsset *)videoAsset
                                           withCompletion:(void (^)(NSString * _Nullable presetName))completion
{
    UIAlertController *compressionPrompt = [UIAlertController alertControllerWithTitle:[VectorL10n attachmentSizePromptTitle]
                                                                               message:[VectorL10n attachmentSizePromptMessage]
                                                                        preferredStyle:UIAlertControllerStyleActionSheet];
    
    CGSize naturalSize = [videoAsset tracksWithMediaType:AVMediaTypeVideo].firstObject.naturalSize;
    
    // Provide 480p as the baseline preset.
    NSString *fileSizeString = [MXKTools estimatedFileSizeStringForVideoAsset:videoAsset withPresetName:AVAssetExportPreset640x480];
    NSString *title = [VectorL10n attachmentSmallWithResolution:@"480p" :fileSizeString];
    [compressionPrompt addAction:[UIAlertAction actionWithTitle:title
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * action) {
        // Call the completion with 480p preset.
        completion(AVAssetExportPreset640x480);
    }]];
    
    // Allow 720p when the video exceeds 480p.
    if (naturalSize.height > 480)
    {
        NSString *fileSizeString = [MXKTools estimatedFileSizeStringForVideoAsset:videoAsset withPresetName:AVAssetExportPreset1280x720];
        NSString *title = [VectorL10n attachmentMediumWithResolution:@"720p" :fileSizeString];
        [compressionPrompt addAction:[UIAlertAction actionWithTitle:title
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * action) {
            // Call the completion with 720p preset.
            completion(AVAssetExportPreset1280x720);
        }]];
    }
    
    // Allow 1080p when the video exceeds 720p.
    if (naturalSize.height > 720)
    {
        NSString *fileSizeString = [MXKTools estimatedFileSizeStringForVideoAsset:videoAsset withPresetName:AVAssetExportPreset1920x1080];
        NSString *title = [VectorL10n attachmentLargeWithResolution:@"1080p" :fileSizeString];
        [compressionPrompt addAction:[UIAlertAction actionWithTitle:title
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * action) {
            // Call the completion with 1080p preset.
            completion(AVAssetExportPreset1920x1080);
        }]];
    }
    
    [compressionPrompt addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                          style:UIAlertActionStyleCancel
                                                        handler:^(UIAlertAction * action) {
        // Cancelled. Call the completion with nil.
        completion(nil);
    }]];
    
    return compressionPrompt;
}

+ (NSString *)estimatedFileSizeStringForVideoAsset:(AVAsset *)videoAsset withPresetName:(NSString *)presetName
{
    AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:videoAsset presetName:presetName];
    exportSession.timeRange = CMTimeRangeMake(kCMTimeZero, videoAsset.duration);
    
    return [MXTools fileSizeToString:exportSession.estimatedOutputFileLength];
}

#pragma mark - App permissions

+ (void)checkAccessForMediaType:(NSString *)mediaType
            manualChangeMessage:(NSString *)manualChangeMessage
      showPopUpInViewController:(UIViewController *)viewController
              completionHandler:(void (^)(BOOL))handler
{
    [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {

        dispatch_async(dispatch_get_main_queue(), ^{

            if (granted)
            {
                handler(YES);
            }
            else
            {
                // Access not granted to mediaType
                // Display manualChangeMessage
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:manualChangeMessage preferredStyle:UIAlertControllerStyleAlert];

                // On iOS >= 8, add a shortcut to the app settings (This requires the shared application instance)
                UIApplication *sharedApplication = [UIApplication performSelector:@selector(sharedApplication)];
                if (sharedApplication && UIApplicationOpenSettingsURLString)
                {
                    [alert addAction:[UIAlertAction actionWithTitle:[VectorL10n settings]
                                                                     style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * action) {
                                                                       
                                                                       NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                                                                       [sharedApplication performSelector:@selector(openURL:) withObject:url];
                                                                       
                                                                       // Note: it does not worth to check if the user changes the permission
                                                                       // because iOS restarts the app in case of change of app privacy settings
                                                                       handler(NO);
                                                                       
                                                                   }]];
                }
                
                [alert addAction:[UIAlertAction actionWithTitle:[VectorL10n ok]
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * action) {
                                                            
                                                            handler(NO);
                                                            
                                                        }]];
                
                [viewController presentViewController:alert animated:YES completion:nil];
            }
            
        });
    }];
}

+ (void)checkAccessForCall:(BOOL)isVideoCall
manualChangeMessageForAudio:(NSString*)manualChangeMessageForAudio
manualChangeMessageForVideo:(NSString*)manualChangeMessageForVideo
 showPopUpInViewController:(UIViewController*)viewController
         completionHandler:(void (^)(BOOL granted))handler
{
    // Check first microphone permission
    [MXKTools checkAccessForMediaType:AVMediaTypeAudio manualChangeMessage:manualChangeMessageForAudio showPopUpInViewController:viewController completionHandler:^(BOOL granted) {

        if (granted)
        {
            // Check camera permission in case of video call
            if (isVideoCall)
            {
                [MXKTools checkAccessForMediaType:AVMediaTypeVideo manualChangeMessage:manualChangeMessageForVideo showPopUpInViewController:viewController completionHandler:^(BOOL granted) {

                    handler(granted);
                }];
            }
            else
            {
                handler(YES);
            }
        }
        else
        {
            handler(NO);
        }
    }];
}

+ (void)checkAccessForContacts:(NSString *)manualChangeMessage
     showPopUpInViewController:(UIViewController *)viewController
             completionHandler:(void (^)(BOOL granted))handler
{
    [self checkAccessForContacts:nil withManualChangeMessage:manualChangeMessage showPopUpInViewController:viewController completionHandler:handler];
}

+ (void)checkAccessForContacts:(NSString *)manualChangeTitle
       withManualChangeMessage:(NSString *)manualChangeMessage
     showPopUpInViewController:(UIViewController *)viewController
             completionHandler:(void (^)(BOOL granted))handler
{
    // Check if the application is allowed to list the contacts
    CNAuthorizationStatus authStatus = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    if (authStatus == CNAuthorizationStatusAuthorized)
    {
        handler(YES);
    }
    else if (authStatus == CNAuthorizationStatusNotDetermined)
    {
        // Request address book access
        [[CNContactStore new] requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
            
            [MXSDKOptions.sharedInstance.analyticsDelegate trackContactsAccessGranted:granted];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                handler(granted);
                
            });
        }];
    }
    else if (authStatus == CNAuthorizationStatusDenied && viewController && manualChangeMessage)
    {
        // Access not granted to the local contacts
        // Display manualChangeMessage
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:manualChangeTitle message:manualChangeMessage preferredStyle:UIAlertControllerStyleAlert];

        [alert addAction:[UIAlertAction actionWithTitle:VectorL10n.cancel
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * action) {
            
            handler(NO);
            
        }]];
        
        // Add a shortcut to the app settings (This requires the shared application instance)
        UIApplication *sharedApplication = [UIApplication performSelector:@selector(sharedApplication)];
        if (sharedApplication)
        {
            UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:VectorL10n.settings
                                                                     style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * action) {
                [MXKAppSettings standardAppSettings].syncLocalContactsPermissionOpenedSystemSettings = YES;
                // Wait for the setting to be saved as the app could be killed imminently.
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                [sharedApplication performSelector:@selector(openURL:) withObject:url];
                
                // Note: it does not worth to check if the user changes the permission
                // because iOS restarts the app in case of change of app privacy settings
                handler(NO);
            }];
            
            [alert addAction: settingsAction];
            alert.preferredAction = settingsAction;
        }
        
        [viewController presentViewController:alert animated:YES completion:nil];
    }
    else
    {
        handler(NO);
    }
}

#pragma mark - HTML processing

+ (void)removeDTCoreTextArtifacts:(NSMutableAttributedString*)mutableAttributedString
{
    // DTCoreText adds a newline at the end of plain text ( https://github.com/Cocoanetics/DTCoreText/issues/779 )
    // or after a blockquote section.
    // Trim trailing whitespace and newlines in the string content
    while ([mutableAttributedString.string hasSuffixCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]])
    {
        [mutableAttributedString deleteCharactersInRange:NSMakeRange(mutableAttributedString.length - 1, 1)];
    }
    
    // New lines may have also been introduced by the paragraph style
    // Make sure the last paragraph style has no spacing
    [mutableAttributedString enumerateAttributesInRange:NSMakeRange(0, mutableAttributedString.length) options:(NSAttributedStringEnumerationReverse) usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
        
        if (attrs[NSParagraphStyleAttributeName])
        {
            NSString *subString = [mutableAttributedString.string substringWithRange:range];
            NSArray *components = [subString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            
            NSMutableDictionary *updatedAttrs = [NSMutableDictionary dictionaryWithDictionary:attrs];
            NSMutableParagraphStyle *paragraphStyle = [updatedAttrs[NSParagraphStyleAttributeName] mutableCopy];
            paragraphStyle.paragraphSpacing = 0;
            updatedAttrs[NSParagraphStyleAttributeName] = paragraphStyle;
            
            if (components.count > 1)
            {
                NSString *lastComponent = components.lastObject;
                
                NSRange range2 = NSMakeRange(range.location, range.length - lastComponent.length);
                [mutableAttributedString setAttributes:attrs range:range2];
                
                range2 = NSMakeRange(range2.location + range2.length, lastComponent.length);
                [mutableAttributedString setAttributes:updatedAttrs range:range2];
            }
            else
            {
                [mutableAttributedString setAttributes:updatedAttrs range:range];
            }
        }
        
        // Check only the last paragraph
        *stop = YES;
    }];
    
    // Image rendering failed on an exception until we replace the DTImageTextAttachments with a simple NSTextAttachment subclass
    // (thanks to https://github.com/Cocoanetics/DTCoreText/issues/863).
    [mutableAttributedString enumerateAttribute:NSAttachmentAttributeName
                                        inRange:NSMakeRange(0, mutableAttributedString.length)
                                        options:0
                                     usingBlock:^(id value, NSRange range, BOOL *stop) {
                                         
                                         if ([value isKindOfClass:DTImageTextAttachment.class])
                                         {
                                             DTImageTextAttachment *attachment = (DTImageTextAttachment*)value;
                                             NSTextAttachment *textAttachment = [[NSTextAttachment alloc] init];
                                             if (attachment.image)
                                             {
                                                 textAttachment.image = attachment.image;
                                                 
                                                 CGRect frame = textAttachment.bounds;
                                                 frame.size = attachment.displaySize;
                                                 textAttachment.bounds = frame;
                                             }
                                             // Note we remove here attachment without image.
                                             NSAttributedString *attrStringWithImage = [NSAttributedString attributedStringWithAttachment:textAttachment];
                                             [mutableAttributedString replaceCharactersInRange:range withAttributedString:attrStringWithImage];
                                         }
                                     }];
}

+ (void)createLinksInMutableAttributedString:(NSMutableAttributedString*)mutableAttributedString forEnabledMatrixIds:(NSInteger)enabledMatrixIdsBitMask
{
    if (!mutableAttributedString)
    {
        return;
    }

    // If enabled, make user id clickable
    if (enabledMatrixIdsBitMask & MXKTOOLS_USER_IDENTIFIER_BITWISE)
    {
        [MXKTools createLinksInMutableAttributedString:mutableAttributedString matchingRegex:userIdRegex];
    }
    
    // If enabled, make room id clickable
    if (enabledMatrixIdsBitMask & MXKTOOLS_ROOM_IDENTIFIER_BITWISE)
    {
        [MXKTools createLinksInMutableAttributedString:mutableAttributedString matchingRegex:roomIdRegex];
    }
    
    // If enabled, make room alias clickable
    if (enabledMatrixIdsBitMask & MXKTOOLS_ROOM_ALIAS_BITWISE)
    {
        [MXKTools createLinksInMutableAttributedString:mutableAttributedString matchingRegex:roomAliasRegex];
    }
    
    // If enabled, make event id clickable
    if (enabledMatrixIdsBitMask & MXKTOOLS_EVENT_IDENTIFIER_BITWISE)
    {
        [MXKTools createLinksInMutableAttributedString:mutableAttributedString matchingRegex:eventIdRegex];
    }
        
    // Permalinks
    NSArray* matches = [httpLinksRegex matchesInString: [mutableAttributedString string] options:0 range: NSMakeRange(0,mutableAttributedString.length)];
    if (matches) {
        for (NSTextCheckingResult *match in matches)
        {
            NSRange matchRange = [match range];

            NSString *link = [mutableAttributedString.string substringWithRange:matchRange];
            // Handle potential permalinks
            if ([permalinkRegex numberOfMatchesInString:link options:0 range:NSMakeRange(0, link.length)]) {
                NSURLComponents *url = [[NSURLComponents new] initWithString:link];
                if (url.URL)
                {
                    [mutableAttributedString addAttribute:NSLinkAttributeName value:url.URL range:matchRange];
                }
            }
        }
    }
    
    // This allows to check for normal url based links (like https://element.io)
    // And set back the default link color
    matches = [linkDetector matchesInString: [mutableAttributedString string] options:0 range: NSMakeRange(0,mutableAttributedString.length)];
    if (matches)
    {
        for (NSTextCheckingResult *match in matches)
        {
            NSRange matchRange = [match range];
            NSURL *matchUrl = [match URL];
            NSURLComponents *url = [[NSURLComponents new] initWithURL:matchUrl resolvingAgainstBaseURL:NO];
            if (url.URL)
            {
                [mutableAttributedString addAttribute:NSForegroundColorAttributeName value:ThemeService.shared.theme.colors.links range:matchRange];
            }
        }
    }
}

+ (void)createLinksInMutableAttributedString:(NSMutableAttributedString*)mutableAttributedString matchingRegex:(NSRegularExpression*)regex
{
    __block NSArray *linkMatches;
    
    // Enumerate each string matching the regex
    [regex enumerateMatchesInString:mutableAttributedString.string
                            options:0
                              range:NSMakeRange(0, mutableAttributedString.length)
                         usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
        
        // Do not create a link if there is already one on the found match
        __block BOOL hasAlreadyLink = NO;
        [mutableAttributedString enumerateAttributesInRange:match.range
                                                    options:0
                                                 usingBlock:^(NSDictionary<NSString *,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
            
            if (attrs[NSLinkAttributeName])
            {
                hasAlreadyLink = YES;
                *stop = YES;
            }
        }];
        
        // Do not create a link if the match is part of an http link.
        // The http link will be automatically generated by the UI afterwards.
        // So, do not break it now by adding a link on a subset of this http link.
        if (!hasAlreadyLink)
        {
            if (!linkMatches)
            {
                // Search for the links in the string only once
                // Do not use NSDataDetector with NSTextCheckingTypeLink because is not able to
                // manage URLs with 2 hashes like "https://matrix.to/#/#matrix:matrix.org"
                // Such URL is not valid but web browsers can open them and users C+P them...
                // NSDataDetector does not support it but UITextView and UIDataDetectorTypeLink
                // detect them when they are displayed. So let the UI create the link at display.
                linkMatches = [httpLinksRegex matchesInString:mutableAttributedString.string options:0 range:NSMakeRange(0, mutableAttributedString.length)];
            }
            
            for (NSTextCheckingResult *linkMatch in linkMatches)
            {
                // If the match is fully in the link, skip it
                if (NSIntersectionRange(match.range, linkMatch.range).length == match.range.length)
                {
                    // but before we set the right color
                    [mutableAttributedString addAttribute:NSForegroundColorAttributeName value:ThemeService.shared.theme.colors.links range:linkMatch.range];
                    hasAlreadyLink = YES;
                    break;
                }
            }
        }
        
        if (!hasAlreadyLink)
        {
            // Make the link clickable
            // Caution: We need here to escape the non-ASCII characters (like '#' in room alias)
            // to convert the link into a legal URL string.
            NSString *link = [mutableAttributedString.string substringWithRange:match.range];
            link = [link stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
            [mutableAttributedString addAttribute:NSLinkAttributeName value:link range:match.range];
            [mutableAttributedString addAttribute:NSForegroundColorAttributeName value:ThemeService.shared.theme.colors.links range:match.range];
        }
    }];
}

#pragma mark - HTML processing - blockquote display handling

+ (NSString*)cssToMarkBlockquotes
{
    return [NSString stringWithFormat:@"blockquote {background: #%lX; display: block;}", (unsigned long)[MXKTools rgbValueWithColor:kMXKToolsBlockquoteMarkColor]];
}

+ (void)removeMarkedBlockquotesArtifacts:(NSMutableAttributedString*)mutableAttributedString
{
    // Enumerate all sections marked thanks to `cssToMarkBlockquotes`
    // and apply our own attribute instead.

    // According to blockquotes in the string, DTCoreText can apply 2 policies:
    //     - define a `DTTextBlocksAttribute` attribute on a <blockquote> block
    //     - or, just define a `NSBackgroundColorAttributeName` attribute

    // `DTTextBlocksAttribute` case
    [mutableAttributedString enumerateAttribute:DTTextBlocksAttribute
                                        inRange:NSMakeRange(0, mutableAttributedString.length)
                                        options:0
                                     usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop)
     {
         if ([value isKindOfClass:NSArray.class])
         {
             NSArray *array = (NSArray*)value;
             if (array.count > 0 && [array[0] isKindOfClass:DTTextBlock.class])
             {
                 DTTextBlock *dtTextBlock = (DTTextBlock *)array[0];
                 if ([dtTextBlock.backgroundColor isEqual:kMXKToolsBlockquoteMarkColor])
                 {
                     // Apply our own attribute
                     [mutableAttributedString addAttribute:kMXKToolsBlockquoteMarkAttribute value:@(YES) range:range];

                     // Fix a boring behaviour where DTCoreText add a " " string before a string corresponding
                     // to an HTML blockquote. This " " string has ParagraphStyle.headIndent = 0 which breaks
                     // the blockquote block indentation
                     if (range.location > 0)
                     {
                         NSRange prevRange = NSMakeRange(range.location - 1, 1);

                         NSRange effectiveRange;
                         NSParagraphStyle *paragraphStyle = [mutableAttributedString attribute:NSParagraphStyleAttributeName
                                                                                       atIndex:prevRange.location
                                                                                effectiveRange:&effectiveRange];

                         // Check if this is the " " string
                         if (paragraphStyle && effectiveRange.length == 1 && paragraphStyle.firstLineHeadIndent != 25)
                         {
                             // Fix its paragraph style
                             NSMutableParagraphStyle *newParagraphStyle = [paragraphStyle mutableCopy];
                             newParagraphStyle.firstLineHeadIndent = 25.0;
                             newParagraphStyle.headIndent = 25.0;

                             [mutableAttributedString addAttribute:NSParagraphStyleAttributeName value:newParagraphStyle range:prevRange];
                         }
                     }
                 }
             }
         }
     }];

    // `NSBackgroundColorAttributeName` case
    [mutableAttributedString enumerateAttribute:NSBackgroundColorAttributeName
                                        inRange:NSMakeRange(0, mutableAttributedString.length)
                                        options:0
                                     usingBlock:^(id value, NSRange range, BOOL *stop)
     {

         if ([value isKindOfClass:UIColor.class] && [(UIColor*)value isEqual:[UIColor magentaColor]])
         {
             // Remove the marked background
             [mutableAttributedString removeAttribute:NSBackgroundColorAttributeName range:range];

             // And apply our own attribute
             [mutableAttributedString addAttribute:kMXKToolsBlockquoteMarkAttribute value:@(YES) range:range];
         }
     }];
}

+ (void)enumerateMarkedBlockquotesInAttributedString:(NSAttributedString*)attributedString usingBlock:(void (^)(NSRange range, BOOL *stop))block
{
    [attributedString enumerateAttribute:kMXKToolsBlockquoteMarkAttribute
                                 inRange:NSMakeRange(0, attributedString.length)
                                 options:0
                              usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop)
     {
         if ([value isKindOfClass:NSNumber.class] && ((NSNumber*)value).boolValue)
         {
             block(range, stop);
         }
     }];
}

#pragma mark - Push

// Trim push token before printing it in logs
+ (NSString*)logForPushToken:(NSData*)pushToken
{
    NSUInteger len = ((pushToken.length > 8) ? 8 : pushToken.length / 2);
    return [NSString stringWithFormat:@"%@...", [pushToken subdataWithRange:NSMakeRange(0, len)]];
}

@end
