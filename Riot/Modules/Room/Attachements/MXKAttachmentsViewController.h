/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
*/

#import <MatrixSDK/MatrixSDK.h>

#import "MXKViewController.h"
#import "MXKAttachment.h"
#import "MXKAttachmentAnimator.h"

@protocol MXKAttachmentsViewControllerDelegate;

/**
 This view controller is used to display attachments of a room.
 Only one attachment is displayed at once, the user is able to swipe one by one the attachment.
 */
@interface MXKAttachmentsViewController : MXKViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIDocumentInteractionControllerDelegate, MXKDestinationAttachmentAnimatorDelegate>

@property (nonatomic) IBOutlet UICollectionView *attachmentsCollection;
@property (nonatomic) IBOutlet UIView *navigationBarContainer;
@property (nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (unsafe_unretained, nonatomic) IBOutlet UIBarButtonItem *backButton;

/**
 The attachments array.
 */
@property (nonatomic, readonly) NSArray *attachments;

/**
 Tell whether all attachments have been retrieved from the room history (In that case no attachment can be added at the beginning of attachments array).
 */
@property (nonatomic) BOOL complete;

/**
 The delegate notified when inputs are ready.
 */
@property (nonatomic, weak) id<MXKAttachmentsViewControllerDelegate> delegate;

#pragma mark - Class methods

/**
 Returns the `UINib` object initialized for a `MXKAttachmentsViewController`.

 @return The initialized `UINib` object or `nil` if there were errors during initialization
 or the nib file could not be located.
 
 @discussion You may override this method to provide a customized nib. If you do,
 you should also override `roomViewController` to return your
 view controller loaded from your custom nib.
 */
+ (UINib *)nib;

/**
 Creates and returns a new `MXKAttachmentsViewController` object.

 @discussion This is the designated initializer for programmatic instantiation.
 @return An initialized `MXKAttachmentsViewController` object if successful, `nil` otherwise.
 */
+ (instancetype)attachmentsViewController;

/**
 Creates and returns a new `MXKAttachmentsViewController` object, also sets sets up environment for animated interactive transitions.
 */
+ (instancetype)animatedAttachmentsViewControllerWithSourceViewController:(UIViewController <MXKSourceAttachmentAnimatorDelegate> *)sourceViewController;

/**
 Display attachments of a room.
 
 The provided event id is used to select the attachment to display first. Use nil to unchange the current displayed attachment.
 By default the first attachment is displayed.
 If the back pagination spinner is currently displayed and provided event id is nil,
 the viewer will display the first added attachment during back pagination.

 @param attachmentArray the array of attachments (MXKAttachment instances).
 @param eventId the identifier of the attachment to display first.
 
 */
- (void)displayAttachments:(NSArray*)attachmentArray focusOn:(NSString*)eventId;

/**
 Action used to handle the `backButton` in the navigation bar. 
 */
- (IBAction)onButtonPressed:(id)sender;

@end

@protocol MXKAttachmentsViewControllerDelegate <NSObject>

/**
 Ask the delegate for more attachments.
 This method is called only if 'complete' is NO.
 
 When some attachments are available, the delegate update the attachmnet list by using
 [MXKAttachmentsViewController displayAttachments: focusOn:].
 When no new attachment is available, the delegate must update the property 'complete'.
 
 @param attachmentsViewController the attachments view controller.
 @param eventId the event identifier of the current first attachment.
 @return a boolean which tells whether some new attachments may be added or not.
 */
- (BOOL)attachmentsViewController:(MXKAttachmentsViewController*)attachmentsViewController paginateAttachmentBefore:(NSString*)eventId;

@optional

/**
 Informs the delegate that a new attachment has been shown
 the parameter eventId is used by the delegate to identify the attachment
 */
- (void)displayedNewAttachmentWithEventId:(NSString *)eventId;


@end
