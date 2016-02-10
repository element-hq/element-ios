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

#import <MatrixKit/MatrixKit.h>

/**
 Convert a RGB hexadecimal value into a UIColor.
 */
#define UIColorFromRGB(rgbValue) \
    [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
                    green:((float)((rgbValue & 0x00FF00) >>  8))/255.0 \
                     blue:((float)((rgbValue & 0x0000FF) >>  0))/255.0 \
                    alpha:1.0]

#pragma mark - Vector Colors
extern UIColor *kVectorColorGreen;
extern UIColor *kVectorColorLightGreen;
extern UIColor *kVectorColorLightGrey;
extern UIColor *kVectorColorSiver;
extern UIColor *kVectorColorOrange;

#pragma mark - Vector Text Colors
extern UIColor *kVectorTextColorBlack;
extern UIColor *kVectorTextColorDarkGray;
extern UIColor *kVectorTextColorGray;

/**
 `VectorDesignValues` class manages the Vector design parameters
 */
@interface VectorDesignValues : NSObject

// to update the navigation bar buttons color
// [[AppDelegate theDelegate] recentsNavigationController].navigationBar.tintColor = [UIColor greenColor];

@end
