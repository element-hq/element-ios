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

#import "VectorDesignValues.h"

@implementation VectorDesignValues

static NSMutableDictionary* backgroundByImageNameDict;

+ (UIColor*)getBackgroundColor:(NSString*)imageName
{
    UIColor* backgroundColor = VECTOR_LIGHT_GRAY_COLOR;
    
    if (!imageName)
    {
        return backgroundColor;
    }
    
    if (!backgroundByImageNameDict)
    {
        backgroundByImageNameDict = [[NSMutableDictionary alloc] init];
    }
    
    UIColor* bgColor = [backgroundByImageNameDict objectForKey:imageName];
    
    if (!bgColor)
    {
        CGFloat backgroundSide = 74.0;
        CGFloat sourceSide = 30.0;
        
        UIImageView* backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, backgroundSide, backgroundSide)];
        backgroundView.backgroundColor = backgroundColor;
        
        CGFloat offset = (backgroundSide - sourceSide) / 2.0f;
        
        UIImageView* resourceImageView = [[UIImageView alloc] initWithFrame:CGRectMake(offset, offset, sourceSide, sourceSide)];
        resourceImageView.backgroundColor = [UIColor clearColor];
        resourceImageView.image = [MXKTools resizeImage:[UIImage imageNamed:imageName] toSize:CGSizeMake(sourceSide, sourceSide)];
        
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
        [backgroundByImageNameDict setObject:bgColor forKey:imageName];
    }
    
    return bgColor;
}


@end
