/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <MatrixSDK/MatrixSDK.h>

#import "MXKTableViewController.h"

/**
 This view controller displays the room settings.
 */
@interface MXKRoomSettingsViewController : MXKTableViewController
{
@protected
    // the dedicated room
    MXRoom* mxRoom;
    
    // the room state
    MXRoomState* mxRoomState;
}

/**
 The dedicated roomId.
 */
@property (nonatomic, readonly) NSString *roomId;


#pragma mark - Class methods

/**
 Returns the `UINib` object initialized for a `MXKRoomSettingsViewController`.
 
 @return The initialized `UINib` object or `nil` if there were errors during initialization
 or the nib file could not be located.
 
 @discussion You may override this method to provide a customized nib. If you do,
 you should also override `roomViewController` to return your
 view controller loaded from your custom nib.
 */
+ (UINib *)nib;

/**
 Creates and returns a new `MXKRoomSettingsViewController` object.
 
 @discussion This is the designated initializer for programmatic instantiation.
 @return An initialized `MXKRoomSettingsViewController` object if successful, `nil` otherwise.
 */
+ (instancetype)roomSettingsViewController;

/**
 Set the dedicated session and the room Id
 */
- (void)initWithSession:(MXSession*)session andRoomId:(NSString*)roomId;

/**
 Refresh the displayed room settings. By default this method reload the table view.
 
 @discusion You may override this method to handle the table refresh.
 */
- (void)refreshRoomSettings;

/**
 Updates the display with a new room state.
 
 @param newRoomState the new room state.
 */
- (void)updateRoomState:(MXRoomState*)newRoomState;

@end
