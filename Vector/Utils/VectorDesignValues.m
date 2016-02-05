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
UIColor *kVectorColorLightGrey;
UIColor *kVectorColorSiver;

UIColor *kVectorTextColorBlack;
UIColor *kVectorTextColorGray;

@implementation VectorDesignValues

+ (void)load
{
    [super load];

    // Load colors at the app load time for the life of the app
    kVectorColorGreen = [UIColor colorWithRed:(98.0/256.0) green:(206.0/256.0) blue:(156.0/256.0) alpha:1.0];
    kVectorColorLightGrey = [UIColor colorWithRed:(242.0 / 256.0) green:(242.0 / 256.0) blue:(242.0 / 256.0) alpha:1.0];
    kVectorColorSiver = [UIColor colorWithRed:(199.0 / 256.0) green:(199.0 / 256.0) blue:(204.0 / 256.0) alpha:1.0];

    kVectorTextColorBlack = [UIColor colorWithRed:(60.0 / 256.0) green:(60.0 / 256.0) blue:(60.0 / 256.0) alpha:1.0];
    kVectorTextColorGray = [UIColor colorWithRed:(157.0 / 256.0) green:(157.0 / 256.0) blue:(157.0 / 256.0) alpha:1.0];
}

@end
