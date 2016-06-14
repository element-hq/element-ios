/*
 Copyright 2015 OpenMarket Ltd
 
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

#import "VectorDesignValues.h"

@implementation AvatarGenerator

static NSMutableDictionary *imageByKeyDict = nil;
static NSMutableArray* colorsList = nil;
static UILabel* backgroundLabel = nil;

/**
 Init the generated avatar colors.
 Should be the same as the webclient.
 */
+ (void)initColorList
{
    if (!colorsList)
    {
        colorsList = [[NSMutableArray alloc] init];
        [colorsList addObject:kVectorColorGreen];
        [colorsList addObject:kVectorColorLightGreen];
        [colorsList addObject:kVectorColorOrange];
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
 Create an UIImage with the text and the background color.
 */
+ (UIImage *)imageFromText:(NSString*)text withBackgroundColor:(UIColor*)color
{
    if (!backgroundLabel)
    {
        backgroundLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        backgroundLabel.textColor = [UIColor whiteColor];
        backgroundLabel.textAlignment = NSTextAlignmentCenter;
        backgroundLabel.font = [UIFont boldSystemFontOfSize:25];
    }
    
    backgroundLabel.text = text;
    backgroundLabel.backgroundColor = color;
    
    // Create a "canvas" (image context) to draw in.
    UIGraphicsBeginImageContextWithOptions(backgroundLabel.frame.size, NO, 0);
    
    // set to the top quality
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    [[backgroundLabel layer] renderInContext: UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // Return the image.
    return image;
}

/**
 Returns the UIImage for the text and a selected color.
 It checks first if it is not yet cached before generating one.
 */
+ (UIImage*)avatarForText:(NSString*)aText andColorIndex:(NSUInteger)colorIndex
{
    if ([aText hasPrefix:@"@"] || [aText hasPrefix:@"#"] || [aText hasPrefix:@"!"])
    {
        aText = [aText substringFromIndex:1];
    }

    // default firstchar
    NSString* firstChar = @" ";
    
    if (aText.length > 0)
    {
        firstChar = [[aText substringToIndex:1] uppercaseString];
    }
    
    // the images are cached to avoid create them several times
    // the key is <first upper character><index in the colors array>
    // it should be smaller than using the text as a key
    NSString* key = [NSString stringWithFormat:@"%@%tu", firstChar, colorIndex];
    
    if (!imageByKeyDict)
    {
        imageByKeyDict = [[NSMutableDictionary alloc] init];
    }
    
    UIImage* image = [imageByKeyDict objectForKey:key];
    
    if (!image)
    {
        image = [AvatarGenerator imageFromText:firstChar withBackgroundColor:[colorsList objectAtIndex:colorIndex]];
        [imageByKeyDict setObject:image forKey:key];
    }
    
    return image;
}

+ (UIImage*)generateAvatarForText:(NSString*)text
{
    return [AvatarGenerator avatarForText:text andColorIndex:[AvatarGenerator colorIndexForText:text]];
}

+ (UIImage*)generateRoomMemberAvatar:(NSString*)userId displayName:(NSString*)displayname
{
    // the selected color is based on the userId
    NSUInteger index = [AvatarGenerator colorIndexForText:userId];
    NSString* text = displayname ? displayname : userId;
    
    return [AvatarGenerator avatarForText:text andColorIndex:index];
}

+ (UIImage*)generateRoomAvatar:(NSString*)roomId andDisplayName:(NSString*)displayName
{
    return [AvatarGenerator avatarForText:displayName andColorIndex:[AvatarGenerator colorIndexForText:roomId]];
}

@end
