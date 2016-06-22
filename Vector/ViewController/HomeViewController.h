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

#import "ContactPickerViewController.h"

#import "RoomViewController.h"
#import "AuthenticationViewController.h"

/**
 The `HomeViewController` screen is the main app screen.
 */
@interface HomeViewController : SegmentedViewController <MXKRecentListViewControllerDelegate, UISearchBarDelegate, UIGestureRecognizerDelegate, ContactPickerViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *settingsBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *searchBarButtonIem;

// References on the currently selected room and its view controller
@property (nonatomic, readonly) RoomViewController *currentRoomViewController;
@property (nonatomic, readonly) NSString  *selectedRoomId;
@property (nonatomic, readonly) NSString  *selectedEventId;
@property (nonatomic, readonly) MXSession *selectedRoomSession;
@property (nonatomic, readonly) RoomPreviewData *selectedRoomPreviewData;

// Reference to the current auth VC. It is not nil only when the auth screen is displayed.
@property (nonatomic, readonly) AuthenticationViewController *authViewController;

/**
 Display the authentication screen.
 */
- (void)showAuthenticationScreen;

/**
 Display the authentication screen in order to pursue a registration process by using a predefined set
 of parameters.
 
 If the provided registration parameters are not supported, we switch back to the default login screen.

 @param parameters the set of parameters.
 */
- (void)showAuthenticationScreenWithRegistrationParameters:(NSDictionary*)parameters;

/**
 Open the room with the provided identifier in a specific matrix session.

 @param roomId the room identifier.
 @param eventId if not nil, the room will be opened on this event.
 @param mxSession the matrix session in which the room should be available.
 */
- (void)selectRoomWithId:(NSString*)roomId andEventId:(NSString*)eventId inMatrixSession:(MXSession*)mxSession;

/**
 Open the RoomViewController to display the preview of a room that is unknown for the user.

 This room can come from an email invitation link or a simple link to a room.

 @param roomPreviewData the data for the room preview.
 */
- (void)showRoomPreview:(RoomPreviewData*)roomPreviewData;

/**
 Close the current selected room (if any)
 */
- (void)closeSelectedRoom;

/**
 Open the public rooms directory page.
 It uses the `publicRoomsDirectoryDataSource` managed by the recents view controller data source
 */
- (void)showPublicRoomsDirectory;

/**
 Action registered on `UIControlEventTouchUpInside` event for both buttons.
 */
- (IBAction)onButtonPressed:(id)sender;

@end
