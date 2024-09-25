/*
Copyright 2024 New Vector Ltd.
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"

#import "MediaPickerViewController.h"
#import "TableViewCellWithCheckBoxes.h"

@class AnalyticsScreenTracker;
@protocol RoomSettingsViewControllerDelegate;

/**
 List the settings fields. Used to preselect/edit a field
 */
typedef enum : NSUInteger {
    /**
     Default.
     */
    RoomSettingsViewControllerFieldNone,
    
    /**
     The room name.
     */
    RoomSettingsViewControllerFieldName,
    
    /**
     The room topic.
     */
    RoomSettingsViewControllerFieldTopic,
    
    /**
     The room avatar.
     */
    RoomSettingsViewControllerFieldAvatar
    
} RoomSettingsViewControllerField;

@interface RoomSettingsViewController : MXKRoomSettingsViewController <UITextViewDelegate, UITextFieldDelegate, MXKRoomMemberDetailsViewControllerDelegate, TableViewCellWithCheckBoxesDelegate>

/**
 Select a settings field in order to edit it ('RoomSettingsViewControllerFieldNone' by default).
 */
@property (nonatomic) RoomSettingsViewControllerField selectedRoomSettingsField;

/**
 The screen timer used for analytics if they've been enabled. The default value is nil.
 */
@property (nonatomic) AnalyticsScreenTracker *screenTracker;

/**
 ID of the currently selected space. `nil` if home
 */
@property (nonatomic, nullable) NSString *parentSpaceId;

/**
 Delegate of this view controller.
 */
@property (nonatomic, weak) id<RoomSettingsViewControllerDelegate> delegate;

@end

@protocol RoomSettingsViewControllerDelegate <NSObject>

- (void)roomSettingsViewControllerDidLeaveRoom:(RoomSettingsViewController *)controller;

- (void)roomSettingsViewController:(RoomSettingsViewController *)controller didReplaceRoomWithReplacementId:(NSString *)newRoomId;

- (void)roomSettingsViewControllerDidCancel:(RoomSettingsViewController *)controller;

- (void)roomSettingsViewControllerDidComplete:(RoomSettingsViewController *)controller;

@end
