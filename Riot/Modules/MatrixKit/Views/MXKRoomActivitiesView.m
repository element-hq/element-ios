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

#import "MXKRoomActivitiesView.h"

@implementation MXKRoomActivitiesView

+ (UINib *)nib
{
    // No 'MXKRoomActivitiesView.xib' has been defined yet
    return nil;
}

+ (instancetype)roomActivitiesView
{
    id instance = nil;
    
    if ([[self class] nib])
    {
        @try {
           instance = [[[self class] nib] instantiateWithOwner:nil options:nil].firstObject;
        }
        @catch (NSException *exception) {
        }
    }
    
    if (!instance)
    {
        instance = [[self alloc] initWithFrame:CGRectZero];
    }
 
    return instance;
}

- (void)destroy
{
    _delegate = nil;
}

- (CGFloat)height
{
    return self.frame.size.height;
}

@end
