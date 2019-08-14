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

#import "ContactsTableViewController.h"

/**
 'StartChatViewController' instance is used to prepare new room creation.
 */
@interface StartChatViewController : ContactsTableViewController

/**
 Tell whether a search session is in progress
 */
@property (nonatomic) BOOL isAddParticipantSearchBarEditing;

/**
 Returns the `UINib` object initialized for a `StartChatViewController`.
 
 @return The initialized `UINib` object or `nil` if there were errors during initialization
 or the nib file could not be located.
 */
+ (UINib *)nib;

/**
 Creates and returns a new `StartChatViewController` object.
 
 @discussion This is the designated initializer for programmatic instantiation.
 @return An initialized `StartChatViewController` object if successful, `nil` otherwise.
 */
+ (instancetype)startChatViewController;

@end

