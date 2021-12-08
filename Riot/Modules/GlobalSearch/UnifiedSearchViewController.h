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

#import "SegmentedViewController.h"

#import "ContactsTableViewController.h"

/**
 The `UnifiedSearchViewController` screen is the global search screen.
 */
@interface UnifiedSearchViewController : SegmentedViewController <UIGestureRecognizerDelegate, ContactsTableViewControllerDelegate>

+ (instancetype)instantiate;

/**
 Open the public rooms directory page.
 It uses the `publicRoomsDirectoryDataSource` managed by the recents view controller data source
 */
- (void)showPublicRoomsDirectory;

/**
 Tell whether an event has been selected from messages or files search tab.
 */
@property (nonatomic, readonly) MXEvent *selectedSearchEvent;
@property (nonatomic, readonly) MXSession *selectedSearchEventSession;

@end
