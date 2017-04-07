/*
 Copyright 2015 OpenMarket Ltd
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

#import <MatrixKit/MatrixKit.h>

@interface RecentsViewController : MXKRecentListViewController <MXKRecentListViewControllerDelegate, UIGestureRecognizerDelegate>
{
@protected
    /**
     The image view of the room creation button.
     */
    UIImageView* createNewRoomImageView;
    
    /**
     Current alert (if any).
     */
    MXKAlert *currentAlert;
}

/**
 If YES, the table view will scroll at the top on the next data source refresh.
 It comes back to NO after each refresh.
 */
@property (nonatomic) BOOL shouldScrollToTopOnRefresh;

/**
 The Google Analytics Instance screen name (Default is "RecentsScreen").
 */
@property (nonatomic) NSString *screenName;

/**
 Refresh the cell selection in the table.

 This must be done accordingly to the currently selected room in the master tabbar of the application.

 @param forceVisible if YES and if the corresponding cell is not visible, scroll the table view to make it visible.
 */
- (void)refreshCurrentSelectedCell:(BOOL)forceVisible;


#pragma mark - Room creation
/**
 Add a Room creation button at the right bottom corner of the view.
 */
- (void)addRoomCreationButton;

/**
 Action triggered when the user taps on the Room creation button.
 Create an empty room by default.
 */
- (void)onRoomCreationButtonPressed;

/**
 Create an empty room.
 */
- (void)createAnEmptyRoom;

@end

