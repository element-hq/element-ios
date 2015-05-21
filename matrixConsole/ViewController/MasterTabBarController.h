/*
 Copyright 2014 OpenMarket Ltd
 
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

#import <UIKit/UIKit.h>

#import <MatrixKit/MatrixKit.h>

#define TABBAR_HOME_INDEX      0
#define TABBAR_RECENTS_INDEX   1
#define TABBAR_CONTACTS_INDEX  2
#define TABBAR_SETTINGS_INDEX  3
#define TABBAR_COUNT           4

@interface MasterTabBarController : UITabBarController

// Associated matrix sessions (empty by default).
@property (nonatomic, readonly) NSArray *mxSessions;

// Current selected room id. nil if no room is presently visible.
@property (strong, nonatomic) NSString *visibleRoomId;

// Add a matrix session. This session is propagated to all view controllers handled by the tab bar controller.
- (void)addMatrixSession:(MXSession*)mxSession;
// Remove a matrix session.
- (void)removeMatrixSession:(MXSession*)mxSession;

- (void)showAuthenticationScreen;
- (void)showRoomCreationForm;
- (void)showRoom:(NSString*)roomId;

- (void)popRoomViewControllerAnimated:(BOOL)animated;

- (BOOL)isPresentingMediaPicker;
- (void)presentMediaPicker:(UIImagePickerController*)mediaPicker;
- (void)dismissMediaPicker;





@end

