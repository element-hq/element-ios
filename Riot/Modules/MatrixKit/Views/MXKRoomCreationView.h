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

@class MXKRoomCreationView;
@protocol MXKRoomCreationViewDelegate <NSObject>

/**
 Tells the delegate that an alert must be presented.
 
 @param creationView the view.
 @param alertController the alert to present.
 */
- (void)roomCreationView:(MXKRoomCreationView*)creationView presentAlertController:(UIAlertController*)alertController;

/**
 Tells the delegate to open the room with the provided identifier in a specific matrix session.
 
 @param creationView the view.
 @param roomId the room identifier.
 @param mxSession the matrix session in which the room should be available.
 */
- (void)roomCreationView:(MXKRoomCreationView*)creationView showRoom:(NSString*)roomId withMatrixSession:(MXSession*)mxSession;
@end

/**
 MXKRoomCreationView instance is a cell dedicated to room creation.
 Add this view in your app to offer room creation option.
 */
@interface MXKRoomCreationView : MXKView <UITextFieldDelegate> {
@protected
    UIView *inputAccessoryView;
}

/**
 *  Returns the `UINib` object initialized for the tool bar view.
 *
 *  @return The initialized `UINib` object or `nil` if there were errors during
 *  initialization or the nib file could not be located.
 */
+ (UINib *)nib;

/**
 Creates and returns a new `MXKRoomCreationView-inherited` object.
 
 @discussion This is the designated initializer for programmatic instantiation.
 @return An initialized `MXKRoomCreationView-inherited` object if successful, `nil` otherwise.
 */
+ (instancetype)roomCreationView;

/**
 The delegate.
 */
@property (nonatomic, weak) id<MXKRoomCreationViewDelegate> delegate;

/**
 Hide room name field (NO by default).
 Set YES this property to disable room name edition and hide the related items.
 */
@property (nonatomic, getter=isRoomNameFieldHidden) BOOL roomNameFieldHidden;

/**
 Hide room alias field (NO by default).
 Set YES this property to disable room alias edition and hide the related items.
 */
@property (nonatomic, getter=isRoomAliasFieldHidden) BOOL roomAliasFieldHidden;

/**
 Hide room participants field (NO by default).
 Set YES this property to disable room participants edition and hide the related items.
 */
@property (nonatomic, getter=isParticipantsFieldHidden) BOOL participantsFieldHidden;

/**
 The view height which takes into account potential hidden fields
 */
@property (nonatomic) CGFloat actualFrameHeight;

/**
 */
@property (nonatomic) NSArray* mxSessions;

/**
 The custom accessory view associated to all text field of this 'MXKRoomCreationView' instance.
 This view is actually used to retrieve the keyboard view. Indeed the keyboard view is the superview of
 this accessory view when a text field become the first responder.
 */
@property (readonly) UIView *inputAccessoryView;

/**
 UI items
 */
@property (weak, nonatomic) IBOutlet UILabel *roomNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *roomAliasLabel;
@property (weak, nonatomic) IBOutlet UILabel *participantsLabel;
@property (weak, nonatomic) IBOutlet UITextField *roomNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *roomAliasTextField;
@property (weak, nonatomic) IBOutlet UITextField *participantsTextField;
@property (weak, nonatomic) IBOutlet UISegmentedControl *roomVisibilityControl;
@property (weak, nonatomic) IBOutlet UIButton *createRoomBtn;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *roomNameFieldTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *roomAliasFieldTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *participantsFieldTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textFieldLeftConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *createRoomBtnTopConstraint;

/**
 Action registered to handle text field editing change (UIControlEventEditingChanged).
 */
- (IBAction)textFieldEditingChanged:(id)sender;

/**
 Force dismiss keyboard.
 */
- (void)dismissKeyboard;

/**
 Dispose any resources and listener.
 */
- (void)destroy;

@end
