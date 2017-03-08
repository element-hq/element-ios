/*
 Copyright 2016 OpenMarket Ltd
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

#import "RiotDesignValues.h"

UIColor *kRiotColorGreen;
UIColor *kRiotColorLightGreen;
UIColor *kRiotColorLightGrey;
UIColor *kRiotColorSilver;
UIColor *kRiotColorOrange;
UIColor *kRiotColorPinkRed;
UIColor *kRiotColorRed;

UIColor *kRiotTextColorBlack;
UIColor *kRiotTextColorDarkGray;
UIColor *kRiotTextColorGray;

UIColor *kRiotNavBarTintColor;

NSInteger const kRiotRoomModeratorLevel = 50;
NSInteger const kRiotRoomAdminLevel = 100;

@implementation RiotDesignValues

+ (void)load
{
    [super load];

    // Load colors at the app load time for the life of the app

    // Colors as defined by the design
    kRiotColorGreen = [UIColor colorWithRed:(98.0/255.0) green:(206.0/255.0) blue:(156.0/255.0) alpha:1.0];
    kRiotColorLightGrey = [UIColor colorWithRed:(242.0 / 255.0) green:(242.0 / 255.0) blue:(242.0 / 255.0) alpha:1.0];
    kRiotColorSilver = [UIColor colorWithRed:(199.0 / 255.0) green:(199.0 / 255.0) blue:(204.0 / 255.0) alpha:1.0];
    kRiotColorPinkRed = [UIColor colorWithRed:(255.0 / 255.0) green:(0.0 / 255.0) blue:(100.0 / 255.0) alpha:1.0];
    kRiotColorRed = UIColorFromRGB(0xFF4444);

    kRiotTextColorBlack = [UIColor colorWithRed:(60.0 / 255.0) green:(60.0 / 255.0) blue:(60.0 / 255.0) alpha:1.0];
    kRiotTextColorDarkGray = [UIColor colorWithRed:(74.0 / 255.0) green:(74.0 / 255.0) blue:(74.0 / 255.0) alpha:1.0];
    kRiotTextColorGray = [UIColor colorWithRed:(157.0 / 255.0) green:(157.0 / 255.0) blue:(157.0 / 255.0) alpha:1.0];
    
    kRiotNavBarTintColor = kRiotColorLightGrey;

    // Colors copied from Vector web
    kRiotColorLightGreen = UIColorFromRGB(0x50e2c2);
    kRiotColorOrange = UIColorFromRGB(0xf4c371);
}

@end
