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

#import "RecentsDataSource.h"

#import "RecentTableViewCell.h"

#import "EventFormatter.h"

@implementation RecentsDataSource

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        // Reset default view classes
        [self registerCellViewClass:RecentTableViewCell.class forCellIdentifier:kMXKRecentCellIdentifier];
        
        // Replace event formatter
        self.eventFormatter = [[EventFormatter alloc] initWithMatrixSession:self.mxSession];
    }
    return self;
}

#pragma mark - Override MXKDataSource

- (void)destroy
{
    [super destroy];
}

@end
