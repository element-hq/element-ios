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

#import <MatrixSDK/MatrixSDK.h>

#import "MXKView.h"

@class MXKRoomTitleView;
@protocol MXKRoomTitleViewDelegate <NSObject>

/**
 Tells the delegate that an alert must be presented.
 
 @param titleView the room title view.
 @param alertController the alert to present.
 */
- (void)roomTitleView:(MXKRoomTitleView*)titleView presentAlertController:(UIAlertController*)alertController;

/**
 Asks the delegate if editing should begin

 @param titleView the room title view.
 @return  YES if an editing session should be initiated; otherwise, NO to disallow editing.
 */
- (BOOL)roomTitleViewShouldBeginEditing:(MXKRoomTitleView*)titleView;

@optional

/**
 Tells the delegate that the saving of user's changes is in progress or is finished.
 
 @param titleView the room title view.
 @param saving YES if a request is running to save user's changes.
 */
- (void)roomTitleView:(MXKRoomTitleView*)titleView isSaving:(BOOL)saving;

@end

/**
 'MXKRoomTitleView' instance displays editable room display name.
 */
@interface MXKRoomTitleView : MXKView <UITextFieldDelegate>
{
@protected
    /**
     Potential alert.
     */
    UIAlertController *currentAlert;
    
    /**
     Test fields input accessory.
     */
    UIView *inputAccessoryView;
}

@property (weak, nonatomic) IBOutlet UITextField *displayNameTextField;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *displayNameTextFieldTopConstraint;

@property (strong, nonatomic) MXRoom *mxRoom;
@property (strong, nonatomic) MXUser *mxUser;
@property (nonatomic) BOOL editable;
@property (nonatomic) BOOL isEditing;

/**
 *  Returns the `UINib` object initialized for the room title view.
 *
 *  @return The initialized `UINib` object or `nil` if there were errors during
 *  initialization or the nib file could not be located.
 */
+ (UINib *)nib;

/**
 Creates and returns a new `MXKRoomTitleView-inherited` object.
 
 @discussion This is the designated initializer for programmatic instantiation.
 @return An initialized `MXKRoomTitleView-inherited` object if successful, `nil` otherwise.
 */
+ (instancetype)roomTitleView;

/**
 The delegate notified when inputs are ready.
 */
@property (weak, nonatomic) id<MXKRoomTitleViewDelegate> delegate;

/**
 The custom accessory view associated to all text field of this 'MXKRoomTitleView' instance.
 This view is actually used to retrieve the keyboard view. Indeed the keyboard view is the superview of
 this accessory view when a text field become the first responder.
 */
@property (readonly) UIView *inputAccessoryView;

/**
 Dismiss keyboard.
 */
- (void)dismissKeyboard;

/**
 Force title view refresh.
 */
- (void)refreshDisplay;

/**
 Dispose view resources and listener.
 */
- (void)destroy;

@end
