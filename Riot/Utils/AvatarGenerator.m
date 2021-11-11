/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "AvatarGenerator.h"

#import "ThemeService.h"

#import "GeneratedInterface-Swift.h"

@implementation AvatarGenerator

static NSMutableDictionary *imageByKeyDict = nil;
static NSArray* colorsList = nil;
static UILabel* backgroundLabel = nil;

/**
 Init the generated avatar colors.
 Should be the same as the webclient.
 */
+ (void)initColorList
{
    if (!colorsList)
    {
        colorsList = ThemeService.shared.theme.avatarColors;
    }
}

/**
 Generate the selected color index in colorsList list.
 */
+ (NSUInteger)colorIndexForText:(NSString*)text
{
    [AvatarGenerator initColorList];
    
    NSUInteger colorIndex = 0;
    
    if (text)
    {
        NSUInteger sum = 0;
        
        for(int i = 0; i < text.length; i++)
        {
            sum += [text characterAtIndex:i];
        }
        
        colorIndex = sum % colorsList.count;
    }
    
    return colorIndex;
}

/**
 Return the first valid character for avatar creation.
 */
+ (NSString *)firstChar:(NSString *)text
{
    if ([text hasPrefix:@"@"] || [text hasPrefix:@"#"] || [text hasPrefix:@"!"] || [text hasPrefix:@"+"])
    {
        text = [text substringFromIndex:1];
    }
    
    // default firstchar
    NSString* firstChar = @" ";
    
    if (text.length > 0)
    {
        firstChar = [[text substringToIndex:NSMaxRange([text rangeOfComposedCharacterSequenceAtIndex:0])] uppercaseString];
    }
    
    return firstChar;
}

+ (UIImage *)imageFromText:(NSString*)text withBackgroundColor:(UIColor*)color
{
    if (!backgroundLabel)
    {
        backgroundLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        backgroundLabel.textColor = ThemeService.shared.theme.backgroundColor;
        backgroundLabel.textAlignment = NSTextAlignmentCenter;
        backgroundLabel.font = [UIFont boldSystemFontOfSize:25];
    }
    
    backgroundLabel.text = text;
    backgroundLabel.backgroundColor = color;
    
    // Create a "canvas" (image context) to draw in.
    UIGraphicsBeginImageContextWithOptions(backgroundLabel.frame.size, NO, 0);
    
    // set to the top quality
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIImage *image;
    if (context)
    {
        CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
        [[backgroundLabel layer] renderInContext: context];
        image = UIGraphicsGetImageFromCurrentImageContext();
    }
    
    UIGraphicsEndImageContext();
    
    // Return the image.
    return image;
}

+ (UIImage *)imageFromText:(NSString*)text withBackgroundColor:(UIColor*)color size:(CGFloat)size andFontSize:(CGFloat)fontSize
{
    UILabel *bgLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, size, size)];
    bgLabel.textColor = ThemeService.shared.theme.backgroundColor;
    bgLabel.textAlignment = NSTextAlignmentCenter;
    bgLabel.font = [UIFont boldSystemFontOfSize:fontSize];
    
    bgLabel.text = text;
    bgLabel.backgroundColor = color;
    
    // Create a "canvas" (image context) to draw in.
    UIGraphicsBeginImageContextWithOptions(bgLabel.frame.size, NO, 0);
    
    // set to the top quality
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIImage *image;
    if (context)
    {
        CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
        [[bgLabel layer] renderInContext: context];
        image = UIGraphicsGetImageFromCurrentImageContext();
    }   
    
    UIGraphicsEndImageContext();
    
    // Return the image.
    return image;
}

/**
 Returns the UIImage for the text and a selected color.
 It checks first if it is not yet cached before generating one.
 */
+ (UIImage*)avatarForText:(NSString*)text andColorIndex:(NSUInteger)colorIndex
{
    NSString* firstChar = [AvatarGenerator firstChar:text];
    
    // the images are cached to avoid create them several times
    // the key is <first upper character><index in the colors array>
    // it should be smaller than using the text as a key
    NSString* key = [NSString stringWithFormat:@"%@%tu", firstChar, colorIndex];
    
    if (!imageByKeyDict)
    {
        imageByKeyDict = [[NSMutableDictionary alloc] init];
    }
    
    UIImage* image = imageByKeyDict[key];
    
    if (!image)
    {
        image = [AvatarGenerator imageFromText:firstChar withBackgroundColor:colorsList[colorIndex]];
        imageByKeyDict[key] = image;
    }
    
    return image;
}

+ (UIImage*)generateAvatarForText:(NSString*)text
{
    return [AvatarGenerator avatarForText:text andColorIndex:[AvatarGenerator colorIndexForText:text]];
}

+ (UIImage*)generateAvatarForMatrixItem:(NSString*)itemId withDisplayName:(NSString*)displayname
{
    return [AvatarGenerator avatarForText:(displayname ? displayname : itemId) andColorIndex:[AvatarGenerator colorIndexForText:itemId]];
}

+ (UIImage*)generateAvatarForMatrixItem:(NSString*)itemId withDisplayName:(NSString*)displayname size:(CGFloat)size andFontSize:(CGFloat)fontSize
{
    NSString* firstChar = [AvatarGenerator firstChar:(displayname ? displayname : itemId)];
    NSUInteger colorIndex = [AvatarGenerator colorIndexForText:itemId];
    
    return [AvatarGenerator imageFromText:firstChar withBackgroundColor:colorsList[colorIndex] size:size andFontSize:fontSize];
}

+ (void)clear
{
    [imageByKeyDict removeAllObjects];
    colorsList = nil;
    backgroundLabel = nil;
}

@end
