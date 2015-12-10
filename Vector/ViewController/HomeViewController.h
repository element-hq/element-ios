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

#import "SegmentedViewController.h"

@class RoomViewController;

/**
 The `HomeViewController` screen is the main app screen.
 */
@interface HomeViewController : SegmentedViewController <MXKRecentListViewControllerDelegate, UISearchBarDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *settingsBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *searchBarButtonIem;

// References on the currently selected room and its view controller
@property (nonatomic, readonly) RoomViewController *currentRoomViewController;
@property (nonatomic, readonly) NSString  *selectedRoomId;
@property (nonatomic, readonly) MXSession *selectedRoomSession;

/**
 Start displaying the screen with a user Matrix session.
 
 @param session the user Matrix session.
 */
- (void)displayWithSession:(MXSession*)session;

/**
 Open the room with the provided identifier in a specific matrix session.

 @param roomId the room identifier.
 @param mxSession the matrix session in which the room should be available.
 */
- (void)selectRoomWithId:(NSString*)roomId inMatrixSession:(MXSession*)mxSession;

/**
 Close the current selected room (if any)
 */
- (void)closeSelectedRoom;

/**
 Action registered on `UIControlEventTouchUpInside` event for both buttons.
 */
- (IBAction)onButtonPressed:(id)sender;

@end
