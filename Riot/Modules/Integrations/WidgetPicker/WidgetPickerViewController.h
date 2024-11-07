/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
