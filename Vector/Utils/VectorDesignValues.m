/*
 Copyright 2016 OpenMarket Ltd

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

UIColor *kVectorColorGreen;
UIColor *kVectorColorLightGreen;
UIColor *kVectorColorLightGrey;
UIColor *kVectorColorSiver;
UIColor *kVectorColorOrange;

UIColor *kVectorTextColorBlack;
UIColor *kVectorTextColorDarkGray;
UIColor *kVectorTextColorGray;

@implementation VectorDesignValues

+ (void)load
{
    [super load];

    // Load colors at the app load time for the life of the app

    // Colors as defined by the design
    kVectorColorGreen = [UIColor colorWithRed:(98.0/255.0) green:(206.0/255.0) blue:(156.0/255.0) alpha:1.0];
    kVectorColorLightGrey = [UIColor colorWithRed:(242.0 / 255.0) green:(242.0 / 255.0) blue:(242.0 / 255.0) alpha:1.0];
    kVectorColorSiver = [UIColor colorWithRed:(199.0 / 255.0) green:(199.0 / 255.0) blue:(204.0 / 255.0) alpha:1.0];

    kVectorTextColorBlack = [UIColor colorWithRed:(60.0 / 255.0) green:(60.0 / 255.0) blue:(60.0 / 255.0) alpha:1.0];
    kVectorTextColorDarkGray = [UIColor colorWithRed:(74.0 / 255.0) green:(74.0 / 255.0) blue:(74.0 / 255.0) alpha:1.0];
    kVectorTextColorGray = [UIColor colorWithRed:(157.0 / 255.0) green:(157.0 / 255.0) blue:(157.0 / 255.0) alpha:1.0];

    // Colors copied from Vector web
    kVectorColorLightGreen = UIColorFromRGB(0x50e2c2);
    kVectorColorOrange = UIColorFromRGB(0xf4c371);
}

@end
