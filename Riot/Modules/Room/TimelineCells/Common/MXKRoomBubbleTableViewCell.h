/*
Copyright 2018-2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKTableViewCell.h"
#import "MXKCellRendering.h"
#import "MXKReceiptSendersContainer.h"

#import <WebKit/WebKit.h>

@class MXKImageView;
@class MXKPieChartView;
@class MXKRoomBubbleCellData;

#pragma mark - MXKCellRenderingDelegate cell tap locations

/**
 Action identifier used when the user tapped on message text view.
 
 The `userInfo` dictionary contains an `MXEvent` object under the `kMXKRoomBubbleCellEventKey` key, representing the tapped event.
 */
extern NSString *const kMXKRoomBubbleCellTapOnMessageTextView;

/**
 Action identifier used when the user tapped on user name label.
 
 The `userInfo` dictionary contains an `NSString` object under the `kMXKRoomBubbleCellUserIdKey` key, representing the user id of the tapped name label.
 */
extern NSString *const kMXKRoomBubbleCellTapOnSenderNameLabel;

/**
 Action identifier used when the user tapped on avatar view.
 
 The `userInfo` dictionary contains an `NSString` object under the `kMXKRoomBubbleCellUserIdKey` key, representing the user id of the tapped avatar.
 */
extern NSString *const kMXKRoomBubbleCellTapOnAvatarView;

/**
 Action identifier used when the user tapped on date/time container.
 
 The `userInfo` is nil.
 */
extern NSString *const kMXKRoomBubbleCellTapOnDateTimeContainer;

/**
 Action identifier used when the user tapped on attachment view.
 
 The `userInfo` is nil. The attachment can be retrieved via MXKRoomBubbleTableViewCell.attachmentView.
 */
extern NSString *const kMXKRoomBubbleCellTapOnAttachmentView;

/**
 Action identifier used when the user tapped on overlay container.
 
 The `userInfo` is nil
 */
extern NSString *const kMXKRoomBubbleCellTapOnOverlayContainer;

/**
 Action identifier used when the user tapped on content view.
 
 The `userInfo` dictionary may contain an `MXEvent` object under the `kMXKRoomBubbleCellEventKey` key, representing the event displayed at the level of the tapped line. This dictionary is empty if no event correspond to the tapped position.
 */
extern NSString *const kMXKRoomBubbleCellTapOnContentView;

/**
 Action identifier used when the user pressed unsent button displayed in front of an unsent event.
 
 The `userInfo` dictionary contains an `MXEvent` object under the `kMXKRoomBubbleCellEventKey` key, representing the unsent event.
 */
extern NSString *const kMXKRoomBubbleCellUnsentButtonPressed;

/**
 Action identifier used when the user pressed stop share button displayed in live location cell.
 
 The `userInfo` dictionary contains an `MXEvent` object under the `kMXKRoomBubbleCellEventKey` key, representing the live location event to stop.
 */
extern NSString *const kMXKRoomBubbleCellStopShareButtonPressed;

/**
 Action identifier used when the user pressed retry share button displayed in live location cell.
 
 The `userInfo` dictionary contains an `MXEvent` object under the `kMXKRoomBubbleCellEventKey` key, representing the live location event to retry.
 */
extern NSString *const kMXKRoomBubbleCellRetryShareButtonPressed;

/**
 Action identifier used when the user long pressed on a displayed event.
 
 The `userInfo` dictionary contains an `MXEvent` object under the `kMXKRoomBubbleCellEventKey` key, representing the selected event.
 */
extern NSString *const kMXKRoomBubbleCellLongPressOnEvent;

/**
 Action identifier used when the user long pressed on progress view.
 
 The `userInfo` is nil. The progress view can be retrieved via MXKRoomBubbleTableViewCell.progressView.
 */
extern NSString *const kMXKRoomBubbleCellLongPressOnProgressView;

/**
 Action identifier used when the user long pressed on avatar view.
 
 The `userInfo` dictionary contains an `NSString` object under the `kMXKRoomBubbleCellUserIdKey` key, representing the user id of the concerned avatar.
 */
extern NSString *const kMXKRoomBubbleCellLongPressOnAvatarView;

/**
 Action identifier used when the user clicked on a link.

 This action is sent via the MXKCellRenderingDelegate `shouldDoAction` operation.

 The `userInfo` dictionary contains a `NSURL` object under the `kMXKRoomBubbleCellUrl` key, representing the url the user wants to open. And a NSNumber wrapping `UITextItemInteraction` raw value, representing the type of interaction expected with the URL, under the `kMXKRoomBubbleCellUrlItemInteraction` key.

 The shouldDoAction implementation must return NO to prevent the system (safari) from opening the link.
 
 @discussion: If the link refers to a room alias/id, a user id or an event id, the non-ASCII characters (like '#' in room alias) has been
 escaped to be able to convert it into a legal URL string.
 */
extern NSString *const kMXKRoomBubbleCellShouldInteractWithURL;

/**
 Notifications `userInfo` keys
 */
extern NSString *const kMXKRoomBubbleCellUserIdKey;
extern NSString *const kMXKRoomBubbleCellEventKey;
extern NSString *const kMXKRoomBubbleCellEventIdKey;
extern NSString *const kMXKRoomBubbleCellReceiptsContainerKey;
extern NSString *const kMXKRoomBubbleCellUrl;
extern NSString *const kMXKRoomBubbleCellUrlItemInteraction;

#pragma mark - MXKRoomBubbleTableViewCell

/**
 `MXKRoomBubbleTableViewCell` is a base class for displaying a room bubble.
 
 This class is used to handle a maximum of items which may be present in bubbles display (like the user's picture view, the message text view...).
 To optimize bubbles rendering, we advise to define a .xib for each kind of bubble layout (with or without sender's information, with or without attachment...).
 Each inherited class should define only the actual displayed items.
 */
@interface MXKRoomBubbleTableViewCell : MXKTableViewCell <MXKCellRendering, UITextViewDelegate, WKNavigationDelegate>
{
@protected
    /**
     The current bubble data displayed by the table view cell
     */
    MXKRoomBubbleCellData *bubbleData;
}

/**
 The current bubble data displayed by the table view cell
 */
@property (strong, nonatomic, readonly) MXKRoomBubbleCellData *bubbleData;

/**
 Option to highlight or not the content of message text view (May be used in case of text selection).
 NO by default.
 */
@property (nonatomic) BOOL allTextHighlighted;

/**
 Tell whether the animation should start automatically in case of animated gif (NO by default).
 */
@property (nonatomic) BOOL isAutoAnimatedGif;

/**
 The default picture displayed when no picture is available.
 */
@property (nonatomic) UIImage *picturePlaceholder;

/**
 The list of the temporary subviews that should be removed before reusing the cell (empty array by default).
 */
@property (nonatomic) NSMutableArray<UIView*> *tmpSubviews;

/**
 The read receipts alignment.
 By default, they are left aligned.
 */
@property (nonatomic) ReadReceiptsAlignment readReceiptsAlignment;

@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UIView *userNameTapGestureMaskView;
@property (strong, nonatomic) IBOutlet MXKImageView *pictureView;
@property (weak, nonatomic) IBOutlet UITextView  *messageTextView;
@property (strong, nonatomic) IBOutlet MXKImageView *attachmentView;
@property (strong, nonatomic) IBOutlet UIImageView *playIconView;
@property (strong, nonatomic) IBOutlet UIImageView *fileTypeIconView;
@property (weak, nonatomic) IBOutlet UIView *bubbleInfoContainer;
@property (weak, nonatomic) IBOutlet UIView *bubbleOverlayContainer;

/**
 The container view in which the encryption information may be displayed
 */
@property (weak, nonatomic) IBOutlet UIView *encryptionStatusContainerView;

@property (weak, nonatomic) IBOutlet UIView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *statsLabel;
@property (weak, nonatomic) IBOutlet MXKPieChartView *progressChartView;

/**
 The constraints which defines the relationship between messageTextView and its superview.
 The defined constant are supposed >= 0.
 */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *msgTextViewTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *msgTextViewBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *msgTextViewLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *msgTextViewTrailingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *msgTextViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *msgTextViewMinHeightConstraint;

/**
 The constraints which defines the relationship between attachmentView and its superview
 The defined constant are supposed >= 0.
 */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *attachViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *attachViewMinHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *attachViewTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *attachViewBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *attachViewLeadingConstraint;
@property (weak, nonatomic) NSLayoutConstraint *attachViewTrailingConstraint;

/**
 The constraints which defines the relationship between bubbleInfoContainer and its superview
 The defined constant are supposed >= 0.
 */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bubbleInfoContainerTopConstraint;

/**
 The read marker view and its layout constraints (nil by default).
 */
@property (nonatomic, nullable) UIView *readMarkerView;
@property (nonatomic, nullable) NSLayoutConstraint *readMarkerViewTopConstraint;
@property (nonatomic, nullable) NSLayoutConstraint *readMarkerViewLeadingConstraint;
@property (nonatomic, nullable) NSLayoutConstraint *readMarkerViewTrailingConstraint;
@property (nonatomic, nullable) NSLayoutConstraint *readMarkerViewHeightConstraint;

/**
 The potential webview used to render an attachment (for example an animated gif).
 */
@property (nonatomic) WKWebView *attachmentWebView;

/**
 Indicate true if the cell needs vertical space in the text to position UI components.
 */
@property (nonatomic, readonly) BOOL isTextViewNeedsPositioningVerticalSpace;

/**
 Use bubbleData.attributedTextMessage or bubbleData.attributedTextMessageWithoutPositioningSpace according to isTextViewNeedsPositioningVerticalSpace value.
 */
@property (nonatomic, readonly) NSAttributedString *suitableAttributedTextMessage;

/**
 Called during the designated initializer of the UITableViewCell class to set the default
 properties values.
 
 You should not call this method directly.
 
 Subclasses can override this method as needed to customize the initialization.
 */
- (void)finalizeInit;

/**
 Handle progressView display.
 */
- (void)startProgressUI;
- (void)updateProgressUI:(NSDictionary*)statisticsDict;

#pragma mark - Original Xib values

/**
 Get an original instance of the `MXKRoomBubbleTableViewCell` child class.

 @return an instance of the child class caller which has the original Xib values.
 */
+ (MXKRoomBubbleTableViewCell*)cellWithOriginalXib;

/**
 Disable the handling of the long press on event (see kMXKRoomBubbleCellLongPressOnEvent). NO by default.
 
 CAUTION: Changing this flag only impact the new created cells (existing 'MXKRoomBubbleTableViewCell' instances are unchanged).
 */
+ (void)disableLongPressGestureOnEvent:(BOOL)disable;

/**
 Method used during [MXKCellRendering render:] to check the provided `cellData`
 and prepare the protected `bubbleData`.
 Do not override it.

 @param cellData the data object to render.
 */
- (void)prepareRender:(MXKCellData*)cellData;

/**
 Highlight text message related to a specific event in the displayed message.
 
 @param eventId the id of the event to highlight (use nil to cancel highlighting).
 */
- (void)highlightTextMessageForEvent:(NSString*)eventId;

/**
 The top position of an event in the cell.
 
 A cell can display several events. The method returns the vertical position of a given
 event in the cell.
 
 @return the y position (in pixel) of the event in the cell.
 */
- (CGFloat)topPositionOfEvent:(NSString*)eventId;

/**
 The bottom position of an event in the cell.
 
 A cell can display several events. The method returns the vertical position of the bottom part
 of a given event in the cell.
 
 @return the y position (in pixel) of the bottom part of the event in the cell.
 */
- (CGFloat)bottomPositionOfEvent:(NSString*)eventId;

/**
 Restore `attachViewBottomConstraint` constant to default value.
 */
- (void)resetAttachmentViewBottomConstraintConstant;

/**
 Redeclare heightForCellData:withMaximumWidth: method from MXKCellRendering to use it as a class method in Swift and not a static method.
 */
+ (CGFloat)heightForCellData:(MXKCellData*)cellData withMaximumWidth:(CGFloat)maxWidth;

/**
 Setup outlets views. Useful to call when cell subclass does not use a xib otherwise this method is called automatically in `awakeFromNib`.
 */
- (void)setupViews;

/// Setup sender name label if needed
- (void)setupSenderNameLabel;

/// Setup avatar view if needed
- (void)setupAvatarView;

/// Setup message text view if needed
- (void)setupMessageTextView;

/// Setup message text view long press gesture if needed
- (void)setupMessageTextViewLongPressGesture;

/// Add temporary subview to `tmpSubviews` property.
- (void)addTemporarySubview:(UIView*)subview;

/// Called when content view cell is tapped
- (IBAction)onContentViewTap:(UITapGestureRecognizer*)sender;

/// Called when sender name is tapped
- (IBAction)onSenderNameTap:(UITapGestureRecognizer*)sender;

/// Called when avatar view is tapped
- (IBAction)onAvatarTap:(UITapGestureRecognizer*)sender;

/// Called when a UI component is long pressed
- (IBAction)onLongPressGesture:(UILongPressGestureRecognizer*)longPressGestureRecognizer;

/// Remove marker view if present
- (void)removeReadMarkerView;

@end
