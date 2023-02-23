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

#import <UIKit/UIKit.h>

#import <Photos/Photos.h>

#import "MXKView.h"

/**
 List the predefined modes to handle the size of attached images
 */
typedef enum : NSUInteger
{
    /**
     Prompt the user to select the compression level
     */
    MXKRoomInputToolbarCompressionModePrompt,
    
    /**
     The compression level is fixed for the following modes
     */
    MXKRoomInputToolbarCompressionModeSmall,
    MXKRoomInputToolbarCompressionModeMedium,
    MXKRoomInputToolbarCompressionModeLarge,
    
    /**
     No compression, the original image is sent
     */
    MXKRoomInputToolbarCompressionModeNone
    
} MXKRoomInputToolbarCompressionMode;


@class MXKRoomInputToolbarView;
@class MXKImageView;
@protocol MXKRoomInputToolbarViewDelegate <NSObject>

/**
 Tells the delegate that an alert must be presented.
 
 @param toolbarView the room input toolbar view.
 @param alertController the alert to present.
 */
- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView presentAlertController:(UIAlertController*)alertController;

/**
 Tells the delegate that the visibility of the status bar must be changed.
 
 @param toolbarView the room input toolbar view.
 @param isHidden tell whether the status bar must be hidden or not.
 */
- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView hideStatusBar:(BOOL)isHidden;

@optional

/**
 Tells the delegate that the user is typing or has finished typing.
 
 @param toolbarView the room input toolbar view
 @param typing YES if the user is typing inside the message composer.
 */
- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView isTyping:(BOOL)typing;

/**
 Tells the delegate that toolbar height has been updated.
 
 @param toolbarView the room input toolbar view.
 @param height the updated height of toolbar view.
 @param completion a block object to be executed when height change is taken into account.
 */
- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView heightDidChanged:(CGFloat)height completion:(void (^)(BOOL finished))completion;

/**
 Tells the delegate that the user wants to send a text message.
 
 @param toolbarView the room input toolbar view.
 @param textMessage the string to send.
 */
- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView sendTextMessage:(NSString*)textMessage;

/**
 Tells the delegate that the user wants to send a formatted  text message.

 @param toolbarView the room input toolbar view.
 @param formattedTextMessage the formatted message to send.
 @param rawText the raw message to send.
 */
- (void)roomInputToolbarView:(MXKRoomInputToolbarView *)toolbarView sendFormattedTextMessage:(NSString *)formattedTextMessage withRawText:(NSString *)rawText;

/**
 Tells the delegate that the user wants to display the send media actions.

 @param toolbarView the room input toolbar view.
 */
- (void)roomInputToolbarViewShowSendMediaActions:(MXKRoomInputToolbarView *)toolbarView;

/**
 Tells the delegate that the user wants to send an image.
 
 @param toolbarView the room input toolbar view.
 @param image the UIImage hosting the image data to send.
 */
- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView sendImage:(UIImage*)image;

/**
 Tells the delegate that the user wants to send an image.
 
 @param toolbarView the room input toolbar view.
 @param imageData the full-sized image data of the image.
 @param mimetype image mime type
 */
- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView sendImage:(NSData*)imageData withMimeType:(NSString*)mimetype;

/**
 Tells the delegate that the user wants to send a video.
 
 @param toolbarView the room input toolbar view.
 @param videoLocalURL the local filesystem path of the video to send.
 @param videoThumbnail the UIImage hosting a video thumbnail.
 */
- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView sendVideo:(NSURL*)videoLocalURL withThumbnail:(UIImage*)videoThumbnail;

/**
 Tells the delegate that the user wants to send a video.
 
 @param toolbarView the room input toolbar view.
 @param videoAsset the AVAsset that represents the video to send.
 @param videoThumbnail the UIImage hosting a video thumbnail.
 */
- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView sendVideoAsset:(AVAsset*)videoAsset withThumbnail:(UIImage*)videoThumbnail;

/**
 Tells the delegate that the user wants to send a file.
 
 @param toolbarView the room input toolbar view.
 @param fileLocalURL the local filesystem path of the file to send.
 @param mimetype file mime type
 */
- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView sendFile:(NSURL*)fileLocalURL withMimeType:(NSString*)mimetype;

/**
 Tells the delegate that the user wants invite a matrix user.
 
 Note: `Invite matrix user` option is displayed in actions list only if the delegate implements this method.
 
 @param toolbarView the room input toolbar view.
 @param mxUserId the Matrix user id.
 */
- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView inviteMatrixUser:(NSString*)mxUserId;

/**
 Tells the delegate that the user wants to place a voice or a video call.
 
 @param toolbarView the room input toolbar view.
 @param video YES to make a video call.
 */
- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView placeCallWithVideo:(BOOL)video;

/**
 Tells the delegate that the user wants to hangup the current call.

 @param toolbarView the room input toolbar view.
 */
- (void)roomInputToolbarViewHangupCall:(MXKRoomInputToolbarView*)toolbarView;

/**
 Tells the delegate to present a view controller modally.
 
 Note: Media attachment is available only if the delegate implements this method.
 
 @param toolbarView the room input toolbar view.
 @param viewControllerToPresent the view controller to present.
 */
- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView presentViewController:(UIViewController*)viewControllerToPresent;

/**
 Tells the delegate to dismiss the view controller that was presented modally
 
 @param toolbarView the room input toolbar view.
 @param flag Pass YES to animate the transition.
 @param completion The block to execute after the view controller is dismissed.
 */
- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion;

/**
 Tells the delegate to start or stop an activity indicator.
 
 @param toolbarView the room input toolbar view
 @param isAnimating YES if the activity indicator should run.
 */
- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView updateActivityIndicator:(BOOL)isAnimating;

@end

/**
 `MXKRoomInputToolbarView` instance is a view used to handle all kinds of available inputs
 for a room (message composer, attachments selection...).
 
 By default the right button of the toolbar offers the following options: attach media, invite new members.
 By default the left button is used to send the content of the message composer.
 By default 'messageComposerContainer' is empty.
 */
@interface MXKRoomInputToolbarView : MXKView <UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
    /**
     The message composer container view. Your own message composer may be added inside this container.
     */
    UIView *messageComposerContainer;
    
@protected
    UIView *inputAccessoryViewForKeyboard;
}

/**
 *  Returns the `UINib` object initialized for the tool bar view.
 *
 *  @return The initialized `UINib` object or `nil` if there were errors during
 *  initialization or the nib file could not be located.
 */
+ (UINib *)nib;

/**
 Creates and returns a new `MXKRoomInputToolbarView-inherited` object.
 
 @discussion This is the designated initializer for programmatic instantiation.
 @return An initialized `MXKRoomInputToolbarView-inherited` object if successful, `nil` otherwise.
 */
+ (MXKRoomInputToolbarView *)instantiateRoomInputToolbarView;

/**
 The delegate notified when inputs are ready.
 */
@property (weak, nonatomic) id<MXKRoomInputToolbarViewDelegate> delegate;

/**
  A custom button displayed on the left of the toolbar view.
 */
@property (weak, nonatomic) IBOutlet UIButton *leftInputToolbarButton;

/**
 A custom button displayed on the right of the toolbar view.
 */
@property (weak, nonatomic) IBOutlet UIButton *rightInputToolbarButton;

/**
 Layout constraint between the top of the message composer container and the top of its superview.
 The first view is the container, the second is the superview.
 */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *messageComposerContainerTopConstraint;

/**
 Layout constraint between the bottom of the message composer container and the bottom of its superview.
 The first view is the superview, the second is the container.
 */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *messageComposerContainerBottomConstraint;

/**
 Tell whether the sent images and videos should be automatically saved in the user's photos library. NO by default.
 */
@property (nonatomic) BOOL enableAutoSaving;

/**
 Tell whether the text is editable. YES by default.
 */
@property(nonatomic, getter=isEditable) BOOL editable;

/**
 `onTouchUpInside` action is registered on `Touch Up Inside` event for both buttons (left and right input toolbar buttons).
 Override this method to customize user interaction handling
 
 @param button the event sender
 */
- (IBAction)onTouchUpInside:(UIButton*)button;

/**
 Send message currently displayed inside toolbar's ` UITextView`.
 */
- (void)sendCurrentMessage;

/**
 Handle image attachment
 Save the image in user's photos library when 'isPhotoLibraryAsset' flag is NO and auto saving is enabled.
 
 @param imageData the full-sized image data of the selected image.
 @param mimetype the image MIME type (nil if unknown).
 @param compressionMode the compression mode to apply on this image. This option is considered only for jpeg image.
 @param isPhotoLibraryAsset tell whether the image has been selected from the user's photos library or not.
 */
- (void)sendSelectedImage:(NSData*)imageData withMimeType:(NSString *)mimetype andCompressionMode:(MXKRoomInputToolbarCompressionMode)compressionMode isPhotoLibraryAsset:(BOOL)isPhotoLibraryAsset;

/**
 Handle video attachment.
 Save the video in user's photos library when 'isPhotoLibraryAsset' flag is NO and auto saving is enabled.
 
 @param selectedVideo the local url of the video to send.
 @param isPhotoLibraryAsset tell whether the video has been selected from user's photos library.
 */
- (void)sendSelectedVideo:(NSURL*)selectedVideo isPhotoLibraryAsset:(BOOL)isPhotoLibraryAsset;

/**
 Handle video attachment.
 Save the video in user's photos library when 'isPhotoLibraryAsset' flag is NO and auto saving is enabled.
 
 @param selectedVideo an AVAsset that represents the video to send.
 @param isPhotoLibraryAsset tell whether the video has been selected from user's photos library.
 */
- (void)sendSelectedVideoAsset:(AVAsset*)selectedVideo isPhotoLibraryAsset:(BOOL)isPhotoLibraryAsset;

/**
 Handle multiple media attachments according to the compression mode.
 
 @param assets the selected assets.
 @param compressionMode the compression mode to apply on the media. This option is considered only for jpeg image.
 */
- (void)sendSelectedAssets:(NSArray<PHAsset*>*)assets withCompressionMode:(MXKRoomInputToolbarCompressionMode)compressionMode;

/**
 The maximum height of the toolbar.
 A value <= 0 means no limit.
 */
@property CGFloat maxHeight;

/**
 The current text message in message composer.
 */
@property NSString *textMessage;

/**
 The string that should be displayed when there is no other text in message composer.
 This property may be ignored when message composer does not support placeholder display.
 */
@property (nonatomic) NSString *placeholder;

/**
 The custom accessory view associated with the message composer. This view is
 actually used to retrieve the keyboard view. Indeed the keyboard view is the superview of
 the accessory view when the message composer become the first responder.
 */
@property UIView *inputAccessoryViewForKeyboard;

/**
 Display the keyboard.
 */
- (BOOL)becomeFirstResponder;

/**
 Force dismiss keyboard.
 */
- (void)dismissKeyboard;

/**
 Dispose any resources and listener.
 */
- (void)destroy;

/**
 Paste a text in textMessage.
 
 The text is pasted at the current cursor location in the message composer or it
 replaces the currently selected text.
 
 @param text the text to paste.
 */
- (void)pasteText:(NSString*)text;

/**
 The current attributed text message in message composer.
 */
@property (nonatomic) NSAttributedString *attributedTextMessage;

- (void)dismissValidationView:(MXKImageView*)validationView;

@end
