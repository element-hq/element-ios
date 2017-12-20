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

#import "ContactsTableViewController.h"

@class Contact;

/**
 'GroupParticipantsViewController' instance is used to list members of the group defined by the property 'mxGroup'.
 When this property is nil, the view controller is empty.
 */
@interface GroupParticipantsViewController : MXKViewController <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UIGestureRecognizerDelegate, ContactsTableViewControllerDelegate>
{
@protected
    /**
     Section indexes
     */
    NSInteger participantsSection;
    NSInteger invitedSection;
    
    /**
     The current list of joined members.
     */
    NSMutableArray<Contact*> *actualParticipants;
    
    /**
     The current list of invited members.
     */
    NSMutableArray<Contact*> *invitedParticipants;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *searchBarHeader;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBarView;
@property (weak, nonatomic) IBOutlet UIView *searchBarHeaderBorder;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchBarTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewBottomConstraint;

/**
 A matrix group (nil by default).
 */
@property (strong, readonly, nonatomic) MXGroup *group;
@property (strong, readonly, nonatomic) MXSession *mxSession;

/**
 Returns the `UINib` object initialized for a `GroupParticipantsViewController`.
 
 @return The initialized `UINib` object or `nil` if there were errors during initialization
 or the nib file could not be located.
 */
+ (UINib *)nib;

/**
 Creates and returns a new `GroupParticipantsViewController` object.
 
 @discussion This is the designated initializer for programmatic instantiation.
 @return An initialized `GroupParticipantsViewController` object if successful, `nil` otherwise.
 */
+ (instancetype)groupParticipantsViewController;

/**
 Set the group for which the details are displayed.
 Provide the related matrix session.
 
 @param group
 @param mxSession
 */
- (void)setGroup:(MXGroup*)group withMatrixSession:(MXSession*)mxSession;

@end

