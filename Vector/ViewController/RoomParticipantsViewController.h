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

#import <MatrixKit/MatrixKit.h>

#import "ContactTableViewCell.h"

#import "SegmentedViewController.h"

/**
 'RoomParticipantsViewController' instance is used to edit members of the room defined by the property 'mxRoom'.
 When this property is nil, the view controller empty.
 */
@interface RoomParticipantsViewController : MXKViewController <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>
{
@protected
    /**
     The matrix id of the current user (nil if the user is not a participant of the room).
     */
    NSString *userMatrixId;
    
    /**
     Section indexes
     */
    NSInteger searchResultSection;
    NSInteger membersSection;
    NSInteger invitedSection;
    
    /**
     The current list of joined members.
     */
    NSMutableArray *actualMembers;
    
    /**
     The current list of invited members.
     */
    NSMutableArray *invitedMembers;
    
    /**
     Store MXKContact instance by matrix user id
     */
    NSMutableDictionary *mxkContactsById;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *searchBarHeader;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBarView;
@property (weak, nonatomic) IBOutlet UIView *searchBarHeaderBorder;

/**
 A matrix room (nil by default).
 */
@property (nonatomic) MXRoom *mxRoom;

/**
 Tell whether a search session is in progress
 */
@property (nonatomic) BOOL isAddParticipantSearchBarEditing;

/**
 The potential segmented view controller in which the view controller is displayed.
 */
@property (nonatomic) SegmentedViewController *segmentedViewController;

@end

