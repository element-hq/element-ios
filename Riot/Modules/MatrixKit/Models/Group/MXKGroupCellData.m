/*
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

#import "MXKGroupCellData.h"

#import "MXKSessionGroupsDataSource.h"

@implementation MXKGroupCellData
@synthesize group, groupsDataSource, groupDisplayname, sortingDisplayname;

- (instancetype)initWithGroup:(MXGroup*)theGroup andGroupsDataSource:(MXKSessionGroupsDataSource*)theGroupsDataSource
{
    self = [self init];
    if (self)
    {
        groupsDataSource = theGroupsDataSource;
        [self updateWithGroup:theGroup];
    }
    return self;
}

- (void)updateWithGroup:(MXGroup*)theGroup
{
    group = theGroup;
    
    groupDisplayname = sortingDisplayname = group.profile.name;
    
    if (!groupDisplayname.length)
    {
        groupDisplayname = group.groupId;
        // Ignore the prefix '+' of the group id during sorting.
        sortingDisplayname = [groupDisplayname substringFromIndex:1];
    }
}

@end
