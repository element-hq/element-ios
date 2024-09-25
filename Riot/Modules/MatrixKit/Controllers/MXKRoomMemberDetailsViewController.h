/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <UIKit/UIKit.h>

#import "MXKViewController.h"
#import "MXKImageView.h"

/**
 Available actions on room member
 */
typedef enum : NSUInteger
{
    MXKRoomMemberDetailsActionInvite,
    MXKRoomMemberDetailsActionLeave,
    MXKRoomMemberDetailsActionKick,
    MXKRoomMemberDetailsActionBan,
    MXKRoomMemberDetailsActionUnban,
    MXKRoomMemberDetailsActionIgnore,
    MXKRoomMemberDetailsActionUnignore,
    MXKRoomMemberDetailsActionSetDefaultPowerLevel,
    MXKRoomMemberDetailsActionSetModerator,
    MXKRoomMemberDetailsActionSetAdmin,
    MXKRoomMemberDetailsActionSetCustomPowerLevel,
    MXKRoomMemberDetailsActionStartChat,
    MXKRoomMemberDetailsActionStartVoiceCall,
    MXKRoomMemberDetailsActionStartVideoCall,
    MXKRoomMemberDetailsActionMention,
    MXKRoomMemberDetailsActionSecurity,
    MXKRoomMemberDetailsActionSecurityInformation
    
} MXKRoomMemberDetailsAction;

@class MXKRoomMemberDetailsViewController;

/**
 `MXKRoomMemberDetailsViewController` delegate.
 */
@protocol MXKRoomMemberDetailsViewControllerDelegate <NSObject>

/**
 Tells the delegate that the user wants to start a one-to-one chat with the room member.
 
 @param roomMemberDetailsViewController the `MXKRoomMemberDetailsViewController` instance.
 @param matrixId the member's matrix id
 @param completion the block to execute at the end of the operation (independently if it succeeded or not).
 */
- (void)roomMemberDetailsViewController:(MXKRoomMemberDetailsViewController *)roomMemberDetailsViewController startChatWithMemberId:(NSString*)matrixId completion:(void (^)(void))completion;

@optional
/**
 Tells the delegate that the user wants to mention the room member.
 
 @discussion the `MXKRoomMemberDetailsViewController` instance is withdrawn automatically.
 
 @param roomMemberDetailsViewController the `MXKRoomMemberDetailsViewController` instance.
 @param member the room member to mention.
 */
- (void)roomMemberDetailsViewController:(MXKRoomMemberDetailsViewController *)roomMemberDetailsViewController mention:(MXRoomMember*)member;

/**
 Tells the delegate that the user wants to place a voip call with the room member.
 
 @param roomMemberDetailsViewController the `MXKRoomMemberDetailsViewController` instance.
 @param matrixId the member's matrix id
 @param isVideoCall the type of the call: YES for video call / NO for voice call.
 */
- (void)roomMemberDetailsViewController:(MXKRoomMemberDetailsViewController *)roomMemberDetailsViewController placeVoipCallWithMemberId:(NSString*)matrixId andVideo:(BOOL)isVideoCall;

@end

/**
 Whereas the main item of this view controller is a table view, the 'MXKRoomMemberDetailsViewController' class inherits
 from 'MXKViewController' instead of 'MXKTableViewController' in order to ease the customization.
 Indeed some items like header may be added at the same level than the table.
 */
@interface MXKRoomMemberDetailsViewController : MXKViewController <UITableViewDelegate, UITableViewDataSource>
{
@protected
    /**
     Current alert (if any).
     */
    UIAlertController *currentAlert;
    
    /**
     List of the allowed actions on this member.
     */
    NSMutableArray<NSNumber*> *actionsArray;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet MXKImageView *memberThumbnail;
@property (weak, nonatomic) IBOutlet UITextView *roomMemberMatrixInfo;

/**
 The default account picture displayed when no picture is defined.
 */
@property (nonatomic) UIImage *picturePlaceholder;

/**
 The displayed member and the corresponding room
 */
@property (nonatomic, readonly) MXRoomMember *mxRoomMember;
@property (nonatomic, readonly) MXRoom *mxRoom;
@property (nonatomic, readonly) id<MXEventTimeline> mxRoomLiveTimeline;

/**
 Enable mention option. NO by default
 */
@property (nonatomic) BOOL enableMention;

/**
 Enable voip call (voice/video). NO by default
 */
@property (nonatomic) BOOL enableVoipCall;

/**
 Enable leave this room. YES by default
 */
@property (nonatomic) BOOL enableLeave;

/**
 Tell whether an action is already in progress.
 */
@property (nonatomic, readonly) BOOL hasPendingAction;

/**
 The delegate for the view controller.
 */
@property (nonatomic, weak) id<MXKRoomMemberDetailsViewControllerDelegate> delegate;

#pragma mark - Class methods

/**
 Returns the `UINib` object initialized for a `MXKRoomMemberDetailsViewController`.
 
 @return The initialized `UINib` object or `nil` if there were errors during initialization
 or the nib file could not be located.
 
 @discussion You may override this method to provide a customized nib. If you do,
 you should also override `roomMemberDetailsViewController` to return your
 view controller loaded from your custom nib.
 */
+ (UINib *)nib;

/**
 Creates and returns a new `MXKRoomMemberDetailsViewController` object.
 
 @discussion This is the designated initializer for programmatic instantiation.
 @return An initialized `MXKRoomMemberDetailsViewController` object if successful, `nil` otherwise.
 */
+ (instancetype)roomMemberDetailsViewController;

/**
 Set the room member to display. Provide the actual room in order to handle member changes.
 
 @param roomMember the matrix room member
 @param room the matrix room to which this member belongs.
 */
- (void)displayRoomMember:(MXRoomMember*)roomMember withMatrixRoom:(MXRoom*)room;

/**
 Refresh the member information.
 */
- (void)updateMemberInfo;

/**
 The following method is registered on `UIControlEventTouchUpInside` event for all displayed action buttons.
 
 The start chat and mention options are transferred to the delegate.
 All the other actions are handled by the current implementation.
 
 If the delegate responds to selector: @selector(roomMemberDetailsViewController:placeVoipCallWithMemberId:andVideo:), the voip options
 are transferred to the delegate.
 */
- (IBAction)onActionButtonPressed:(id)sender;

/**
 Set the power level of the room member
 
 @param value the value to set.
 @param promptUser prompt the user if they ops a member with the same power level.
 */
- (void)setPowerLevel:(NSInteger)value promptUser:(BOOL)promptUser;

/**
 Add a mask in overlay to prevent a new contact selection (used when an action is on progress).
 */
- (void)addPendingActionMask;

/**
 Remove the potential overlay mask
 */
- (void)removePendingActionMask;

@end

