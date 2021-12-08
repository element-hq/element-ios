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

#import "RecentsDataSource.h"

/**
 'UnifiedSearchRecentsDataSource' class inherits from 'RecentsDataSource' to define the Riot recents source
 used during the unified search on rooms.
 */
@interface UnifiedSearchRecentsDataSource : RecentsDataSource

#pragma mark - Directory handling

/**
 Hide recents. NO by default.
 */
@property (nonatomic) BOOL hideRecents;

@end
