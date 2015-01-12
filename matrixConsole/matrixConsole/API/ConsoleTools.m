/*
 Copyright 2014 OpenMarket Ltd
 
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

#import "ConsoleTools.h"

@implementation ConsoleTools

#pragma mark - Time interval

+ (NSString*)formatSecondsInterval:(CGFloat)secondsInterval {
    NSMutableString* formattedString = [[NSMutableString alloc] init];
    
    if (secondsInterval < 1) {
        [formattedString appendString:@"< 1s"];
    } else if (secondsInterval < 60)
    {
        [formattedString appendFormat:@"%ds", (int)secondsInterval];
    }
    else if (secondsInterval < 3600)
    {
        [formattedString appendFormat:@"%dm %2ds", (int)(secondsInterval/60), ((int)secondsInterval) % 60];
    }
    else if (secondsInterval >= 3600)
    {
        [formattedString appendFormat:@"%dh %dm %ds", (int)(secondsInterval / 3600),
         ((int)(secondsInterval) % 3600) / 60,
         (int)(secondsInterval) % 60];
    }
    [formattedString appendString:@" left"];
    
    return formattedString;
}

#pragma mark - Image

+ (UIImage *)resize:(UIImage *)image toFitInSize:(CGSize)size {
    UIImage *resizedImage = image;
    
    // Check whether resize is required
    if (size.width && size.height) {
        CGFloat width = image.size.width;
        CGFloat height = image.size.height;
        
        if (width > size.width) {
            height = (height * size.width) / width;
            height = floorf(height / 2) * 2;
            width = size.width;
        }
        if (height > size.height) {
            width = (width * size.height) / height;
            width = floorf(width / 2) * 2;
            height = size.height;
        }
        
        if (width != image.size.width || height != image.size.height) {
            // Create the thumbnail
            CGSize imageSize = CGSizeMake(width, height);
            UIGraphicsBeginImageContext(imageSize);
            
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
    
    return resizedImage;
}

@end
