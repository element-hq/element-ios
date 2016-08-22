/*
 Copyright 2016 OpenMarket Ltd
 
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

#import "MediaPickerViewController.h"
#import "TableViewCellWithCheckBoxes.h"

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

@interface RoomSettingsViewController : MXKRoomSettingsViewController <UITextViewDelegate, UITextFieldDelegate, MediaPickerViewControllerDelegate, MXKRoomMemberDetailsViewControllerDelegate, TableViewCellWithCheckBoxesDelegate>

/**
 Select a settings field in order to edit it ('RoomSettingsViewControllerFieldNone' by default).
 */
@property (nonatomic) RoomSettingsViewControllerField selectedRoomSettingsField;

@end

