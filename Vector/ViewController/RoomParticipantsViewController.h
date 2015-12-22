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

/**
 'RoomParticipantsViewController' instance is used to edit members of the room defined by the property 'mxRoom'.
 
 When this property is nil, the view controller is able to handle a list of participants without room reference (see inherited class 'RoomCreationStep2ViewController').
 */
@interface RoomParticipantsViewController : MXKTableViewController <UISearchBarDelegate>
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
    NSInteger participantsSection;
    
    /**
     Mutable list of participants
     */
    NSMutableArray *mutableParticipants;
    
    /**
     Store MXKContact instance by matrix user id
     */
    NSMutableDictionary *mxkContactsById;
}

/**
 A matrix room (nil by default).
 */
@property (nonatomic) MXRoom *mxRoom;

/**
 Tell whether a search session is in progress
 */
@property (nonatomic) BOOL isAddParticipantSearchBarEditing;


/**
 Customize the UITableViewCell before rendering it.
 
 @param contactCell the cell to customize.
 @param indexPath path of the cell in the tableview.
 */
- (void)customizeContactCell:(ContactTableViewCell*)contactCell atIndexPath:(NSIndexPath *)indexPath;

@end

