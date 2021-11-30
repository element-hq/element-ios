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

#import <UIKit/UIKit.h>

#import <MatrixSDK/MatrixSDK.h>
#import "MatrixKit.h"

/**
 `WidgetPickerViewController` displays the list of widgets within a room plus a
 way to open the integration manager for this room.

 TODO: The feature is still in dev. WidgetPickerViewController` is not yet a pure
 UIViewController.
 As there is no specified design, the list is displayed in a simple UIAlertController.
 It would be nice if this picker could directly:
     - Remove a widget
     - Launch the integration manager to edit a widget
     - Automatically updates on widgets change
 */
@interface WidgetPickerViewController : NSObject

/**
 The UIAlertController instance which handles the dialog.
 */
@property (nonatomic, readonly) UIAlertController *alertController;

/**
 Create the `WidgetPickerViewController` instance.

 @param mxSession the session to use.
 @param roomId the room where to list available widgets.
 */
- (instancetype)initForMXSession:(MXSession*)mxSession inRoom:(NSString*)roomId;

/**
 Show the dialog in a given view controller.

 @param mxkViewController the mxkViewController where to show the dialog.
 */
- (void)showInViewController:(MXKViewController*)mxkViewController;

@end
