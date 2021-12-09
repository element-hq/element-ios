/*
 Copyright 2014 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 Copyright 2018 New Vector Ltd
 
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

@import MobileCoreServices;

#import "RoomViewController.h"

#import "RoomDataSource.h"
#import "RoomBubbleCellData.h"

#import "RoomInputToolbarView.h"
#import "DisabledRoomInputToolbarView.h"

#import "RoomActivitiesView.h"

#import "AttachmentsViewController.h"

#import "EventDetailsView.h"

#import "RoomAvatarTitleView.h"
#import "ExpandedRoomTitleView.h"
#import "SimpleRoomTitleView.h"
#import "PreviewRoomTitleView.h"

#import "RoomMemberDetailsViewController.h"
#import "ContactDetailsViewController.h"

#import "SegmentedViewController.h"
#import "RoomSettingsViewController.h"

#import "RoomFilesViewController.h"

#import "RoomSearchViewController.h"

#import "UsersDevicesViewController.h"

#import "ReadReceiptsViewController.h"

#import "JitsiViewController.h"

#import "RoomEmptyBubbleCell.h"

#import "RoomIncomingTextMsgBubbleCell.h"
#import "RoomIncomingTextMsgWithoutSenderInfoBubbleCell.h"
#import "RoomIncomingTextMsgWithPaginationTitleBubbleCell.h"
#import "RoomIncomingTextMsgWithoutSenderNameBubbleCell.h"
#import "RoomIncomingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.h"
#import "RoomIncomingAttachmentBubbleCell.h"
#import "RoomIncomingAttachmentWithoutSenderInfoBubbleCell.h"
#import "RoomIncomingAttachmentWithPaginationTitleBubbleCell.h"

#import "RoomIncomingEncryptedTextMsgBubbleCell.h"
#import "RoomIncomingEncryptedTextMsgWithoutSenderInfoBubbleCell.h"
#import "RoomIncomingEncryptedTextMsgWithPaginationTitleBubbleCell.h"
#import "RoomIncomingEncryptedTextMsgWithoutSenderNameBubbleCell.h"
#import "RoomIncomingEncryptedTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.h"
#import "RoomIncomingEncryptedAttachmentBubbleCell.h"
#import "RoomIncomingEncryptedAttachmentWithoutSenderInfoBubbleCell.h"
#import "RoomIncomingEncryptedAttachmentWithPaginationTitleBubbleCell.h"

#import "RoomOutgoingTextMsgBubbleCell.h"
#import "RoomOutgoingTextMsgWithoutSenderInfoBubbleCell.h"
#import "RoomOutgoingTextMsgWithPaginationTitleBubbleCell.h"
#import "RoomOutgoingTextMsgWithoutSenderNameBubbleCell.h"
#import "RoomOutgoingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.h"
#import "RoomOutgoingAttachmentBubbleCell.h"
#import "RoomOutgoingAttachmentWithoutSenderInfoBubbleCell.h"
#import "RoomOutgoingAttachmentWithPaginationTitleBubbleCell.h"

#import "RoomOutgoingEncryptedTextMsgBubbleCell.h"
#import "RoomOutgoingEncryptedTextMsgWithoutSenderInfoBubbleCell.h"
#import "RoomOutgoingEncryptedTextMsgWithPaginationTitleBubbleCell.h"
#import "RoomOutgoingEncryptedTextMsgWithoutSenderNameBubbleCell.h"
#import "RoomOutgoingEncryptedTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.h"
#import "RoomOutgoingEncryptedAttachmentBubbleCell.h"
#import "RoomOutgoingEncryptedAttachmentWithoutSenderInfoBubbleCell.h"
#import "RoomOutgoingEncryptedAttachmentWithPaginationTitleBubbleCell.h"

#import "RoomMembershipBubbleCell.h"
#import "RoomMembershipWithPaginationTitleBubbleCell.h"
#import "RoomMembershipCollapsedBubbleCell.h"
#import "RoomMembershipCollapsedWithPaginationTitleBubbleCell.h"
#import "RoomMembershipExpandedBubbleCell.h"
#import "RoomMembershipExpandedWithPaginationTitleBubbleCell.h"
#import "RoomCreationWithPaginationCollapsedBubbleCell.h"
#import "RoomCreationCollapsedBubbleCell.h"

#import "RoomSelectedStickerBubbleCell.h"
#import "RoomPredecessorBubbleCell.h"

#import "MXKRoomBubbleTableViewCell+Riot.h"

#import "AvatarGenerator.h"
#import "Tools.h"
#import "WidgetManager.h"
#import "ShareManager.h"

#import "GBDeviceInfo_iOS.h"

#import "RoomEncryptedDataBubbleCell.h"
#import "EncryptionInfoView.h"

#import "MXRoom+Riot.h"

#import "IntegrationManagerViewController.h"
#import "WidgetPickerViewController.h"
#import "StickerPickerViewController.h"

#import "EventFormatter.h"

#import "SettingsViewController.h"
#import "SecurityViewController.h"

#import "TypingUserInfo.h"

#import "MXSDKOptions.h"

#import "GeneratedInterface-Swift.h"

NSNotificationName const RoomCallTileTappedNotification = @"RoomCallTileTappedNotification";
NSNotificationName const RoomGroupCallTileTappedNotification = @"RoomGroupCallTileTappedNotification";
const NSTimeInterval kResizeComposerAnimationDuration = .05;

@interface RoomViewController () <UISearchBarDelegate, UIGestureRecognizerDelegate, UIScrollViewAccessibilityDelegate, RoomTitleViewTapGestureDelegate, RoomParticipantsViewControllerDelegate, MXKRoomMemberDetailsViewControllerDelegate, ContactsTableViewControllerDelegate, MXServerNoticesDelegate, RoomContextualMenuViewControllerDelegate,
    ReactionsMenuViewModelCoordinatorDelegate, EditHistoryCoordinatorBridgePresenterDelegate, MXKDocumentPickerPresenterDelegate, EmojiPickerCoordinatorBridgePresenterDelegate,
    ReactionHistoryCoordinatorBridgePresenterDelegate, CameraPresenterDelegate, MediaPickerCoordinatorBridgePresenterDelegate,
    RoomDataSourceDelegate, RoomCreationModalCoordinatorBridgePresenterDelegate, RoomInfoCoordinatorBridgePresenterDelegate, DialpadViewControllerDelegate, RemoveJitsiWidgetViewDelegate, VoiceMessageControllerDelegate, SpaceDetailPresenterDelegate, UserSuggestionCoordinatorBridgeDelegate>
{
    
    // The preview header
    __weak PreviewRoomTitleView *previewHeader;
    
    // The customized room data source for Vector
    RoomDataSource *customizedRoomDataSource;
    
    // The user taps on a user id contained in a message
    MXKContact *selectedContact;
    
    // List of members who are typing in the room.
    NSArray *currentTypingUsers;
    
    // Typing notifications listener.
    __weak id typingNotifListener;
    
    // The position of the first touch down event stored in case of scrolling when the expanded header is visible.
    CGPoint startScrollingPoint;
    
    // Missed discussions badge
    NSUInteger missedDiscussionsCount;
    NSUInteger missedHighlightCount;
    UILabel *missedDiscussionsBadgeLabel;
    UIView *missedDiscussionsDotView;
    
    // Potential encryption details view.
    __weak EncryptionInfoView *encryptionInfoView;
    
    // The list of unknown devices that prevent outgoing messages from being sent
    MXUsersDevicesMap<MXDeviceInfo*> *unknownDevices;
    
    // Observe kAppDelegateDidTapStatusBarNotification to handle tap on clock status bar.
    __weak id kAppDelegateDidTapStatusBarNotificationObserver;
    
    // Observe kAppDelegateNetworkStatusDidChangeNotification to handle network status change.
    __weak id kAppDelegateNetworkStatusDidChangeNotificationObserver;

    // Observers to manage MXSession state (and sync errors)
    __weak id kMXSessionStateDidChangeObserver;

    // Observers to manage ongoing conference call banner
    __weak id kMXCallStateDidChangeObserver;
    __weak id kMXCallManagerConferenceStartedObserver;
    __weak id kMXCallManagerConferenceFinishedObserver;

    // Observers to manage widgets
    __weak id kMXKWidgetManagerDidUpdateWidgetObserver;
    
    // Observer kMXRoomSummaryDidChangeNotification to keep updated the missed discussion count
    __weak id mxRoomSummaryDidChangeObserver;

    // Observer for removing the re-request explanation/waiting dialog
    __weak id mxEventDidDecryptNotificationObserver;
    
    // The table view cell in which the read marker is displayed (nil by default).
    MXKRoomBubbleTableViewCell *readMarkerTableViewCell;
    
    // Tell whether the view controller is appeared or not.
    BOOL isAppeared;
    
    // Tell whether the room has a Jitsi call or not.
    BOOL hasJitsiCall;
    
    // The right bar button items back up.
    NSArray<UIBarButtonItem *> *rightBarButtonItems;

    // Observe kThemeServiceDidChangeThemeNotification to handle user interface theme change.
    __weak id kThemeServiceDidChangeThemeNotificationObserver;
    
    // Observe URL preview updates to refresh cells.
    __weak id URLPreviewDidUpdateNotificationObserver;
    
    // Listener for `m.room.tombstone` event type
    __weak id tombstoneEventNotificationsListener;

    // Homeserver notices
    MXServerNotices *serverNotices;
    
    // Formatted body parser for events
    FormattedBodyParser *formattedBodyParser;
    
    // Time to display notification content in the timeline
    MXTaskProfile *notificationTaskProfile;
}

@property (nonatomic, weak) IBOutlet UIView *overlayContainerView;
@property (nonatomic, strong) RemoveJitsiWidgetView *removeJitsiWidgetView;


@property (nonatomic, strong) RoomContextualMenuViewController *roomContextualMenuViewController;
@property (nonatomic, strong) RoomContextualMenuPresenter *roomContextualMenuPresenter;
@property (nonatomic, strong) MXKErrorAlertPresentation *errorPresenter;
@property (nonatomic, strong) NSString *textMessageBeforeEditing;
@property (nonatomic, strong) EditHistoryCoordinatorBridgePresenter *editHistoryPresenter;
@property (nonatomic, strong) MXKDocumentPickerPresenter *documentPickerPresenter;
@property (nonatomic, strong) EmojiPickerCoordinatorBridgePresenter *emojiPickerCoordinatorBridgePresenter;
@property (nonatomic, strong) ReactionHistoryCoordinatorBridgePresenter *reactionHistoryCoordinatorBridgePresenter;
@property (nonatomic, strong) CameraPresenter *cameraPresenter;
@property (nonatomic, strong) MediaPickerCoordinatorBridgePresenter *mediaPickerPresenter;
@property (nonatomic, strong) RoomMessageURLParser *roomMessageURLParser;
@property (nonatomic, strong) RoomCreationModalCoordinatorBridgePresenter *roomCreationModalCoordinatorBridgePresenter;
@property (nonatomic, strong) RoomInfoCoordinatorBridgePresenter *roomInfoCoordinatorBridgePresenter;
@property (nonatomic, strong) CustomSizedPresentationController *customSizedPresentationController;
@property (nonatomic, getter=isActivitiesViewExpanded) BOOL activitiesViewExpanded;
@property (nonatomic, getter=isScrollToBottomHidden) BOOL scrollToBottomHidden;
@property (nonatomic, getter=isMissedDiscussionsBadgeHidden) BOOL missedDiscussionsBadgeHidden;

@property (nonatomic, strong) VoiceMessageController *voiceMessageController;
@property (nonatomic, strong) SpaceDetailPresenter *spaceDetailPresenter;

@property (nonatomic, strong) ShareManager *shareManager;

@property (nonatomic, strong) UserSuggestionCoordinatorBridge *userSuggestionCoordinator;
@property (nonatomic, weak) IBOutlet UIView *userSuggestionContainerView;

@end

@implementation RoomViewController
@synthesize roomPreviewData;

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass(self.class)
                          bundle:[NSBundle bundleForClass:self.class]];
}

+ (instancetype)roomViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass(self.class)
                                          bundle:[NSBundle bundleForClass:self.class]];
}

+ (instancetype)instantiate
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    return [storyboard instantiateViewControllerWithIdentifier:@"RoomViewControllerStoryboardId"];
}

#pragma mark -

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Disable auto join
        self.autoJoinInvitedRoom = NO;
        
        // Disable auto scroll to bottom on keyboard presentation
        self.scrollHistoryToTheBottomOnKeyboardPresentation = NO;
    }
    
    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        // Disable auto join
        self.autoJoinInvitedRoom = NO;
        
        // Disable auto scroll to bottom on keyboard presentation
        self.scrollHistoryToTheBottomOnKeyboardPresentation = NO;
    }
    
    return self;
}

#pragma mark -

- (void)finalizeInit
{
    [super finalizeInit];
    
    self.resizeComposerAnimationDuration = kResizeComposerAnimationDuration;
    
    // Setup `MXKViewControllerHandling` properties
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
    formattedBodyParser = [FormattedBodyParser new];
    
    _showMissedDiscussionsBadge = YES;
    _scrollToBottomHidden = YES;
    
    // Listen to the event sent state changes
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eventDidChangeSentState:) name:kMXEventDidChangeSentStateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eventDidChangeIdentifier:) name:kMXEventDidChangeIdentifierNotification object:nil];
    
    // Show / hide actions button in document preview according BuildSettings
    self.allowActionsInDocumentPreview = BuildSettings.messageDetailsAllowShare;
    
    _voiceMessageController = [[VoiceMessageController alloc] initWithThemeService:ThemeService.shared mediaServiceProvider:VoiceMessageMediaServiceProvider.sharedProvider];
    self.voiceMessageController.delegate = self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Register first customized cell view classes used to render bubbles
    [self.bubblesTableView registerClass:RoomIncomingTextMsgBubbleCell.class forCellReuseIdentifier:RoomIncomingTextMsgBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomIncomingTextMsgWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:RoomIncomingTextMsgWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomIncomingTextMsgWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomIncomingTextMsgWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomIncomingAttachmentBubbleCell.class forCellReuseIdentifier:RoomIncomingAttachmentBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomIncomingAttachmentWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:RoomIncomingAttachmentWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomIncomingAttachmentWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomIncomingAttachmentWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomIncomingTextMsgWithoutSenderNameBubbleCell.class forCellReuseIdentifier:RoomIncomingTextMsgWithoutSenderNameBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomIncomingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.class forCellReuseIdentifier:RoomIncomingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.defaultReuseIdentifier];
    
    [self.bubblesTableView registerClass:RoomIncomingEncryptedTextMsgBubbleCell.class forCellReuseIdentifier:RoomIncomingEncryptedTextMsgBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomIncomingEncryptedTextMsgWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:RoomIncomingEncryptedTextMsgWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomIncomingEncryptedTextMsgWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomIncomingEncryptedTextMsgWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomIncomingEncryptedAttachmentBubbleCell.class forCellReuseIdentifier:RoomIncomingEncryptedAttachmentBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomIncomingEncryptedAttachmentWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:RoomIncomingEncryptedAttachmentWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomIncomingEncryptedAttachmentWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomIncomingEncryptedAttachmentWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomIncomingEncryptedTextMsgWithoutSenderNameBubbleCell.class forCellReuseIdentifier:RoomIncomingEncryptedTextMsgWithoutSenderNameBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomIncomingEncryptedTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.class forCellReuseIdentifier:RoomIncomingEncryptedTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.defaultReuseIdentifier];
    
    [self.bubblesTableView registerClass:RoomOutgoingAttachmentBubbleCell.class forCellReuseIdentifier:RoomOutgoingAttachmentBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomOutgoingAttachmentWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:RoomOutgoingAttachmentWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomOutgoingAttachmentWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomOutgoingAttachmentWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomOutgoingTextMsgBubbleCell.class forCellReuseIdentifier:RoomOutgoingTextMsgBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomOutgoingTextMsgWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:RoomOutgoingTextMsgWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomOutgoingTextMsgWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomOutgoingTextMsgWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomOutgoingTextMsgWithoutSenderNameBubbleCell.class forCellReuseIdentifier:RoomOutgoingTextMsgWithoutSenderNameBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomOutgoingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.class forCellReuseIdentifier:RoomOutgoingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.defaultReuseIdentifier];
    
    [self.bubblesTableView registerClass:RoomOutgoingEncryptedAttachmentBubbleCell.class forCellReuseIdentifier:RoomOutgoingEncryptedAttachmentBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomOutgoingEncryptedAttachmentWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:RoomOutgoingEncryptedAttachmentWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomOutgoingEncryptedAttachmentWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomOutgoingEncryptedAttachmentWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomOutgoingEncryptedTextMsgBubbleCell.class forCellReuseIdentifier:RoomOutgoingEncryptedTextMsgBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomOutgoingEncryptedTextMsgWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:RoomOutgoingEncryptedTextMsgWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomOutgoingEncryptedTextMsgWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomOutgoingEncryptedTextMsgWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomOutgoingEncryptedTextMsgWithoutSenderNameBubbleCell.class forCellReuseIdentifier:RoomOutgoingEncryptedTextMsgWithoutSenderNameBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomOutgoingEncryptedTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.class forCellReuseIdentifier:RoomOutgoingEncryptedTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.defaultReuseIdentifier];
    
    [self.bubblesTableView registerClass:RoomEmptyBubbleCell.class forCellReuseIdentifier:RoomEmptyBubbleCell.defaultReuseIdentifier];
    
    [self.bubblesTableView registerClass:RoomMembershipBubbleCell.class forCellReuseIdentifier:RoomMembershipBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomMembershipWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomMembershipWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomMembershipCollapsedBubbleCell.class forCellReuseIdentifier:RoomMembershipCollapsedBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomMembershipCollapsedWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomMembershipCollapsedWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomMembershipExpandedBubbleCell.class forCellReuseIdentifier:RoomMembershipExpandedBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomMembershipExpandedWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomMembershipExpandedWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    
    [self.bubblesTableView registerClass:RoomSelectedStickerBubbleCell.class forCellReuseIdentifier:RoomSelectedStickerBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomPredecessorBubbleCell.class forCellReuseIdentifier:RoomPredecessorBubbleCell.defaultReuseIdentifier];
    
    [self.bubblesTableView registerClass:KeyVerificationIncomingRequestApprovalBubbleCell.class forCellReuseIdentifier:KeyVerificationIncomingRequestApprovalBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:KeyVerificationIncomingRequestApprovalWithPaginationTitleBubbleCell.class forCellReuseIdentifier:KeyVerificationIncomingRequestApprovalWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:KeyVerificationRequestStatusBubbleCell.class forCellReuseIdentifier:KeyVerificationRequestStatusBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:KeyVerificationRequestStatusWithPaginationTitleBubbleCell.class forCellReuseIdentifier:KeyVerificationRequestStatusWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:KeyVerificationConclusionBubbleCell.class forCellReuseIdentifier:KeyVerificationConclusionBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:KeyVerificationConclusionWithPaginationTitleBubbleCell.class forCellReuseIdentifier:KeyVerificationConclusionWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    
    [self.bubblesTableView registerClass:RoomCreationCollapsedBubbleCell.class forCellReuseIdentifier:RoomCreationCollapsedBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomCreationWithPaginationCollapsedBubbleCell.class forCellReuseIdentifier:RoomCreationWithPaginationCollapsedBubbleCell.defaultReuseIdentifier];
    
    //  call cells
    [self.bubblesTableView registerClass:RoomDirectCallStatusBubbleCell.class forCellReuseIdentifier:RoomDirectCallStatusBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomGroupCallStatusBubbleCell.class forCellReuseIdentifier:RoomGroupCallStatusBubbleCell.defaultReuseIdentifier];
    
    [self.bubblesTableView registerClass:RoomCreationIntroCell.class forCellReuseIdentifier:RoomCreationIntroCell.defaultReuseIdentifier];
    
    [self.bubblesTableView registerNib:RoomTypingBubbleCell.nib forCellReuseIdentifier:RoomTypingBubbleCell.defaultReuseIdentifier];
    
    [self.bubblesTableView registerClass:VoiceMessageBubbleCell.class forCellReuseIdentifier:VoiceMessageBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:VoiceMessageWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:VoiceMessageWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:VoiceMessageWithPaginationTitleBubbleCell.class forCellReuseIdentifier:VoiceMessageWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    
    [self.bubblesTableView registerClass:PollBubbleCell.class forCellReuseIdentifier:PollBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:PollWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:PollWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:PollWithPaginationTitleBubbleCell.class forCellReuseIdentifier:PollWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    
    [self vc_removeBackTitle];
    
    // Display leftBarButtonItems or leftBarButtonItem to the right of the Back button
    self.navigationItem.leftItemsSupplementBackButton = YES;
    
    [self setupRemoveJitsiWidgetRemoveView];
    
    // Replace the default input toolbar view.
    // Note: this operation will force the layout of subviews. That is why cell view classes must be registered before.
    [self updateRoomInputToolbarViewClassIfNeeded];
    
    // set extra area
    [self setRoomActivitiesViewClass:RoomActivitiesView.class];
    
    // Custom the attachmnet viewer
    [self setAttachmentsViewerClass:AttachmentsViewController.class];
    
    // Custom the event details view
    [self setEventDetailsViewClass:EventDetailsView.class];
    
    // Prepare missed dicussion badge (if any)
    self.showMissedDiscussionsBadge = _showMissedDiscussionsBadge;
    
    // Set up the room title view according to the data source (if any)
    [self refreshRoomTitle];
    
    // Refresh tool bar if the room data source is set.
    if (self.roomDataSource)
    {
        [self refreshRoomInputToolbar];
    }
    
    self.roomContextualMenuPresenter = [RoomContextualMenuPresenter new];
    self.errorPresenter = [MXKErrorAlertPresentation new];
    self.roomMessageURLParser = [RoomMessageURLParser new];
    
    self.jumpToLastUnreadLabel.text = [VectorL10n roomJumpToFirstUnread];
    
    MXWeakify(self);
    
    // Observe user interface theme change.
    kThemeServiceDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kThemeServiceDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXStrongifyAndReturnIfNil(self);
        
        [self userInterfaceThemeDidChange];
        
    }];
    
    [self userInterfaceThemeDidChange];
    
    // Observe URL preview updates.
    [self registerURLPreviewNotifications];
    
    [self setupActions];
}

- (void)userInterfaceThemeDidChange
{
    // Consider the main navigation controller if the current view controller is embedded inside a split view controller.
    UINavigationController *mainNavigationController = self.navigationController;
    if (self.splitViewController.isCollapsed && self.splitViewController.viewControllers.count)
    {
        mainNavigationController = self.splitViewController.viewControllers.firstObject;
    }
    
    [ThemeService.shared.theme applyStyleOnNavigationBar:self.navigationController.navigationBar];
    if (mainNavigationController)
    {
        [ThemeService.shared.theme applyStyleOnNavigationBar:mainNavigationController.navigationBar];
    }
    
    // Keep navigation bar transparent in some cases
    if (!self.previewHeaderContainer.hidden)
    {
        self.navigationController.navigationBar.translucent = YES;
        mainNavigationController.navigationBar.translucent = YES;
    }
    
    [self.inputToolbarView customizeViewRendering];
    
    self.activityIndicator.backgroundColor = ThemeService.shared.theme.overlayBackgroundColor;
    
    [self.removeJitsiWidgetView updateWithTheme:ThemeService.shared.theme];
    
    // Prepare jump to last unread banner
    self.jumpToLastUnreadImageView.tintColor = ThemeService.shared.theme.tintColor;
    self.jumpToLastUnreadLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
    
    self.previewHeaderContainer.backgroundColor = ThemeService.shared.theme.headerBackgroundColor;
    
    // Check the table view style to select its bg color.
    self.bubblesTableView.backgroundColor = ((self.bubblesTableView.style == UITableViewStylePlain) ? ThemeService.shared.theme.backgroundColor : ThemeService.shared.theme.headerBackgroundColor);
    self.bubblesTableView.separatorColor = ThemeService.shared.theme.lineBreakColor;
    self.view.backgroundColor = self.bubblesTableView.backgroundColor;
    
    if (self.bubblesTableView.dataSource)
    {
        [self.bubblesTableView reloadData];
    }
    
    [self.scrollToBottomButton vc_addShadowWithColor:ThemeService.shared.theme.shadowColor
                                              offset:CGSizeMake(0, 4)
                                              radius:6
                                             opacity:0.2];

    self.inputBackgroundView.backgroundColor = [ThemeService.shared.theme.backgroundColor colorWithAlphaComponent:0.98];
    
    if (ThemeService.shared.isCurrentThemeDark)
    {
        [self.scrollToBottomButton setImage:[UIImage imageNamed:@"scrolldown_dark"] forState:UIControlStateNormal];

        self.jumpToLastUnreadBanner.backgroundColor = ThemeService.shared.theme.colors.navigation;
        [self.jumpToLastUnreadBanner vc_removeShadow];
        self.resetReadMarkerButton.tintColor = ThemeService.shared.theme.colors.quarterlyContent;
    }
    else
    {
        [self.scrollToBottomButton setImage:[UIImage imageNamed:@"scrolldown"] forState:UIControlStateNormal];
        
        self.jumpToLastUnreadBanner.backgroundColor = ThemeService.shared.theme.colors.background;
        [self.jumpToLastUnreadBanner vc_addShadowWithColor:ThemeService.shared.theme.shadowColor
                                                    offset:CGSizeMake(0, 4)
                                                    radius:8
                                                   opacity:0.1];
        self.resetReadMarkerButton.tintColor = ThemeService.shared.theme.colors.tertiaryContent;
    }
    
    self.scrollToBottomBadgeLabel.badgeColor = ThemeService.shared.theme.tintColor;
    
    [self setNeedsStatusBarAppearanceUpdate];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return ThemeService.shared.theme.statusBarStyle;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Screen tracking
    [[Analytics sharedInstance] trackScreen:@"ChatRoom"];
    
    // Refresh the room title view
    [self refreshRoomTitle];
    
    //  refresh remove Jitsi widget view
    [self refreshRemoveJitsiWidgetView];
    
    // Refresh tool bar if the room data source is set.
    if (self.roomDataSource)
    {
        [self refreshRoomInputToolbar];
    }
    
    // Reset typing notification in order to remove the allocated space
    if ([self.roomDataSource isKindOfClass:RoomDataSource.class])
    {
        [((RoomDataSource*)self.roomDataSource) resetTypingNotification];
    }

    [self listenTypingNotifications];
    [self listenCallNotifications];
    [self listenWidgetNotifications];
    [self listenTombstoneEventNotifications];
    [self listenMXSessionStateChangeNotifications];
    
    MXWeakify(self);
    
    // Observe kAppDelegateDidTapStatusBarNotification.
    kAppDelegateDidTapStatusBarNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kAppDelegateDidTapStatusBarNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXStrongifyAndReturnIfNil(self);
        
        [self setBubbleTableViewContentOffset:CGPointMake(-self.bubblesTableView.adjustedContentInset.left, -self.bubblesTableView.adjustedContentInset.top) animated:YES];
    }];
    
    if ([self.roomDataSource.roomId isEqualToString:[LegacyAppDelegate theDelegate].lastNavigatedRoomIdFromPush])
    {
        [self startActivityIndicator];
        [self.roomDataSource reload];
        [LegacyAppDelegate theDelegate].lastNavigatedRoomIdFromPush = nil;
        
        notificationTaskProfile = [MXSDKOptions.sharedInstance.profiler startMeasuringTaskWithName:AnalyticsNoficationsTimeToDisplayContent
                                                                                          category:AnalyticsNoficationsCategory];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // hide action
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
    
    [self removeTypingNotificationsListener];
    
    if (customizedRoomDataSource)
    {
        // Cancel potential selected event (to leave edition mode)
        if (customizedRoomDataSource.selectedEventId)
        {
            [self cancelEventSelection];
        }
    }
    
    // Hide preview header to restore navigation bar settings
    [self showPreviewHeader:NO];
    
    if (kAppDelegateDidTapStatusBarNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kAppDelegateDidTapStatusBarNotificationObserver];
        kAppDelegateDidTapStatusBarNotificationObserver = nil;
    }
    
    [self removeCallNotificationsListeners];
    [self removeWidgetNotificationsListeners];
    [self removeTombstoneEventNotificationsListener];
    [self removeMXSessionStateChangeNotificationsListener];
    
    // Re-enable the read marker display, and disable its update.
    self.roomDataSource.showReadMarker = YES;
    self.updateRoomReadMarker = NO;
    isAppeared = NO;
    
    [VoiceMessageMediaServiceProvider.sharedProvider pauseAllServices];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    isAppeared = YES;
    [self checkReadMarkerVisibility];
    
    if (self.roomDataSource)
    {
        // Set visible room id
        [AppDelegate theDelegate].visibleRoomId = self.roomDataSource.roomId;
    }
    
    MXWeakify(self);
    
    // Observe network reachability
    kAppDelegateNetworkStatusDidChangeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kAppDelegateNetworkStatusDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXStrongifyAndReturnIfNil(self);
        
        [self refreshActivitiesViewDisplay];
        
    }];
    [self refreshActivitiesViewDisplay];
    [self refreshJumpToLastUnreadBannerDisplay];
    
    // Observe missed notifications
    mxRoomSummaryDidChangeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXRoomSummaryDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXStrongifyAndReturnIfNil(self);
        
        MXRoomSummary *roomSummary = notif.object;
        
        if ([roomSummary.roomId isEqualToString:self.roomDataSource.roomId])
        {
            [self refreshMissedDiscussionsCount:NO];
        }
    }];
    [self refreshMissedDiscussionsCount:YES];
    self.keyboardHeight = MAX(self.keyboardHeight, 0);
    
    if (hasJitsiCall &&
        !self.isRoomHavingAJitsiCall)
    {
        //  the room had a Jitsi call before, but not now
        hasJitsiCall = NO;
        [self reloadBubblesTable:YES];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // Hide contextual menu if needed
    [self hideContextualMenuAnimated:NO];
    
    // Reset visible room id
    [AppDelegate theDelegate].visibleRoomId = nil;
    
    if (kAppDelegateNetworkStatusDidChangeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kAppDelegateNetworkStatusDidChangeNotificationObserver];
        kAppDelegateNetworkStatusDidChangeNotificationObserver = nil;
    }
    
    if (mxRoomSummaryDidChangeObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:mxRoomSummaryDidChangeObserver];
        mxRoomSummaryDidChangeObserver = nil;
    }
    
    if (mxEventDidDecryptNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:mxEventDidDecryptNotificationObserver];
        mxEventDidDecryptNotificationObserver = nil;
    }
        
    if (self.isRoomHavingAJitsiCall)
    {
        hasJitsiCall = YES;
        [self reloadBubblesTable:YES];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    UIEdgeInsets contentInset = self.bubblesTableView.contentInset;
    contentInset.bottom = self.view.safeAreaInsets.bottom;
    self.bubblesTableView.contentInset = contentInset;
    
    // Check here whether a subview has been added or removed
    if (encryptionInfoView)
    {
        if (!encryptionInfoView.superview)
        {
            // Reset
            encryptionInfoView = nil;
            
            // Reload the full table to take into account a potential change on a device status.
            [self.bubblesTableView reloadData];
        }
    }
    
    if (eventDetailsView)
    {
        if (!eventDetailsView.superview)
        {
            // Reset
            eventDetailsView = nil;
        }
    }
    
    // Check whether the preview header is visible
    if (previewHeader)
    {
        if (previewHeader.mainHeaderContainer.isHidden)
        {
            // Check here the main background height to display a correct navigation bar background.
            CGRect frame = self.navigationController.navigationBar.frame;
            
            CGFloat mainHeaderBackgroundHeight = frame.size.height + (frame.origin.y > 0 ? frame.origin.y : 0);
            
            if (previewHeader.mainHeaderBackgroundHeightConstraint.constant != mainHeaderBackgroundHeight)
            {
                previewHeader.mainHeaderBackgroundHeightConstraint.constant = mainHeaderBackgroundHeight;
                
                // Force the layout of previewHeader to update the position of 'bottomBorderView' which
                // is used to define the actual height of the preview container.
                [previewHeader layoutIfNeeded];
            }
        }
        
        self.edgesForExtendedLayout = UIRectEdgeAll;
        
        // Adjust the top constraint of the bubbles table
        CGRect frame = previewHeader.bottomBorderView.frame;
        self.previewHeaderContainerHeightConstraint.constant = frame.origin.y + frame.size.height;
        
        self.bubblesTableViewTopConstraint.constant = self.previewHeaderContainerHeightConstraint.constant - self.bubblesTableView.adjustedContentInset.top;
    }
    else
    {
        // In non expanded header mode, the navigation bar is opaque
        // The table view must not display behind it
        self.edgesForExtendedLayout = UIRectEdgeLeft | UIRectEdgeBottom | UIRectEdgeRight;
    }
    
    //  stay at the bottom if already was
    if (self.isBubblesTableScrollViewAtTheBottom)
    {
        [self scrollBubblesTableViewToBottomAnimated:NO];
    }
    
    [self refreshMissedDiscussionsCount:YES];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    if ([self.titleView isKindOfClass:RoomTitleView.class])
    {
        RoomTitleView *roomTitleView = (RoomTitleView*)self.titleView;
        if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation))
        {
            [roomTitleView updateLayoutForOrientation:UIInterfaceOrientationPortrait];
        }
        else
        {
            [roomTitleView updateLayoutForOrientation:UIInterfaceOrientationLandscapeLeft];
        }
    }

    // Hide the expanded header or the preview in case of iPad and iPhone 6 plus.
    // On these devices, the display mode of the splitviewcontroller may change during screen rotation.
    // It may correspond to an overlay mode in portrait and a side-by-side mode in landscape.
    // This display mode change involves a change at the navigation bar level.
    // If we don't hide the header, the navigation bar is in a wrong state after rotation. FIXME: Find a way to keep visible the header on rotation.
    if ([GBDeviceInfo deviceInfo].family == GBDeviceFamilyiPad || [GBDeviceInfo deviceInfo].displayInfo.display >= GBDeviceDisplay5p5Inch)
    {
        // Hide the preview header (if any) before rotating (It will be restored by `refreshRoomTitle` call if this is still a room preview).
        [self showPreviewHeader:NO];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((coordinator.transitionDuration + 0.5) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            // Let [self refreshRoomTitle] refresh this title view correctly
            [self refreshRoomTitle];
            
        });
    }
    else if (previewHeader)
    {
        // Refresh here the preview header according to the coming screen orientation.
        
        // Retrieve the affine transform indicating the amount of rotation being applied to the interface.
        // This transform is the identity transform when no rotation is applied.
        // Otherwise, it is a transform that applies a 90 degree, -90 degree, or 180 degree rotation.
        CGAffineTransform transform = coordinator.targetTransform;
        
        // Consider here only the transform that applies a +/- 90 degree.
        if (transform.b * transform.c == -1)
        {
            UIInterfaceOrientation currentScreenOrientation = [[UIApplication sharedApplication] statusBarOrientation];
            BOOL isLandscapeOriented = YES;
            
            switch (currentScreenOrientation)
            {
                case UIInterfaceOrientationLandscapeRight:
                case UIInterfaceOrientationLandscapeLeft:
                {
                    // We leave here landscape orientation
                    isLandscapeOriented = NO;
                    break;
                }
                default:
                    break;
            }
            
            [self refreshPreviewHeader:isLandscapeOriented];
        }
    }
    else
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((coordinator.transitionDuration + 0.5) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            // Refresh the room title at the end of the transition to take into account the potential changes during the transition.
            // For example the display of a preview header is ignored during transition.
            [self refreshRoomTitle];
            
        });
    }
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

#pragma mark - Accessibility

// Handle scrolling when VoiceOver is on because it does not work well if we let the system do:
// VoiceOver loses the focus on the tableview
- (BOOL)accessibilityScroll:(UIAccessibilityScrollDirection)direction
{
    BOOL canScroll = YES;
    
    // Scroll by one page
    CGFloat tableViewHeight = self.bubblesTableView.frame.size.height;
    
    CGPoint offset = self.bubblesTableView.contentOffset;
    switch (direction)
    {
        case UIAccessibilityScrollDirectionUp:
            offset.y -= tableViewHeight;
            break;
            
        case UIAccessibilityScrollDirectionDown:
            offset.y += tableViewHeight;
            break;
            
        default:
            break;
    }
    
    if (offset.y < 0 && ![self.roomDataSource.timeline canPaginate:MXTimelineDirectionBackwards])
    {
        // Can't paginate more. Let's stick on the first item
        UIView *focusedView = [self firstCellWithAccessibilityDataInCells:self.bubblesTableView.visibleCells.objectEnumerator];
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, focusedView);
        canScroll = NO;
    }
    else if (offset.y > self.bubblesTableView.contentSize.height - tableViewHeight
             && ![self.roomDataSource.timeline canPaginate:MXTimelineDirectionForwards])
    {
        // Can't paginate more. Let's stick on the last item with accessibility
        UIView *focusedView = [self firstCellWithAccessibilityDataInCells:self.bubblesTableView.visibleCells.reverseObjectEnumerator];
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, focusedView);
        canScroll = NO;
    }
    else
    {
        // Disable VoiceOver while scrolling
        self.bubblesTableView.accessibilityElementsHidden = YES;
        
        [self setBubbleTableViewContentOffset:offset animated:NO];
        
        NSEnumerator<UITableViewCell*> *cells;
        if (direction == UIAccessibilityScrollDirectionUp)
        {
            cells = self.bubblesTableView.visibleCells.objectEnumerator;
        }
        else
        {
            cells = self.bubblesTableView.visibleCells.reverseObjectEnumerator;
        }
        UIView *cell = [self firstCellWithAccessibilityDataInCells:cells];
        
        self.bubblesTableView.accessibilityElementsHidden = NO;
        
        // Force VoiceOver to focus on a visible item
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, cell);
    }
    
    // If we cannot scroll, let VoiceOver indicates the border
    return canScroll;
}

- (UIView*)firstCellWithAccessibilityDataInCells:(NSEnumerator<UITableViewCell*>*)cells
{
    UIView *view;
    
    for (UITableViewCell *cell in cells)
    {
        if (![cell isKindOfClass:[RoomEmptyBubbleCell class]])
        {
            view = cell;
            break;
        }
    }
    
    return view;
}


#pragma mark - Override MXKRoomViewController

- (void)onMatrixSessionChange
{
    [super onMatrixSessionChange];
    
    // Re-enable the read marker display, and disable its update.
    self.roomDataSource.showReadMarker = YES;
    self.updateRoomReadMarker = NO;
}

- (void)stopActivityIndicator
{
    if (notificationTaskProfile)
    {
        // Consider here we have displayed the message corresponding to the notification
        [MXSDKOptions.sharedInstance.profiler stopMeasuringTaskWithProfile:notificationTaskProfile];
        notificationTaskProfile = nil;
    }
    
    [super stopActivityIndicator];
}

- (void)displayRoom:(MXKRoomDataSource *)dataSource
{
    // Remove potential preview Data
    if (roomPreviewData)
    {
        roomPreviewData = nil;
        [self removeMatrixSession:self.mainSession];
    }
    
    // Enable the read marker display, and disable its update.
    dataSource.showReadMarker = YES;
    self.updateRoomReadMarker = NO;
    
    [super displayRoom:dataSource];
    
    customizedRoomDataSource = nil;
    
    if (self.roomDataSource)
    {
        [self listenToServerNotices];
        
        self.eventsAcknowledgementEnabled = YES;
        
        // Store ref on customized room data source
        if ([dataSource isKindOfClass:RoomDataSource.class])
        {
            customizedRoomDataSource = (RoomDataSource*)dataSource;
        }
        
        // Set room title view
        [self refreshRoomTitle];
    }
    else
    {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    
    [self refreshRoomInputToolbar];
    
    [VoiceMessageMediaServiceProvider.sharedProvider setCurrentRoomSummary:dataSource.room.summary];
    _voiceMessageController.roomId = dataSource.roomId;
    
    _userSuggestionCoordinator = [[UserSuggestionCoordinatorBridge alloc] initWithMediaManager:self.roomDataSource.mxSession.mediaManager
                                                                                          room:dataSource.room];
    _userSuggestionCoordinator.delegate = self;
    
    [self setupUserSuggestionView];
}

- (void)onRoomDataSourceReady
{
    // Handle here invitation
    if (self.roomDataSource.room.summary.membership == MXMembershipInvite)
    {
        self.navigationItem.rightBarButtonItem.enabled = NO;
        
        // Show preview header
        [self showPreviewHeader:YES];
    }
    else
    {
        [super onRoomDataSourceReady];
    }
}

- (void)updateViewControllerAppearanceOnRoomDataSourceState
{
    [super updateViewControllerAppearanceOnRoomDataSourceState];
    
    if (self.isRoomPreview)
    {
        self.navigationItem.rightBarButtonItem.enabled = NO;
        
        // Remove input tool bar if any
        if (self.inputToolbarView)
        {
            [super setRoomInputToolbarViewClass:nil];
        }
        
        if (previewHeader)
        {
            previewHeader.mxRoom = self.roomDataSource.room;
            
            // Force the layout of subviews (some constraints may have been updated)
            [self forceLayoutRefresh];
        }
    }
    else
    {
        [self showPreviewHeader:NO];
        
        self.navigationItem.rightBarButtonItem.enabled = (self.roomDataSource != nil);
        
        self.titleView.editable = NO;
        
        if (self.roomDataSource)
        {
            // Update the input toolbar class and update the layout
            [self updateRoomInputToolbarViewClassIfNeeded];
            
            self.inputToolbarView.hidden = (self.roomDataSource.state != MXKDataSourceStateReady);
            
            // Restore room activities view if none
            if (!self.activitiesView)
            {
                // And the extra area
                [self setRoomActivitiesViewClass:RoomActivitiesView.class];
            }
        }
    }
}

- (void)leaveRoomOnEvent:(MXEvent*)event
{
    // Force a simple title view initialised with the current room before leaving actually the room.
    [self setRoomTitleViewClass:SimpleRoomTitleView.class];
    self.titleView.editable = NO;
    self.titleView.mxRoom = self.roomDataSource.room;
    
    // Hide the potential read marker banner.
    self.jumpToLastUnreadBannerContainer.hidden = YES;
    
    [super leaveRoomOnEvent:event];
    
    if (self.delegate)
    {
        [self.delegate roomViewControllerDidLeaveRoom:self];
    }
    else
    {
        [[AppDelegate theDelegate] restoreInitialDisplay:nil];
    }
}

// Set the input toolbar according to the current display
- (void)updateRoomInputToolbarViewClassIfNeeded
{
    Class roomInputToolbarViewClass = RoomInputToolbarView.class;
    
    BOOL shouldDismissContextualMenu = NO;
    
    // Check the user has enough power to post message
    if (self.roomDataSource.roomState)
    {
        MXRoomPowerLevels *powerLevels = self.roomDataSource.roomState.powerLevels;
        NSInteger userPowerLevel = [powerLevels powerLevelOfUserWithUserID:self.mainSession.myUser.userId];
        
        BOOL canSend = (userPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsMessage:kMXEventTypeStringRoomMessage]);
        BOOL isRoomObsolete = self.roomDataSource.roomState.isObsolete;
        BOOL isResourceLimitExceeded = [self.roomDataSource.mxSession.syncError.errcode isEqualToString:kMXErrCodeStringResourceLimitExceeded];
        
        if (isRoomObsolete || isResourceLimitExceeded)
        {
            roomInputToolbarViewClass = nil;
            shouldDismissContextualMenu = YES;
        }
        else if (!canSend)
        {
            roomInputToolbarViewClass = DisabledRoomInputToolbarView.class;
            shouldDismissContextualMenu = YES;
        }
    }
    
    // Do not show toolbar in case of preview
    if (self.isRoomPreview)
    {
        roomInputToolbarViewClass = nil;
        shouldDismissContextualMenu = YES;
    }
    
    if (shouldDismissContextualMenu)
    {
        [self hideContextualMenuAnimated:NO];
    }
    
    // Change inputToolbarView class only if given class is different from current one
    if (!self.inputToolbarView || ![self.inputToolbarView isMemberOfClass:roomInputToolbarViewClass])
    {
        [super setRoomInputToolbarViewClass:roomInputToolbarViewClass];
        
        // The voice message toolbar cannot be set on DisabledInputToolbarView.
        if ([self.inputToolbarView isKindOfClass:RoomInputToolbarView.class])
        {
            [(RoomInputToolbarView *)self.inputToolbarView setVoiceMessageToolbarView:self.voiceMessageController.voiceMessageToolbarView];
        }
        
        [self updateInputToolBarViewHeight];
        [self refreshRoomInputToolbar];
    }
}

// Get the height of the current room input toolbar
- (CGFloat)inputToolbarHeight
{
    CGFloat height = 0;
    
    if ([self.inputToolbarView isKindOfClass:RoomInputToolbarView.class])
    {
        height = ((RoomInputToolbarView*)self.inputToolbarView).mainToolbarHeightConstraint.constant;
    }
    else if ([self.inputToolbarView isKindOfClass:DisabledRoomInputToolbarView.class])
    {
        height = ((DisabledRoomInputToolbarView*)self.inputToolbarView).mainToolbarMinHeightConstraint.constant;
    }
    
    return height;
}

- (void)setRoomActivitiesViewClass:(Class)roomActivitiesViewClass
{
    // Do not show room activities in case of preview (FIXME: show it when live events will be supported during peeking)
    if (self.isRoomPreview)
    {
        roomActivitiesViewClass = nil;
    }
    
    [super setRoomActivitiesViewClass:roomActivitiesViewClass];
    
    if (!self.isActivitiesViewExpanded)
    {
        self.roomActivitiesContainerHeightConstraint.constant = 0;
    }
}

- (BOOL)isIRCStyleCommand:(NSString*)string
{
    // Override the default behavior for `/join` command in order to open automatically the joined room
    
    if ([string hasPrefix:kMXKSlashCmdJoinRoom])
    {
        // Join a room
        NSString *roomAlias;
        
        // Sanity check
        if (string.length > kMXKSlashCmdJoinRoom.length)
        {
            roomAlias = [string substringFromIndex:kMXKSlashCmdJoinRoom.length + 1];
            
            // Remove white space from both ends
            roomAlias = [roomAlias stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        }
        
        // Check
        if (roomAlias.length)
        {
            // TODO: /join command does not support via parameters yet
            [self.mainSession joinRoom:roomAlias viaServers:nil success:^(MXRoom *room) {
                                
                [self showRoomWithId:room.roomId];
                
            } failure:^(NSError *error) {
                
                MXLogDebug(@"[RoomVC] Join roomAlias (%@) failed", roomAlias);
                //Alert user
                [self showError:error];
                
            }];
        }
        else
        {
            // Display cmd usage in text input as placeholder
            self.inputToolbarView.placeholder = @"Usage: /join <room_alias>";
        }
        return YES;
    }
    return [super isIRCStyleCommand:string];
}

- (void)setKeyboardHeight:(CGFloat)keyboardHeight
{
    [super setKeyboardHeight:keyboardHeight];

    self.inputToolbarView.maxHeight = round(([UIScreen mainScreen].bounds.size.height - keyboardHeight) * 0.7);

    // Make the activity indicator follow the keyboard
    // At runtime, this creates a smooth animation
    CGPoint activityIndicatorCenter = self.activityIndicator.center;
    activityIndicatorCenter.y = self.view.center.y - keyboardHeight / 2;
    self.activityIndicator.center = activityIndicatorCenter;
}

- (void)dismissTemporarySubViews
{
    [super dismissTemporarySubViews];
    
    if (encryptionInfoView)
    {
        [encryptionInfoView removeFromSuperview];
        encryptionInfoView = nil;
    }
}

- (void)setBubbleTableViewDisplayInTransition:(BOOL)bubbleTableViewDisplayInTransition
{
    if (self.isBubbleTableViewDisplayInTransition != bubbleTableViewDisplayInTransition)
    {
        [super setBubbleTableViewDisplayInTransition:bubbleTableViewDisplayInTransition];
        
        // Refresh additional displays when the table is ready.
        if (!bubbleTableViewDisplayInTransition && !self.bubblesTableView.isHidden)
        {
            [self refreshActivitiesViewDisplay];
            
            [self checkReadMarkerVisibility];
            [self refreshJumpToLastUnreadBannerDisplay];
        }
    }
}

- (void)sendTextMessage:(NSString*)msgTxt
{
    if (self.inputToolBarSendMode == RoomInputToolbarViewSendModeReply && customizedRoomDataSource.selectedEventId)
    {
        [self.roomDataSource sendReplyToEventWithId:customizedRoomDataSource.selectedEventId withTextMessage:msgTxt success:nil failure:^(NSError *error) {
            // Just log the error. The message will be displayed in red in the room history
            MXLogDebug(@"[MXKRoomViewController] sendTextMessage failed.");
        }];
    }
    else if (self.inputToolBarSendMode == RoomInputToolbarViewSendModeEdit && customizedRoomDataSource.selectedEventId)
    {
        [self.roomDataSource replaceTextMessageForEventWithId:customizedRoomDataSource.selectedEventId withTextMessage:msgTxt success:nil failure:^(NSError *error) {
            // Just log the error. The message will be displayed in red
            MXLogDebug(@"[MXKRoomViewController] sendTextMessage failed.");
        }];
    }
    else
    {
        // Let the datasource send it and manage the local echo
        [self.roomDataSource sendTextMessage:msgTxt success:nil failure:^(NSError *error)
         {
            // Just log the error. The message will be displayed in red in the room history
            MXLogDebug(@"[MXKRoomViewController] sendTextMessage failed.");
        }];
    }
    
    if (customizedRoomDataSource.selectedEventId)
    {
        [self cancelEventSelection];
    }
}

- (void)setRoomTitleViewClass:(Class)roomTitleViewClass
{
    // Sanity check: accept only MXKRoomTitleView classes or sub-classes
    NSParameterAssert([roomTitleViewClass isSubclassOfClass:MXKRoomTitleView.class]);
    
    MXKRoomTitleView *titleView = [roomTitleViewClass roomTitleView];
    [self setValue:titleView forKey:@"titleView"];
    titleView.delegate = self;
    titleView.mxRoom = self.roomDataSource.room;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:titleView];
    
    if ([titleView isKindOfClass:RoomTitleView.class])
    {
        RoomTitleView *roomTitleView = (RoomTitleView*)self.titleView;
        missedDiscussionsBadgeLabel = roomTitleView.missedDiscussionsBadgeLabel;
        missedDiscussionsDotView = roomTitleView.dotView;
        [roomTitleView updateLayoutForOrientation:[UIApplication sharedApplication].statusBarOrientation];
    }

    [self updateViewControllerAppearanceOnRoomDataSourceState];
    
    [self updateTitleViewEncryptionDecoration];
}

- (void)destroy
{
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
    
    if (customizedRoomDataSource)
    {
        customizedRoomDataSource.selectedEventId = nil;
        customizedRoomDataSource = nil;
    }
    
    [self removeTypingNotificationsListener];
    
    if (kThemeServiceDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kThemeServiceDidChangeThemeNotificationObserver];
        kThemeServiceDidChangeThemeNotificationObserver = nil;
    }
    if (kAppDelegateDidTapStatusBarNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kAppDelegateDidTapStatusBarNotificationObserver];
        kAppDelegateDidTapStatusBarNotificationObserver = nil;
    }
    if (kAppDelegateNetworkStatusDidChangeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kAppDelegateNetworkStatusDidChangeNotificationObserver];
        kAppDelegateNetworkStatusDidChangeNotificationObserver = nil;
    }
    if (mxRoomSummaryDidChangeObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:mxRoomSummaryDidChangeObserver];
        mxRoomSummaryDidChangeObserver = nil;
    }
    if (mxEventDidDecryptNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:mxEventDidDecryptNotificationObserver];
        mxEventDidDecryptNotificationObserver = nil;
    }
    if (URLPreviewDidUpdateNotificationObserver)
    {
        [NSNotificationCenter.defaultCenter removeObserver:URLPreviewDidUpdateNotificationObserver];        
    }
    
    [self removeCallNotificationsListeners];
    [self removeWidgetNotificationsListeners];
    [self removeTombstoneEventNotificationsListener];
    [self removeMXSessionStateChangeNotificationsListener];
    [self removeServerNoticesListener];
    
    if (previewHeader)
    {
        // Here [destroy] is called before [viewWillDisappear:]
        MXLogDebug(@"[RoomVC] destroyed whereas it is still visible");
        
        [previewHeader removeFromSuperview];
        previewHeader = nil;
        
        // Hide preview header container to ignore [self showPreviewHeader:NO] call (if any).
        self.previewHeaderContainer.hidden = YES;
    }
    
    roomPreviewData = nil;
    
    missedDiscussionsBadgeLabel = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXEventDidChangeSentStateNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXEventDidChangeIdentifierNotification object:nil];
    
    [super destroy];
}

#pragma mark - Properties

-(void)setActivitiesViewExpanded:(BOOL)activitiesViewExpanded
{
    if (_activitiesViewExpanded != activitiesViewExpanded)
    {
        _activitiesViewExpanded = activitiesViewExpanded;
        
        self.roomActivitiesContainerHeightConstraint.constant = activitiesViewExpanded ? 53 : 0;
        [super roomInputToolbarView:self.inputToolbarView heightDidChanged:[self inputToolbarHeight] completion:nil];
    }
}

- (void)setScrollToBottomHidden:(BOOL)scrollToBottomHidden
{
    if (_scrollToBottomHidden != scrollToBottomHidden)
    {
        _scrollToBottomHidden = scrollToBottomHidden;
    }
    
    if (!_scrollToBottomHidden && [self.roomDataSource isKindOfClass:RoomDataSource.class])
    {
        RoomDataSource *roomDataSource = (RoomDataSource *) self.roomDataSource;
        if (roomDataSource.currentTypingUsers && !roomDataSource.currentTypingUsers.count)
        {
            [roomDataSource resetTypingNotification];
            [self.bubblesTableView reloadData];
        }
    }

    [UIView animateWithDuration:.2 animations:^{
        self.scrollToBottomBadgeLabel.alpha = (scrollToBottomHidden || !self.scrollToBottomBadgeLabel.text) ? 0 : 1;
        self.scrollToBottomButton.alpha = scrollToBottomHidden ? 0 : 1;
    }];
}

- (void)setMissedDiscussionsBadgeHidden:(BOOL)missedDiscussionsBadgeHidden{
    _missedDiscussionsBadgeHidden = missedDiscussionsBadgeHidden;
    
    missedDiscussionsBadgeLabel.hidden = missedDiscussionsBadgeHidden;
    missedDiscussionsDotView.hidden = missedDiscussionsBadgeHidden;
}

#pragma mark - Internals

- (UIBarButtonItem *)videoCallBarButtonItem
{
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"video_call"]
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(onVideoCallPressed:)];
    item.accessibilityLabel = [VectorL10n roomAccessibilityVideoCall];
    
    return item;
}

- (void)setupRemoveJitsiWidgetRemoveView
{
    self.removeJitsiWidgetView = [RemoveJitsiWidgetView instantiate];
    self.removeJitsiWidgetView.delegate = self;
    
    [self.removeJitsiWidgetContainer vc_addSubViewMatchingParent:self.removeJitsiWidgetView];
    
    self.removeJitsiWidgetContainer.hidden = YES;
    
    [self refreshRemoveJitsiWidgetView];
}

- (void)forceLayoutRefresh
{
    // Sanity check: check whether the table view data source is set.
    if (self.bubblesTableView.dataSource)
    {
        [self.view layoutIfNeeded];
    }
}

- (BOOL)isRoomPreview
{
    // Check first whether some preview data are defined.
    if (roomPreviewData)
    {
        return YES;
    }
    
    if (self.roomDataSource && self.roomDataSource.state == MXKDataSourceStateReady && self.roomDataSource.room.summary.membership == MXMembershipInvite)
    {
        return YES;
    }
    
    return NO;
}

- (BOOL)isEncryptionEnabled
{
    return self.roomDataSource.room.summary.isEncrypted && self.mainSession.crypto != nil;
}

- (BOOL)supportCallOption
{
    BOOL callOptionAllowed = (self.roomDataSource.room.isDirect && RiotSettings.shared.roomScreenAllowVoIPForDirectRoom) || (!self.roomDataSource.room.isDirect && RiotSettings.shared.roomScreenAllowVoIPForNonDirectRoom);
    return callOptionAllowed && BuildSettings.allowVoIPUsage && self.roomDataSource.mxSession.callManager && self.roomDataSource.room.summary.membersCount.joined >= 2;
}

- (BOOL)isCallActive
{
    MXCall *callInRoom = [self.roomDataSource.mxSession.callManager callInRoom:self.roomDataSource.roomId];
    
    return (callInRoom && callInRoom.state != MXCallStateEnded)
    || customizedRoomDataSource.jitsiWidget;
}

/**
 Returns a flag for the current user whether it's privileged to add/remove Jitsi widgets to this room.
 */
- (BOOL)canEditJitsiWidget
{
    MXRoomPowerLevels *powerLevels = [self.roomDataSource.roomState powerLevels];
    NSInteger requiredPower = [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kWidgetModularEventTypeString];
    NSInteger myPower = [powerLevels powerLevelOfUserWithUserID:self.roomDataSource.mxSession.myUserId];
    return myPower >= requiredPower;
}

- (void)registerURLPreviewNotifications
{
    MXWeakify(self);
    
    URLPreviewDidUpdateNotificationObserver = [NSNotificationCenter.defaultCenter addObserverForName:URLPreviewDidUpdateNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull notification) {
        
        MXStrongifyAndReturnIfNil(self);        
        
        // Ensure this is the correct room
        if (![(NSString*)notification.userInfo[@"roomId"] isEqualToString:self.roomDataSource.roomId])
        {
            return;
        }
        
        // Get the indexPath for the updated cell.
        NSString *updatedEventId = notification.userInfo[@"eventId"];
        NSInteger updatedEventIndex = [self.roomDataSource indexOfCellDataWithEventId:updatedEventId];
        NSIndexPath *updatedIndexPath = [NSIndexPath indexPathForRow:updatedEventIndex inSection:0];
        
        // Store the content size and offset before reloading the cell
        CGFloat originalContentSize = self.bubblesTableView.contentSize.height;
        CGPoint contentOffset = self.bubblesTableView.contentOffset;
        
        // Only update the content offset if the cell is visible or above the current visible cells.
        BOOL shouldUpdateContentOffset = NO;
        NSIndexPath *lastVisibleIndexPath = [self.bubblesTableView indexPathsForVisibleRows].lastObject;
        if (lastVisibleIndexPath && updatedIndexPath.row < lastVisibleIndexPath.row)
        {
            shouldUpdateContentOffset = YES;
        }
        
        // Note: Despite passing in the index path, this reloads the whole table.
        [self dataSource:self.roomDataSource didCellChange:updatedIndexPath];
        
        // Update the content offset to include any changes to the scroll view's height.
        if (shouldUpdateContentOffset)
        {
            CGFloat delta = self.bubblesTableView.contentSize.height - originalContentSize;
            contentOffset.y += delta;
            
            self.bubblesTableView.contentOffset = contentOffset;
        }
    }];
}

- (void)refreshRoomTitle
{
    NSMutableArray *rightBarButtonItems = nil;
    
    // Set the right room title view
    if (self.isRoomPreview)
    {
        [self showPreviewHeader:YES];
    }
    else if (self.roomDataSource)
    {
        [self showPreviewHeader:NO];
        
        if (self.roomDataSource.isLive)
        {
            rightBarButtonItems = [NSMutableArray new];
            BOOL hasCustomJoinButton = NO;
            
            if (self.supportCallOption)
            {
                if (self.roomDataSource.room.summary.membersCount.joined == 2 && self.roomDataSource.room.isDirect)
                {
                    //  voice call button for Matrix call
                    UIBarButtonItem *itemVoice = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"voice_call_hangon_icon"]
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(onVoiceCallPressed:)];
                    itemVoice.accessibilityLabel = [VectorL10n roomAccessibilityCall];
                    itemVoice.enabled = !self.isCallActive;
                    [rightBarButtonItems addObject:itemVoice];
                    
                    //  video call button for Matrix call
                    UIBarButtonItem *itemVideo = [self videoCallBarButtonItem];
                    itemVideo.enabled = !self.isCallActive;
                    [rightBarButtonItems addObject:itemVideo];
                }
                else
                {
                    //  video call button for Jitsi call
                    if (self.isCallActive)
                    {
                        if (self.isRoomHavingAJitsiCall)
                        {
                            //  show a disabled call button
                            UIBarButtonItem *item = [self videoCallBarButtonItem];
                            item.enabled = NO;
                            [rightBarButtonItems addObject:item];
                        }
                        else
                        {
                            //  show Join button
                            CallTileActionButton *button = [CallTileActionButton new];
                            [button setImage:[UIImage imageNamed:@"call_video_icon"]
                                    forState:UIControlStateNormal];
                            [button setTitle:[VectorL10n roomJoinGroupCall]
                                    forState:UIControlStateNormal];
                            [button addTarget:self
                                       action:@selector(onVideoCallPressed:)
                             forControlEvents:UIControlEventTouchUpInside];
                            button.contentEdgeInsets = UIEdgeInsetsMake(4, 12, 4, 12);
                            UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:button];
                            item.accessibilityLabel = [VectorL10n roomAccessibilityVideoCall];
                            [rightBarButtonItems addObject:item];
                            
                            hasCustomJoinButton = YES;
                        }
                    }
                    else
                    {
                        //  show a video call button
                        //  item will still be enabled, and when tapped an alert will be displayed to the user
                        UIBarButtonItem *item = [self videoCallBarButtonItem];
                        if (!self.canEditJitsiWidget)
                        {
                            item.image = [[UIImage imageNamed:@"video_call"] vc_withAlpha:0.3];
                        }
                        [rightBarButtonItems addObject:item];
                    }
                }
            }
            
            if ([self widgetsCount:NO])
            {
                UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"integrations_icon"]
                                                                         style:UIBarButtonItemStylePlain
                                                                        target:self
                                                                        action:@selector(onIntegrationsPressed:)];
                item.accessibilityLabel = [VectorL10n roomAccessibilityIntegrations];
                if (hasCustomJoinButton)
                {
                    item.imageInsets = UIEdgeInsetsMake(0, -5, 0, -5);
                    item.landscapeImagePhoneInsets = UIEdgeInsetsMake(0, -5, 0, -5);
                }
                [rightBarButtonItems addObject:item];
            }
            
            // Do not change title view class here if the expanded header is visible.
            [self setRoomTitleViewClass:RoomTitleView.class];
            ((RoomTitleView*)self.titleView).tapGestureDelegate = self;
        }
        
        MXKImageView *userPictureView = ((RoomTitleView*)self.titleView).pictureView;
        
        // Set user picture in input toolbar
        if (userPictureView)
        {
            [self.roomDataSource.room.summary setRoomAvatarImageIn:userPictureView];
        }
        
        [self refreshMissedDiscussionsCount:YES];
    }
    
    self.navigationItem.rightBarButtonItems = rightBarButtonItems;
}

- (void)refreshRoomInputToolbar
{
    MXKImageView *userPictureView;
    
    // Check whether the input toolbar is ready before updating it.
    if (self.inputToolbarView && [self.inputToolbarView isKindOfClass:RoomInputToolbarView.class])
    {
        RoomInputToolbarView *roomInputToolbarView = (RoomInputToolbarView*)self.inputToolbarView;
        
        // Update encryption decoration if needed
        [self updateEncryptionDecorationForRoomInputToolbar:roomInputToolbarView];
    }
    else if (self.inputToolbarView && [self.inputToolbarView isKindOfClass:DisabledRoomInputToolbarView.class])
    {
        DisabledRoomInputToolbarView *roomInputToolbarView = (DisabledRoomInputToolbarView*)self.inputToolbarView;
        
        // Get user picture view in input toolbar
        userPictureView = roomInputToolbarView.pictureView;
        
        // For the moment, there is only one reason to use `DisabledRoomInputToolbarView`
        [roomInputToolbarView setDisabledReason:[VectorL10n roomDoNotHavePermissionToPost]];
    }
    
    // Set user picture in input toolbar
    if (userPictureView)
    {
        UIImage *preview = [AvatarGenerator generateAvatarForMatrixItem:self.mainSession.myUser.userId withDisplayName:self.mainSession.myUser.displayname];
        
        // Suppose the avatar is stored unencrypted on the Matrix media repository.
        userPictureView.enableInMemoryCache = YES;
        [userPictureView setImageURI:self.mainSession.myUser.avatarUrl
                            withType:nil
                 andImageOrientation:UIImageOrientationUp
                       toFitViewSize:userPictureView.frame.size
                          withMethod:MXThumbnailingMethodCrop
                        previewImage:preview
                        mediaManager:self.mainSession.mediaManager];
        [userPictureView.layer setCornerRadius:userPictureView.frame.size.width / 2];
        userPictureView.clipsToBounds = YES;
    }
}

- (void)setInputToolBarSendMode:(RoomInputToolbarViewSendMode)sendMode forEventWithId:(NSString *)eventId
{
    if (self.inputToolbarView && [self.inputToolbarView isKindOfClass:[RoomInputToolbarView class]])
    {
        RoomInputToolbarView *roomInputToolbarView = (RoomInputToolbarView*)self.inputToolbarView;
        if (eventId)
        {
            MXEvent *event = [self.roomDataSource eventWithEventId:eventId];
            MXRoomMember * roomMember = [self.roomDataSource.roomState.members memberWithUserId:event.sender];
            if (roomMember.displayname.length)
            {
                roomInputToolbarView.eventSenderDisplayName = roomMember.displayname;
            }
            else
            {
                roomInputToolbarView.eventSenderDisplayName = event.sender;
            }
        }
        else
        {
            roomInputToolbarView.eventSenderDisplayName = nil;
        }
        roomInputToolbarView.sendMode = sendMode;
    }
}

- (RoomInputToolbarViewSendMode)inputToolBarSendMode
{
    RoomInputToolbarViewSendMode sendMode = RoomInputToolbarViewSendModeSend;
    if (self.inputToolbarView && [self.inputToolbarView isKindOfClass:[RoomInputToolbarView class]])
    {
        RoomInputToolbarView *roomInputToolbarView = (RoomInputToolbarView*)self.inputToolbarView;
        sendMode = roomInputToolbarView.sendMode;
    }
    
    return sendMode;
}

- (void)onSwipeGesture:(UISwipeGestureRecognizer*)swipeGestureRecognizer
{
    UIView *view = swipeGestureRecognizer.view;
    
    if (view == self.activitiesView)
    {
        // Dismiss the keyboard when user swipes down on activities view.
        [self.inputToolbarView dismissKeyboard];
    }
}

- (void)updateInputToolBarViewHeight
{
    // Update the inputToolBar height.
    CGFloat height = [self inputToolbarHeight];
    // Disable animation during the update
    [UIView setAnimationsEnabled:NO];
    [self roomInputToolbarView:self.inputToolbarView heightDidChanged:height completion:nil];
    [UIView setAnimationsEnabled:YES];
}

- (UIImage*)roomEncryptionBadgeImage
{
    UIImage *encryptionIcon;
    
    if (self.isEncryptionEnabled)
    {
        RoomEncryptionTrustLevel roomEncryptionTrustLevel = ((RoomDataSource*)self.roomDataSource).encryptionTrustLevel;
        
        encryptionIcon = [EncryptionTrustLevelBadgeImageHelper roomBadgeImageFor:roomEncryptionTrustLevel];
    }
    
    return encryptionIcon;
}

- (void)updateInputToolbarEncryptionDecoration
{
    if (self.inputToolbarView && [self.inputToolbarView isKindOfClass:RoomInputToolbarView.class])
    {
        RoomInputToolbarView *roomInputToolbarView = (RoomInputToolbarView*)self.inputToolbarView;
        [self updateEncryptionDecorationForRoomInputToolbar:roomInputToolbarView];
    }
}

- (void)updateTitleViewEncryptionDecoration
{
    if (![self.titleView isKindOfClass:[RoomTitleView class]])
    {
        return;
    }
    
    RoomTitleView *roomTitleView = (RoomTitleView*)self.titleView;
    roomTitleView.badgeImageView.image = self.roomEncryptionBadgeImage;
}

- (void)updateEncryptionDecorationForRoomInputToolbar:(RoomInputToolbarView*)roomInputToolbarView
{
    roomInputToolbarView.isEncryptionEnabled = self.isEncryptionEnabled;
}

- (void)handleLongPressFromCell:(id<MXKCellRendering>)cell withTappedEvent:(MXEvent*)event
{
    if (event && !customizedRoomDataSource.selectedEventId)
    {
        [self showContextualMenuForEvent:event fromSingleTapGesture:NO cell:cell animated:YES];
    }
}

- (void)showReactionHistoryForEventId:(NSString*)eventId animated:(BOOL)animated
{
    if (self.reactionHistoryCoordinatorBridgePresenter.isPresenting)
    {
        return;
    }
    
    ReactionHistoryCoordinatorBridgePresenter *presenter = [[ReactionHistoryCoordinatorBridgePresenter alloc] initWithSession:self.mainSession roomId:self.roomDataSource.roomId eventId:eventId];
    presenter.delegate = self;
    
    [presenter presentFrom:self animated:animated];
    
    self.reactionHistoryCoordinatorBridgePresenter = presenter;
}

- (void)showCameraControllerAnimated:(BOOL)animated
{
    CameraPresenter *cameraPresenter = [CameraPresenter new];
    cameraPresenter.delegate = self;
    [cameraPresenter presentCameraFrom:self with:@[MXKUTI.image, MXKUTI.movie] animated:YES];
    
    self.cameraPresenter = cameraPresenter;
}


- (void)showMediaPickerAnimated:(BOOL)animated
{
    MediaPickerCoordinatorBridgePresenter *mediaPickerPresenter = [[MediaPickerCoordinatorBridgePresenter alloc] initWithSession:self.mainSession mediaUTIs:@[MXKUTI.image, MXKUTI.movie] allowsMultipleSelection:YES];
    mediaPickerPresenter.delegate = self;
    
    UIView *sourceView;
    
    RoomInputToolbarView *roomInputToolbarView = [self inputToolbarViewAsRoomInputToolbarView];
    
    if (roomInputToolbarView)
    {
        sourceView = roomInputToolbarView.attachMediaButton;
    }
    else
    {
        sourceView = self.inputToolbarView;
    }
    
    [mediaPickerPresenter presentFrom:self sourceView:sourceView sourceRect:sourceView.bounds animated:YES];
    
    self.mediaPickerPresenter = mediaPickerPresenter;
}

- (void)showRoomCreationModalWithBubbleData:(id<MXKRoomBubbleCellDataStoring>) bubbleData
{
    [self.roomCreationModalCoordinatorBridgePresenter dismissWithAnimated:NO completion:nil];
    
    self.roomCreationModalCoordinatorBridgePresenter = [[RoomCreationModalCoordinatorBridgePresenter alloc] initWithSession:self.mainSession bubbleData:bubbleData roomState:self.roomDataSource.roomState];
    self.roomCreationModalCoordinatorBridgePresenter.delegate = self;
    [self.roomCreationModalCoordinatorBridgePresenter presentFrom:self animated:YES];
}

- (void)showMemberDetails:(MXRoomMember *)member
{
    if (!member)
    {
        return;
    }
    RoomMemberDetailsViewController *memberViewController = [RoomMemberDetailsViewController roomMemberDetailsViewController];
    
    // Set delegate to handle action on member (start chat, mention)
    memberViewController.delegate = self;
    memberViewController.enableMention = (self.inputToolbarView != nil);
    memberViewController.enableVoipCall = NO;
    
    [memberViewController displayRoomMember:member withMatrixRoom:self.roomDataSource.room];
    
    [self.navigationController pushViewController:memberViewController animated:YES];
}

- (void)showRoomAvatarChange
{
    [self showRoomInfoWithInitialSection:RoomInfoSectionChangeAvatar];
}

- (void)showAddParticipants
{
    [self showRoomInfoWithInitialSection:RoomInfoSectionAddParticipants];
}

- (void)showRoomTopicChange
{
    [self showRoomInfoWithInitialSection:RoomInfoSectionChangeTopic];
}

- (void)showRoomInfo
{
    [self showRoomInfoWithInitialSection:RoomInfoSectionNone];
}

- (void)showRoomInfoWithInitialSection:(RoomInfoSection)roomInfoSection
{
    RoomInfoCoordinatorParameters *parameters = [[RoomInfoCoordinatorParameters alloc] initWithSession:self.roomDataSource.mxSession room:self.roomDataSource.room initialSection:roomInfoSection];
    
    self.roomInfoCoordinatorBridgePresenter = [[RoomInfoCoordinatorBridgePresenter alloc] initWithParameters:parameters];
    
    self.roomInfoCoordinatorBridgePresenter.delegate = self;
    [self.roomInfoCoordinatorBridgePresenter pushFrom:self.navigationController animated:YES];
}

- (void)setupActions {
    if (![self.inputToolbarView isKindOfClass:RoomInputToolbarView.class]) {
        return;
    }
    
    RoomInputToolbarView *roomInputView = ((RoomInputToolbarView *) self.inputToolbarView);
    MXWeakify(self);
    NSMutableArray *actionItems = [NSMutableArray new];
    if (RiotSettings.shared.roomScreenAllowMediaLibraryAction)
    {
        [actionItems addObject:[[RoomActionItem alloc] initWithImage:[UIImage imageNamed:@"action_media_library"] andAction:^{
            MXStrongifyAndReturnIfNil(self);
            if ([self.inputToolbarView isKindOfClass:RoomInputToolbarView.class]) {
                ((RoomInputToolbarView *) self.inputToolbarView).actionMenuOpened = NO;
            }
            [self showMediaPickerAnimated:YES];
        }]];
    }
    if (RiotSettings.shared.roomScreenAllowStickerAction)
    {
        [actionItems addObject:[[RoomActionItem alloc] initWithImage:[UIImage imageNamed:@"action_sticker"] andAction:^{
            MXStrongifyAndReturnIfNil(self);
            if ([self.inputToolbarView isKindOfClass:RoomInputToolbarView.class]) {
                ((RoomInputToolbarView *) self.inputToolbarView).actionMenuOpened = NO;
            }
            [self roomInputToolbarViewPresentStickerPicker];
        }]];
    }
    if (RiotSettings.shared.roomScreenAllowFilesAction)
    {
        [actionItems addObject:[[RoomActionItem alloc] initWithImage:[UIImage imageNamed:@"action_file"] andAction:^{
            MXStrongifyAndReturnIfNil(self);
            if ([self.inputToolbarView isKindOfClass:RoomInputToolbarView.class]) {
                ((RoomInputToolbarView *) self.inputToolbarView).actionMenuOpened = NO;
            }
            [self roomInputToolbarViewDidTapFileUpload];
        }]];
    }
    if (RiotSettings.shared.roomScreenAllowPollsAction)
    {
        [actionItems addObject:[[RoomActionItem alloc] initWithImage:[UIImage imageNamed:@"action_poll"] andAction:^{
            MXStrongifyAndReturnIfNil(self);
            if ([self.inputToolbarView isKindOfClass:RoomInputToolbarView.class]) {
                ((RoomInputToolbarView *) self.inputToolbarView).actionMenuOpened = NO;
            }
            [self.delegate roomViewControllerDidRequestPollCreationFormPresentation:self];
        }]];
    }
    if (RiotSettings.shared.roomScreenAllowCameraAction)
    {
        [actionItems addObject:[[RoomActionItem alloc] initWithImage:[UIImage imageNamed:@"action_camera"] andAction:^{
            MXStrongifyAndReturnIfNil(self);
            if ([self.inputToolbarView isKindOfClass:RoomInputToolbarView.class]) {
                ((RoomInputToolbarView *) self.inputToolbarView).actionMenuOpened = NO;
            }
            [self showCameraControllerAnimated:YES];
        }]];
    }
    roomInputView.actionsBar.actionItems = actionItems;
}

- (NSString *)textInputContextIdentifier
{
    return self.roomDataSource.roomId;
}

- (void)roomInputToolbarViewPresentStickerPicker
{
    // Search for the sticker picker widget in the user account
    Widget *widget = [[WidgetManager sharedManager] userWidgets:self.roomDataSource.mxSession ofTypes:@[kWidgetTypeStickerPicker]].firstObject;
    
    if (widget)
    {
        // Display the widget
        [widget widgetUrl:^(NSString * _Nonnull widgetUrl) {
            
            StickerPickerViewController *stickerPickerVC = [[StickerPickerViewController alloc] initWithUrl:widgetUrl forWidget:widget];
            
            stickerPickerVC.roomDataSource = self.roomDataSource;
            
            [self.navigationController pushViewController:stickerPickerVC animated:YES];
        } failure:^(NSError * _Nonnull error) {
            
            MXLogDebug(@"[RoomVC] Cannot display widget %@", widget);
            [self showError:error];
        }];
    }
    else
    {
        // The Sticker picker widget is not installed yet. Propose the user to install it
        MXWeakify(self);
        
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        
        NSString *alertMessage = [NSString stringWithFormat:@"%@\n%@",
                                  [VectorL10n widgetStickerPickerNoStickerpacksAlert],
                                  [VectorL10n widgetStickerPickerNoStickerpacksAlertAddNow]];
                                   
        UIAlertController *installPrompt = [UIAlertController alertControllerWithTitle:nil
                                                                               message:alertMessage
                                                                        preferredStyle:UIAlertControllerStyleAlert];
        
        [installPrompt addAction:[UIAlertAction actionWithTitle:[MatrixKitL10n no]
                                                          style:UIAlertActionStyleCancel
                                                        handler:^(UIAlertAction * action)
                                 {
            MXStrongifyAndReturnIfNil(self);
            self->currentAlert = nil;
            
        }]];
        
        [installPrompt addAction:[UIAlertAction actionWithTitle:[MatrixKitL10n yes]
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * action)
                                 {
            MXStrongifyAndReturnIfNil(self);
            self->currentAlert = nil;
            
            // Show the sticker picker settings screen
            IntegrationManagerViewController *modularVC = [[IntegrationManagerViewController alloc]
                                                           initForMXSession:self.roomDataSource.mxSession
                                                           inRoom:self.roomDataSource.roomId
                                                           screen:[IntegrationManagerViewController screenForWidget:kWidgetTypeStickerPicker]
                                                           widgetId:nil];
            
            [self presentViewController:modularVC animated:NO completion:nil];
        }]];
        
        [installPrompt mxk_setAccessibilityIdentifier:@"RoomVCStickerPickerAlert"];
        [self presentViewController:installPrompt animated:YES completion:nil];
        currentAlert = installPrompt;
    }
}

- (void)roomInputToolbarViewDidTapFileUpload
{
    MXKDocumentPickerPresenter *documentPickerPresenter = [MXKDocumentPickerPresenter new];
    documentPickerPresenter.delegate = self;
    
    NSArray<MXKUTI*> *allowedUTIs = @[MXKUTI.data];
    [documentPickerPresenter presentDocumentPickerWith:allowedUTIs from:self animated:YES completion:nil];
    
    self.documentPickerPresenter = documentPickerPresenter;
}

/**
 Send a video asset via the room input toolbar prompting the user for the conversion preset to use
 if the `showMediaCompressionPrompt` setting has been enabled.
 @param videoAsset The video asset to send
 @param isPhotoLibraryAsset Whether the asset was picked from the user's photo library.
 */
- (void)sendVideoAsset:(AVAsset *)videoAsset isPhotoLibraryAsset:(BOOL)isPhotoLibraryAsset
{
    RoomInputToolbarView *roomInputToolbarView = [self inputToolbarViewAsRoomInputToolbarView];
    if (!roomInputToolbarView)
    {
        return;
    }
    
    if (RiotSettings.shared.showMediaCompressionPrompt)
    {
        // Show the video conversion prompt for the user to select what size video they would like to send.
        UIAlertController *compressionPrompt = [MXKTools videoConversionPromptForVideoAsset:videoAsset
                                                                              withCompletion:^(NSString *presetName) {
            // When the preset name is missing, the user cancelled.
            if (!presetName)
            {
                return;
            }
            
            // Set the chosen preset and send the video (conversion takes place in the SDK).
            [MXSDKOptions sharedInstance].videoConversionPresetName = presetName;
            [roomInputToolbarView sendSelectedVideoAsset:videoAsset isPhotoLibraryAsset:isPhotoLibraryAsset];
        }];
        
        [self presentViewController:compressionPrompt animated:YES completion:nil];
    }
    else
    {
        // Otherwise default to 1080p and send the video.
        [MXSDKOptions sharedInstance].videoConversionPresetName = AVAssetExportPreset1920x1080;
        [roomInputToolbarView sendSelectedVideoAsset:videoAsset isPhotoLibraryAsset:isPhotoLibraryAsset];
    }
}

- (void)showRoomWithId:(NSString*)roomId
{
    if (self.delegate)
    {
        [self.delegate roomViewController:self showRoomWithId:roomId];
    }
    else
    {
        [[AppDelegate theDelegate] showRoom:roomId andEventId:nil withMatrixSession:self.roomDataSource.mxSession];
    }
}

- (void)leaveRoom
{
    [self startActivityIndicator];
    
    [self.roomDataSource.room leave:^{
        
        [self stopActivityIndicator];
        
        // We remove the current view controller.
        if (self.delegate)
        {
            [self.delegate roomViewControllerDidLeaveRoom:self];
        }
        else
        {
            [[AppDelegate theDelegate] restoreInitialDisplay:^{}];
        }
        
    } failure:^(NSError *error) {
        
        [self stopActivityIndicator];
        MXLogDebug(@"[RoomVC] Failed to reject an invited room (%@) failed", self.roomDataSource.room.roomId);
        
    }];
}

- (void)roomPreviewDidTapCancelAction
{
    // Decline this invitation = leave this page
    if (self.delegate)
    {
        [self.delegate roomViewControllerPreviewDidTapCancel:self];
    }
    else
    {
        [[AppDelegate theDelegate] restoreInitialDisplay:^{}];
    }
}

- (void)startChatWithUserId:(NSString *)userId completion:(void (^)(void))completion
{
    if (self.delegate)
    {
        [self.delegate roomViewController:self startChatWithUserId:userId completion:completion];
    }
    else
    {
        [[AppDelegate theDelegate] createDirectChatWithUserId:userId completion:completion];
    }
}

- (void)showError:(NSError*)error
{
    [[AppDelegate theDelegate] showErrorAsAlert:error];
}

- (UIAlertController*)showAlertWithTitle:(NSString*)title message:(NSString*)message
{
    return [[AppDelegate theDelegate] showAlertWithTitle:title message:message];
}

- (ScreenPresentationParameters*)buildUniversalLinkPresentationParameters
{
    return [[ScreenPresentationParameters alloc] initWithRestoreInitialDisplay:NO stackAboveVisibleViews:BuildSettings.allowSplitViewDetailsScreenStacking sender:self sourceView:nil];
}

- (BOOL)handleUniversalLinkURL:(NSURL*)universalLinkURL
{
    UniversalLinkParameters *parameters = [[UniversalLinkParameters alloc] initWithUniversalLinkURL:universalLinkURL presentationParameters:[self buildUniversalLinkPresentationParameters]];
    return [self handleUniversalLinkWithParameters:parameters];
}

- (BOOL)handleUniversalLinkFragment:(NSString*)fragment fromURL:(NSURL*)universalLinkURL
{
    UniversalLinkParameters *parameters = [[UniversalLinkParameters alloc] initWithFragment:fragment
                                                                           universalLinkURL:universalLinkURL presentationParameters:[self buildUniversalLinkPresentationParameters]];
    return [self handleUniversalLinkWithParameters:parameters];
}

- (BOOL)handleUniversalLinkWithParameters:(UniversalLinkParameters*)parameters
{
    if (self.delegate)
    {
        return [self.delegate roomViewController:self handleUniversalLinkWithParameters:parameters];
    }
    else
    {
        return [[AppDelegate theDelegate] handleUniversalLinkWithParameters:parameters];
    }
}

- (void)setupUserSuggestionView
{
    if(!self.isViewLoaded) {
        MXLogError(@"Failed setting up user suggestions. View not loaded.");
        return;
    }
    
    UIViewController *suggestionsViewController = self.userSuggestionCoordinator.toPresentable;
    
    if (!suggestionsViewController)
    {
        return;
    }
    
    [suggestionsViewController.view setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self addChildViewController:suggestionsViewController];
    [self.userSuggestionContainerView addSubview:suggestionsViewController.view];
    
    [NSLayoutConstraint activateConstraints:@[[suggestionsViewController.view.topAnchor constraintEqualToAnchor:self.userSuggestionContainerView.topAnchor],
                                              [suggestionsViewController.view.leadingAnchor constraintEqualToAnchor:self.userSuggestionContainerView.leadingAnchor],
                                              [suggestionsViewController.view.trailingAnchor constraintEqualToAnchor:self.userSuggestionContainerView.trailingAnchor],
                                              [suggestionsViewController.view.bottomAnchor constraintEqualToAnchor:self.userSuggestionContainerView.bottomAnchor],]];
    
    [suggestionsViewController didMoveToParentViewController:self];
}

#pragma mark - Jitsi

- (void)showJitsiCallWithWidget:(Widget*)widget
{
    [[AppDelegate theDelegate].callPresenter displayJitsiCallWithWidget:widget];
}

- (void)endActiveJitsiCall
{
    [[AppDelegate theDelegate].callPresenter endActiveJitsiCall];
}

- (BOOL)isRoomHavingAJitsiCall
{
    return [self isRoomHavingAJitsiCallForWidgetId:self.roomDataSource.roomId];
}

- (BOOL)isRoomHavingAJitsiCallForWidgetId:(NSString*)widgetId
{
    return [[AppDelegate theDelegate].callPresenter.jitsiVC.widget.roomId isEqualToString:widgetId];
}

#pragma mark - Dialpad

- (void)openDialpad
{
    DialpadViewController *controller = [DialpadViewController instantiateWithConfiguration:[DialpadConfiguration default]];
    controller.delegate = self;
    self.customSizedPresentationController = [[CustomSizedPresentationController alloc] initWithPresentedViewController:controller presentingViewController:self];
    self.customSizedPresentationController.dismissOnBackgroundTap = NO;
    self.customSizedPresentationController.cornerRadius = 16;
    
    controller.transitioningDelegate = self.customSizedPresentationController;
    [self presentViewController:controller animated:YES completion:nil];
}

#pragma mark - DialpadViewControllerDelegate

- (void)dialpadViewControllerDidTapCall:(DialpadViewController *)viewController withPhoneNumber:(NSString *)phoneNumber
{
    if (self.mainSession.callManager && phoneNumber.length > 0)
    {
        [self startActivityIndicator];
        
        [viewController dismissViewControllerAnimated:YES completion:^{
            MXWeakify(self);
            [self.mainSession.callManager placeCallAgainst:phoneNumber withVideo:NO success:^(MXCall * _Nonnull call) {
                MXStrongifyAndReturnIfNil(self);
                [self stopActivityIndicator];
                self.customSizedPresentationController = nil;
                
                //  do nothing extra here. UI will be handled automatically by the CallService.
            } failure:^(NSError * _Nullable error) {
                MXStrongifyAndReturnIfNil(self);
                [self stopActivityIndicator];
            }];
        }];
    }
}

- (void)dialpadViewControllerDidTapClose:(DialpadViewController *)viewController
{
    [viewController dismissViewControllerAnimated:YES completion:nil];
    self.customSizedPresentationController = nil;
}

#pragma mark - Hide/Show preview header

- (void)showPreviewHeader:(BOOL)isVisible
{
    if (self.previewHeaderContainer && self.previewHeaderContainer.isHidden == isVisible)
    {
        // Check conditions before making the preview room header visible.
        // This operation is ignored if a screen rotation is in progress,
        // or if the view controller is not embedded inside a split view controller yet.
        if (isVisible && (isSizeTransitionInProgress == YES || !self.splitViewController))
        {
            MXLogDebug(@"[RoomVC] Show preview header ignored");
            return;
        }
        
        if (isVisible)
        {
            PreviewRoomTitleView *previewHeader = [PreviewRoomTitleView roomTitleView];
            previewHeader.delegate = self;
            previewHeader.tapGestureDelegate = self;
            previewHeader.translatesAutoresizingMaskIntoConstraints = NO;
            [self.previewHeaderContainer addSubview:previewHeader];
            
            self->previewHeader = previewHeader;
            
            // Force preview header in full width
            NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:previewHeader
                                                                              attribute:NSLayoutAttributeLeading
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:self.previewHeaderContainer
                                                                              attribute:NSLayoutAttributeLeading
                                                                             multiplier:1.0
                                                                               constant:0];
            NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:previewHeader
                                                                               attribute:NSLayoutAttributeTrailing
                                                                               relatedBy:NSLayoutRelationEqual
                                                                                  toItem:self.previewHeaderContainer
                                                                               attribute:NSLayoutAttributeTrailing
                                                                              multiplier:1.0
                                                                                constant:0];
            // Vertical constraints are required for iOS > 8
            NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:previewHeader
                                                                             attribute:NSLayoutAttributeTop
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:self.previewHeaderContainer
                                                                             attribute:NSLayoutAttributeTop
                                                                            multiplier:1.0
                                                                              constant:0];
            NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:previewHeader
                                                                                attribute:NSLayoutAttributeBottom
                                                                                relatedBy:NSLayoutRelationEqual
                                                                                   toItem:self.previewHeaderContainer
                                                                                attribute:NSLayoutAttributeBottom
                                                                               multiplier:1.0
                                                                                 constant:0];
            
            [NSLayoutConstraint activateConstraints:@[leftConstraint, rightConstraint, topConstraint, bottomConstraint]];
            
            if (roomPreviewData)
            {
                previewHeader.roomPreviewData = roomPreviewData;
            }
            else if (self.roomDataSource)
            {
                previewHeader.mxRoom = self.roomDataSource.room;
            }
            
            self.previewHeaderContainer.hidden = NO;
            
            // Finalize preview header display according to the screen orientation
            [self refreshPreviewHeader:UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])];
        }
        else
        {
            [previewHeader removeFromSuperview];
            previewHeader = nil;
            
            self.previewHeaderContainer.hidden = YES;
            
            // Consider the main navigation controller if the current view controller is embedded inside a split view controller.
            UINavigationController *mainNavigationController = self.navigationController;
            if (self.splitViewController.isCollapsed && self.splitViewController.viewControllers.count)
            {
                mainNavigationController = self.splitViewController.viewControllers.firstObject;
            }
            
            // Set a default title view class without handling tap gesture (Let [self refreshRoomTitle] refresh this view correctly).
            [self setRoomTitleViewClass:RoomTitleView.class];
                        
            // Remove the shadow image used to hide the bottom border of the navigation bar when the preview header is displayed
            [mainNavigationController.navigationBar setShadowImage:nil];
            [mainNavigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
            
            [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseIn
                             animations:^{
                
                self.bubblesTableViewTopConstraint.constant = 0;
                
                // Force to render the view
                [self forceLayoutRefresh];
                
            }
                             completion:^(BOOL finished){
            }];
        }
    }
    
    // Consider the main navigation controller if the current view controller is embedded inside a split view controller.
    UINavigationController *mainNavigationController = self.navigationController;
    if (self.splitViewController.isCollapsed && self.splitViewController.viewControllers.count)
    {
        mainNavigationController = self.splitViewController.viewControllers.firstObject;
    }
    mainNavigationController.navigationBar.translucent = isVisible;
    self.navigationController.navigationBar.translucent = isVisible;
}

- (void)refreshPreviewHeader:(BOOL)isLandscapeOriented
{
    if (previewHeader)
    {
        if (isLandscapeOriented
            && [GBDeviceInfo deviceInfo].family != GBDeviceFamilyiPad)
        {
            CGRect frame = self.navigationController.navigationBar.frame;
            
            previewHeader.mainHeaderContainer.hidden = YES;
            previewHeader.mainHeaderBackgroundHeightConstraint.constant = frame.size.height + (frame.origin.y > 0 ? frame.origin.y : 0);
            
            [self setRoomTitleViewClass:RoomTitleView.class];
            // We don't want to handle tap gesture here
            
            // Remove details icon
            RoomTitleView *roomTitleView = (RoomTitleView*)self.titleView;
            
            // Set preview data to provide the room name
            roomTitleView.roomPreviewData = roomPreviewData;
        }
        else
        {
            previewHeader.mainHeaderContainer.hidden = NO;
            previewHeader.mainHeaderBackgroundHeightConstraint.constant = previewHeader.mainHeaderContainer.frame.size.height;
            
            if ([previewHeader isKindOfClass:PreviewRoomTitleView.class])
            {
                // In case of preview, update the header height so that we can
                // display as much as possible the room topic in this header.
                // Note: the header height is handled by the previewHeader.mainHeaderBackgroundHeightConstraint.
                PreviewRoomTitleView *previewRoomTitleView = (PreviewRoomTitleView *)previewHeader;
                
                // Compute the height required to display all the room topic
                CGSize sizeThatFitsTextView = [previewRoomTitleView.roomTopic sizeThatFits:CGSizeMake(previewRoomTitleView.roomTopic.frame.size.width, MAXFLOAT)];
                
                // Increase the preview header height according to the room topic height
                // but limit it in order to let room for room messages at the screen bottom.
                // This free space depends on the device.
                // On an iphone 5 screen, the room topic height cannot be more than 50px.
                // Then, on larger screen, we can allow it a bit more height but we
                // apply a factor to give more priority to the display of more messages.
                CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;
                CGFloat maxRoomTopicHeight = 50 + (screenHeight - 568) / 3;
                
                CGFloat additionalHeight = MIN(maxRoomTopicHeight, sizeThatFitsTextView.height)
                - previewRoomTitleView.roomTopic.frame.size.height;
                
                previewHeader.mainHeaderBackgroundHeightConstraint.constant += additionalHeight;
            }
            
            [self setRoomTitleViewClass:RoomAvatarTitleView.class];
            // Note the avatar title view does not define tap gesture.
            
            previewHeader.roomAvatar.alpha = 0.0;
            
            // Set the avatar provided in preview data
            if (roomPreviewData.roomAvatarUrl)
            {
                previewHeader.roomAvatarURL = roomPreviewData.roomAvatarUrl;
            }
            else if (roomPreviewData.roomId && roomPreviewData.roomName)
            {
                previewHeader.roomAvatarPlaceholder = [AvatarGenerator generateAvatarForMatrixItem:roomPreviewData.roomId withDisplayName:roomPreviewData.roomName];
            }
            else
            {
                previewHeader.roomAvatarPlaceholder = [MXKTools paintImage:[UIImage imageNamed:@"placeholder"]
                                                                 withColor:ThemeService.shared.theme.tintColor];
            }
        }
        
        // Force the layout of previewHeader to update the position of 'bottomBorderView' which is used
        // to define the actual height of the preview container.
        [previewHeader layoutIfNeeded];
        CGRect frame = previewHeader.bottomBorderView.frame;
        self.previewHeaderContainerHeightConstraint.constant = frame.origin.y + frame.size.height;
        
        // Consider the main navigation controller if the current view controller is embedded inside a split view controller.
        UINavigationController *mainNavigationController = self.navigationController;
        if (self.splitViewController.isCollapsed && self.splitViewController.viewControllers.count)
        {
            mainNavigationController = self.splitViewController.viewControllers.firstObject;
        }
        
        // When the preview header is displayed, we hide the bottom border of the navigation bar (the shadow image).
        // The default shadow image is nil. When non-nil, this property represents a custom shadow image to show instead
        // of the default. For a custom shadow image to be shown, a custom background image must also be set with the
        // setBackgroundImage:forBarMetrics: method. If the default background image is used, then the default shadow
        // image will be used regardless of the value of this property.
        UIImage *shadowImage = [[UIImage alloc] init];
        [mainNavigationController.navigationBar setShadowImage:shadowImage];
        [mainNavigationController.navigationBar setBackgroundImage:shadowImage forBarMetrics:UIBarMetricsDefault];
        
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseIn
                         animations:^{
            
            self.bubblesTableViewTopConstraint.constant = self.previewHeaderContainerHeightConstraint.constant - self.bubblesTableView.adjustedContentInset.top;
            
            previewHeader.roomAvatar.alpha = 1;
            
            // Force to render the view
            [self forceLayoutRefresh];
            
        }
                         completion:^(BOOL finished){
        }];
    }
}

#pragma mark - Preview

- (void)displayRoomPreview:(RoomPreviewData *)previewData
{
    // Release existing room data source or preview
    [self displayRoom:nil];
    
    if (previewData)
    {
        self.eventsAcknowledgementEnabled = NO;
        
        [self addMatrixSession:previewData.mxSession];
        
        roomPreviewData = previewData;
        
        [self refreshRoomTitle];
        
        if (roomPreviewData.roomDataSource)
        {
            [super displayRoom:roomPreviewData.roomDataSource];
        }
    }
}

#pragma mark - MXKDataSourceDelegate

- (Class<MXKCellRendering>)cellViewClassForCellData:(MXKCellData*)cellData
{
    Class cellViewClass = nil;
    BOOL showEncryptionBadge = NO;
    
    // Sanity check
    if (![cellData conformsToProtocol:@protocol(MXKRoomBubbleCellDataStoring)])
    {
        return nil;
    }
        
    id<MXKRoomBubbleCellDataStoring> bubbleData = (id<MXKRoomBubbleCellDataStoring>)cellData;
    
    MXKRoomBubbleCellData *roomBubbleCellData;
    
    if ([bubbleData isKindOfClass:MXKRoomBubbleCellData.class])
    {
        roomBubbleCellData = (MXKRoomBubbleCellData*)bubbleData;
        showEncryptionBadge = roomBubbleCellData.containsBubbleComponentWithEncryptionBadge;
    }
    
    // Select the suitable table view cell class, by considering first the empty bubble cell.
    if (bubbleData.hasNoDisplay)
    {
        cellViewClass = RoomEmptyBubbleCell.class;
    }
    else if (bubbleData.tag == RoomBubbleCellDataTagRoomCreationIntro)
    {
        cellViewClass = RoomCreationIntroCell.class;
    }
    else if (bubbleData.tag == RoomBubbleCellDataTagRoomCreateWithPredecessor)
    {
        cellViewClass = RoomPredecessorBubbleCell.class;
    }
    else if (bubbleData.tag == RoomBubbleCellDataTagKeyVerificationRequestIncomingApproval)
    {
        cellViewClass = bubbleData.isPaginationFirstBubble ? KeyVerificationIncomingRequestApprovalWithPaginationTitleBubbleCell.class : KeyVerificationIncomingRequestApprovalBubbleCell.class;
    }
    else if (bubbleData.tag == RoomBubbleCellDataTagKeyVerificationRequest)
    {
        cellViewClass = bubbleData.isPaginationFirstBubble ? KeyVerificationRequestStatusWithPaginationTitleBubbleCell.class : KeyVerificationRequestStatusBubbleCell.class;
    }
    else if (bubbleData.tag == RoomBubbleCellDataTagKeyVerificationConclusion)
    {
        cellViewClass = bubbleData.isPaginationFirstBubble ? KeyVerificationConclusionWithPaginationTitleBubbleCell.class : KeyVerificationConclusionBubbleCell.class;
    }
    else if (bubbleData.tag == RoomBubbleCellDataTagMembership)
    {
        if (bubbleData.collapsed)
        {
            if (bubbleData.nextCollapsableCellData)
            {
                cellViewClass = bubbleData.isPaginationFirstBubble ? RoomMembershipCollapsedWithPaginationTitleBubbleCell.class : RoomMembershipCollapsedBubbleCell.class;
            }
            else
            {
                // Use a normal membership cell for a single membership event
                cellViewClass = bubbleData.isPaginationFirstBubble ? RoomMembershipWithPaginationTitleBubbleCell.class : RoomMembershipBubbleCell.class;
            }
        }
        else if (bubbleData.collapsedAttributedTextMessage)
        {
            // The cell (and its series) is not collapsed but this cell is the first
            // of the series. So, use the cell with the "collapse" button.
            cellViewClass = bubbleData.isPaginationFirstBubble ? RoomMembershipExpandedWithPaginationTitleBubbleCell.class : RoomMembershipExpandedBubbleCell.class;
        }
        else
        {
            cellViewClass = bubbleData.isPaginationFirstBubble ? RoomMembershipWithPaginationTitleBubbleCell.class : RoomMembershipBubbleCell.class;
        }
    }
    else if (bubbleData.tag == RoomBubbleCellDataTagRoomCreateConfiguration)
    {
        cellViewClass = bubbleData.isPaginationFirstBubble ? RoomCreationWithPaginationCollapsedBubbleCell.class : RoomCreationCollapsedBubbleCell.class;
    }
    else if (bubbleData.tag == RoomBubbleCellDataTagCall)
    {
        cellViewClass = RoomDirectCallStatusBubbleCell.class;
    }
    else if (bubbleData.tag == RoomBubbleCellDataTagGroupCall)
    {
        cellViewClass = RoomGroupCallStatusBubbleCell.class;
    }
    else if (bubbleData.attachment.type == MXKAttachmentTypeVoiceMessage || bubbleData.attachment.type == MXKAttachmentTypeAudio)
    {
        if (bubbleData.isPaginationFirstBubble)
        {
            cellViewClass = VoiceMessageWithPaginationTitleBubbleCell.class;
        }
        else if (bubbleData.shouldHideSenderInformation)
        {
            cellViewClass = VoiceMessageWithoutSenderInfoBubbleCell.class;
        }
        else
        {
            cellViewClass = VoiceMessageBubbleCell.class;
        }
    }
    else if (bubbleData.tag == RoomBubbleCellDataTagPoll)
    {
        if (bubbleData.isPaginationFirstBubble)
        {
            cellViewClass = PollWithPaginationTitleBubbleCell.class;
        }
        else if (bubbleData.shouldHideSenderInformation)
        {
            cellViewClass = PollWithoutSenderInfoBubbleCell.class;
        }
        else
        {
            cellViewClass = PollBubbleCell.class;
        }
    }
    else if (bubbleData.isIncoming)
    {
        if (bubbleData.isAttachmentWithThumbnail)
        {
            // Check whether the provided celldata corresponds to a selected sticker
            if (customizedRoomDataSource.selectedEventId && (bubbleData.attachment.type == MXKAttachmentTypeSticker) && [bubbleData.attachment.eventId isEqualToString:customizedRoomDataSource.selectedEventId])
            {
                cellViewClass = RoomSelectedStickerBubbleCell.class;
            }
            else if (bubbleData.isPaginationFirstBubble)
            {
                cellViewClass = showEncryptionBadge ? RoomIncomingEncryptedAttachmentWithPaginationTitleBubbleCell.class : RoomIncomingAttachmentWithPaginationTitleBubbleCell.class;
            }
            else if (bubbleData.shouldHideSenderInformation)
            {
                cellViewClass = showEncryptionBadge ? RoomIncomingEncryptedAttachmentWithoutSenderInfoBubbleCell.class : RoomIncomingAttachmentWithoutSenderInfoBubbleCell.class;
            }
            else
            {
                cellViewClass = showEncryptionBadge ? RoomIncomingEncryptedAttachmentBubbleCell.class : RoomIncomingAttachmentBubbleCell.class;
            }
        }
        else
        {
            if (bubbleData.isPaginationFirstBubble)
            {
                if (bubbleData.shouldHideSenderName)
                {
                    cellViewClass = showEncryptionBadge ? RoomIncomingEncryptedTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.class : RoomIncomingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.class;
                }
                else
                {
                    cellViewClass = showEncryptionBadge ? RoomIncomingEncryptedTextMsgWithPaginationTitleBubbleCell.class : RoomIncomingTextMsgWithPaginationTitleBubbleCell.class;
                }
            }
            else if (bubbleData.shouldHideSenderInformation)
            {
                cellViewClass = showEncryptionBadge ? RoomIncomingEncryptedTextMsgWithoutSenderInfoBubbleCell.class : RoomIncomingTextMsgWithoutSenderInfoBubbleCell.class;
            }
            else if (bubbleData.shouldHideSenderName)
            {
                cellViewClass = showEncryptionBadge ? RoomIncomingEncryptedTextMsgWithoutSenderNameBubbleCell.class : RoomIncomingTextMsgWithoutSenderNameBubbleCell.class;
            }
            else
            {
                cellViewClass = showEncryptionBadge ? RoomIncomingEncryptedTextMsgBubbleCell.class : RoomIncomingTextMsgBubbleCell.class;
            }
        }
    }
    else
    {
        // Handle here outgoing bubbles
        if (bubbleData.isAttachmentWithThumbnail)
        {
            // Check whether the provided celldata corresponds to a selected sticker
            if (customizedRoomDataSource.selectedEventId && (bubbleData.attachment.type == MXKAttachmentTypeSticker) && [bubbleData.attachment.eventId isEqualToString:customizedRoomDataSource.selectedEventId])
            {
                cellViewClass = RoomSelectedStickerBubbleCell.class;
            }
            else if (bubbleData.isPaginationFirstBubble)
            {
                cellViewClass = showEncryptionBadge ? RoomOutgoingEncryptedAttachmentWithPaginationTitleBubbleCell.class :RoomOutgoingAttachmentWithPaginationTitleBubbleCell.class;
            }
            else if (bubbleData.shouldHideSenderInformation)
            {
                cellViewClass = showEncryptionBadge ? RoomOutgoingEncryptedAttachmentWithoutSenderInfoBubbleCell.class : RoomOutgoingAttachmentWithoutSenderInfoBubbleCell.class;
            }
            else
            {
                cellViewClass = showEncryptionBadge ? RoomOutgoingEncryptedAttachmentBubbleCell.class : RoomOutgoingAttachmentBubbleCell.class;
            }
        }
        else
        {
            if (bubbleData.isPaginationFirstBubble)
            {
                if (bubbleData.shouldHideSenderName)
                {
                    cellViewClass = showEncryptionBadge ? RoomOutgoingEncryptedTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.class : RoomOutgoingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.class;
                }
                else
                {
                    cellViewClass = showEncryptionBadge ? RoomOutgoingEncryptedTextMsgWithPaginationTitleBubbleCell.class : RoomOutgoingTextMsgWithPaginationTitleBubbleCell.class;
                }
            }
            else if (bubbleData.shouldHideSenderInformation)
            {
                cellViewClass = showEncryptionBadge ? RoomOutgoingEncryptedTextMsgWithoutSenderInfoBubbleCell.class :RoomOutgoingTextMsgWithoutSenderInfoBubbleCell.class;
            }
            else if (bubbleData.shouldHideSenderName)
            {
                cellViewClass = showEncryptionBadge ? RoomOutgoingEncryptedTextMsgWithoutSenderNameBubbleCell.class : RoomOutgoingTextMsgWithoutSenderNameBubbleCell.class;
            }
            else
            {
                cellViewClass = showEncryptionBadge ? RoomOutgoingEncryptedTextMsgBubbleCell.class : RoomOutgoingTextMsgBubbleCell.class;
            }
        }
    }
    
    return cellViewClass;
}

#pragma mark - MXKDataSource delegate

- (void)dataSource:(MXKDataSource *)dataSource didRecognizeAction:(NSString *)actionIdentifier inCell:(id<MXKCellRendering>)cell userInfo:(NSDictionary *)userInfo
{
    // Handle here user actions on bubbles for Vector app
    if (customizedRoomDataSource)
    {
        id<MXKRoomBubbleCellDataStoring> bubbleData;
        
        if ([cell isKindOfClass:[MXKRoomBubbleTableViewCell class]])
        {
            MXKRoomBubbleTableViewCell *roomBubbleTableViewCell = (MXKRoomBubbleTableViewCell*)cell;
            bubbleData = roomBubbleTableViewCell.bubbleData;
        }
        
        
        if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellTapOnAvatarView])
        {
            MXRoomMember *member = [self.roomDataSource.roomState.members memberWithUserId:userInfo[kMXKRoomBubbleCellUserIdKey]];
            [self showMemberDetails:member];
        }
        else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellLongPressOnAvatarView])
        {
            // Add the member display name in text input
            MXRoomMember *roomMember = [self.roomDataSource.roomState.members memberWithUserId:userInfo[kMXKRoomBubbleCellUserIdKey]];
            if (roomMember)
            {
                [self mention:roomMember];
            }
        }
        else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellTapOnMessageTextView] || [actionIdentifier isEqualToString:kMXKRoomBubbleCellTapOnContentView])
        {
            // Retrieve the tapped event
            MXEvent *tappedEvent = userInfo[kMXKRoomBubbleCellEventKey];
            
            // Check whether a selection already exist or not
            if (customizedRoomDataSource.selectedEventId)
            {
                [self cancelEventSelection];
            }
            else if (tappedEvent)
            {
                if (tappedEvent.eventType == MXEventTypeRoomCreate)
                {
                    // Handle tap on RoomPredecessorBubbleCell
                    MXRoomCreateContent *createContent = [MXRoomCreateContent modelFromJSON:tappedEvent.content];
                    NSString *predecessorRoomId = createContent.roomPredecessorInfo.roomId;
                    
                    if (predecessorRoomId)
                    {
                        // Show predecessor room
                        [self showRoomWithId:predecessorRoomId];
                    }
                    else
                    {
                        // Show contextual menu on single tap if bubble is not collapsed
                        if (bubbleData.collapsed)
                        {
                            [self showRoomCreationModalWithBubbleData:bubbleData];
                        }
                        else
                        {
                            [self showContextualMenuForEvent:tappedEvent fromSingleTapGesture:YES cell:cell animated:YES];
                        }
                    }
                }
                else if (bubbleData.tag == RoomBubbleCellDataTagCall)
                {
                    if ([bubbleData isKindOfClass:[RoomBubbleCellData class]])
                    {
                        //  post notification `RoomCallTileTapped`
                        [[NSNotificationCenter defaultCenter] postNotificationName:RoomCallTileTappedNotification object:bubbleData];
                        
                        preventBubblesTableViewScroll = YES;
                        [self selectEventWithId:tappedEvent.eventId];
                    }
                }
                else if (bubbleData.tag == RoomBubbleCellDataTagGroupCall)
                {
                    if ([bubbleData isKindOfClass:[RoomBubbleCellData class]])
                    {
                        //  post notification `RoomGroupCallTileTapped`
                        [[NSNotificationCenter defaultCenter] postNotificationName:RoomGroupCallTileTappedNotification object:bubbleData];
                        
                        preventBubblesTableViewScroll = YES;
                        [self selectEventWithId:tappedEvent.eventId];
                    }
                }
                else
                {
                    // Show contextual menu on single tap if bubble is not collapsed
                    if (bubbleData.collapsed)
                    {
                        [self selectEventWithId:tappedEvent.eventId];
                    }
                    else
                    {
                        [self showContextualMenuForEvent:tappedEvent fromSingleTapGesture:YES cell:cell animated:YES];
                    }
                }
            }
        }
        else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellTapOnOverlayContainer])
        {
            // Cancel the current event selection
            [self cancelEventSelection];
        }
        else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellRiotEditButtonPressed])
        {
            [self dismissKeyboard];
            
            MXEvent *selectedEvent = userInfo[kMXKRoomBubbleCellEventKey];
            
            if (selectedEvent)
            {
                [self showContextualMenuForEvent:selectedEvent fromSingleTapGesture:YES cell:cell animated:YES];
            }
        }
        else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellKeyVerificationIncomingRequestAcceptPressed])
        {
            NSString *eventId = userInfo[kMXKRoomBubbleCellEventIdKey];
            
            RoomDataSource *roomDataSource = (RoomDataSource*)self.roomDataSource;
            
            [roomDataSource acceptVerificationRequestForEventId:eventId success:^{
                
            } failure:^(NSError *error) {
                [self showError:error];
            }];
        }
        else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellKeyVerificationIncomingRequestDeclinePressed])
        {
            NSString *eventId = userInfo[kMXKRoomBubbleCellEventIdKey];
            
            RoomDataSource *roomDataSource = (RoomDataSource*)self.roomDataSource;
            
            [roomDataSource declineVerificationRequestForEventId:eventId success:^{
                
            } failure:^(NSError *error) {
                [self showError:error];
            }];
        }
        else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellTapOnAttachmentView])
        {
            if (((MXKRoomBubbleTableViewCell*)cell).bubbleData.attachment.eventSentState == MXEventSentStateFailed)
            {
                // Shortcut: when clicking on an unsent media, show the action sheet to resend it
                NSString *eventId = ((MXKRoomBubbleTableViewCell*)cell).bubbleData.attachment.eventId;
                MXEvent *selectedEvent = [self.roomDataSource eventWithEventId:eventId];
                
                if (selectedEvent)
                {
                    [self dataSource:dataSource didRecognizeAction:kMXKRoomBubbleCellRiotEditButtonPressed inCell:cell userInfo:@{kMXKRoomBubbleCellEventKey:selectedEvent}];
                }
                else
                {
                    MXLogDebug(@"[RoomViewController] didRecognizeAction:inCell:userInfo tap on attachment with event state MXEventSentStateFailed. Selected event is nil for event id %@", eventId);
                }
            }
            else if (((MXKRoomBubbleTableViewCell*)cell).bubbleData.attachment.type == MXKAttachmentTypeSticker)
            {
                // We don't open the attachments viewer when the user taps on a sticker.
                // We consider this tap like a selection.
                
                // Check whether a selection already exist or not
                if (customizedRoomDataSource.selectedEventId)
                {
                    [self cancelEventSelection];
                }
                else
                {
                    // Highlight this event in displayed message
                    [self selectEventWithId:((MXKRoomBubbleTableViewCell*)cell).bubbleData.attachment.eventId];
                }
            }
            else
            {
                // Keep default implementation
                [super dataSource:dataSource didRecognizeAction:actionIdentifier inCell:cell userInfo:userInfo];
            }
        }
        else if ([actionIdentifier isEqualToString:kRoomEncryptedDataBubbleCellTapOnEncryptionIcon])
        {
            // Retrieve the tapped event
            MXEvent *tappedEvent = userInfo[kMXKRoomBubbleCellEventKey];
            
            if (tappedEvent)
            {
                [self showEncryptionInformation:tappedEvent];
            }
        }
        else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellTapOnReceiptsContainer])
        {
            MXKReceiptSendersContainer *container = userInfo[kMXKRoomBubbleCellReceiptsContainerKey];
            [ReadReceiptsViewController openInViewController:self fromContainer:container withSession:self.mainSession];
        }
        else if ([actionIdentifier isEqualToString:kRoomMembershipExpandedBubbleCellTapOnCollapseButton])
        {
            // Reset the selection before collapsing
            customizedRoomDataSource.selectedEventId = nil;
            
            [self.roomDataSource collapseRoomBubble:((MXKRoomBubbleTableViewCell*)cell).bubbleData collapsed:YES];
        }
        else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellLongPressOnEvent])
        {
            MXEvent *tappedEvent = userInfo[kMXKRoomBubbleCellEventKey];
            
            if (!bubbleData.collapsed)
            {
                [self handleLongPressFromCell:cell withTappedEvent:tappedEvent];
            }
        }
        else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellLongPressOnReactionView])
        {
            NSString *tappedEventId = userInfo[kMXKRoomBubbleCellEventIdKey];
            if (tappedEventId)
            {
                [self showReactionHistoryForEventId:tappedEventId animated:YES];
            }
        }
        else if ([actionIdentifier isEqualToString:RoomDirectCallStatusBubbleCell.callBackAction])
        {
            MXEvent *callInviteEvent = userInfo[kMXKRoomBubbleCellEventKey];
            MXCallInviteEventContent *eventContent = [MXCallInviteEventContent modelFromJSON:callInviteEvent.content];
            
            [self placeCallWithVideo2:eventContent.isVideoCall];
        }
        else if ([actionIdentifier isEqualToString:RoomDirectCallStatusBubbleCell.declineAction])
        {
            MXEvent *callInviteEvent = userInfo[kMXKRoomBubbleCellEventKey];
            MXCallInviteEventContent *eventContent = [MXCallInviteEventContent modelFromJSON:callInviteEvent.content];
            
            MXCall *call = [self.mainSession.callManager callWithCallId:eventContent.callId];
            [call hangup];
        }
        else if ([actionIdentifier isEqualToString:RoomDirectCallStatusBubbleCell.answerAction])
        {
            MXEvent *callInviteEvent = userInfo[kMXKRoomBubbleCellEventKey];
            MXCallInviteEventContent *eventContent = [MXCallInviteEventContent modelFromJSON:callInviteEvent.content];
            
            MXCall *call = [self.mainSession.callManager callWithCallId:eventContent.callId];
            [call answer];
        }
        else if ([actionIdentifier isEqualToString:RoomDirectCallStatusBubbleCell.endCallAction])
        {
            MXEvent *callInviteEvent = userInfo[kMXKRoomBubbleCellEventKey];
            MXCallInviteEventContent *eventContent = [MXCallInviteEventContent modelFromJSON:callInviteEvent.content];
            
            MXCall *call = [self.mainSession.callManager callWithCallId:eventContent.callId];
            [call hangup];
        }
        else if ([actionIdentifier isEqualToString:RoomGroupCallStatusBubbleCell.joinAction] ||
                 [actionIdentifier isEqualToString:RoomGroupCallStatusBubbleCell.answerAction])
        {
            MXWeakify(self);

            // Check app permissions first
            [MXKTools checkAccessForCall:YES
             manualChangeMessageForAudio:[MatrixKitL10n microphoneAccessNotGrantedForCall:AppInfo.current.displayName]
             manualChangeMessageForVideo:[MatrixKitL10n cameraAccessNotGrantedForCall:AppInfo.current.displayName]
               showPopUpInViewController:self completionHandler:^(BOOL granted) {
                
                MXStrongifyAndReturnIfNil(self);
                if (granted)
                {
                    // Present the Jitsi view controller
                    Widget *jitsiWidget = [self->customizedRoomDataSource jitsiWidget];
                    if (jitsiWidget)
                    {
                        [self showJitsiCallWithWidget:jitsiWidget];
                    }
                }
                else
                {
                    MXLogDebug(@"[RoomVC] didRecognizeAction:inCell:userInfo Warning: The application does not have the permission to join/answer the group call");
                }
            }];
            
            MXEvent *widgetEvent = userInfo[kMXKRoomBubbleCellEventKey];
            Widget *widget = [[Widget alloc] initWithWidgetEvent:widgetEvent
                                                 inMatrixSession:customizedRoomDataSource.mxSession];
            [[JitsiService shared] resetDeclineForWidgetWithId:widget.widgetId];
        }
        else if ([actionIdentifier isEqualToString:RoomGroupCallStatusBubbleCell.leaveAction])
        {
            [self endActiveJitsiCall];
            [self reloadBubblesTable:YES];
        }
        else if ([actionIdentifier isEqualToString:RoomGroupCallStatusBubbleCell.declineAction])
        {
            MXEvent *widgetEvent = userInfo[kMXKRoomBubbleCellEventKey];
            Widget *widget = [[Widget alloc] initWithWidgetEvent:widgetEvent
                                                 inMatrixSession:customizedRoomDataSource.mxSession];
            [[JitsiService shared] declineWidgetWithId:widget.widgetId];
            [self reloadBubblesTable:YES];
        }
        else if ([actionIdentifier isEqualToString:RoomCreationIntroCell.tapOnAvatarView])
        {
            [self showRoomAvatarChange];
        }
        else if ([actionIdentifier isEqualToString:RoomCreationIntroCell.tapOnAddParticipants])
        {
            [self showAddParticipants];
        }
        else if ([actionIdentifier isEqualToString:RoomCreationIntroCell.tapOnAddTopic])
        {
            [self showRoomTopicChange];
        }
        else
        {
            // Keep default implementation for other actions
            [super dataSource:dataSource didRecognizeAction:actionIdentifier inCell:cell userInfo:userInfo];
        }
    }
    else
    {
        // Keep default implementation for other actions
        [super dataSource:dataSource didRecognizeAction:actionIdentifier inCell:cell userInfo:userInfo];
    }
}

// Display the additiontal event actions menu
- (void)showAdditionalActionsMenuForEvent:(MXEvent*)selectedEvent inCell:(id<MXKCellRendering>)cell animated:(BOOL)animated
{
    MXKRoomBubbleTableViewCell *roomBubbleTableViewCell = (MXKRoomBubbleTableViewCell *)cell;
    MXKAttachment *attachment = roomBubbleTableViewCell.bubbleData.attachment;
    
    BOOL isJitsiCallEvent = NO;
    switch (selectedEvent.eventType) {
        case MXEventTypeCustom:
            if ([selectedEvent.type isEqualToString:kWidgetMatrixEventTypeString]
                || [selectedEvent.type isEqualToString:kWidgetModularEventTypeString])
            {
                Widget *widget = [[Widget alloc] initWithWidgetEvent:selectedEvent inMatrixSession:self.roomDataSource.mxSession];
                if ([widget.type isEqualToString:kWidgetTypeJitsiV1] ||
                    [widget.type isEqualToString:kWidgetTypeJitsiV2])
                {
                    isJitsiCallEvent = YES;
                }
            }
        default:
            break;
    }
    
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
    
    MXWeakify(self);
    UIAlertController *actionsMenu = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    // Add actions for a failed event
    if (selectedEvent.sentState == MXEventSentStateFailed)
    {
        [actionsMenu addAction:[UIAlertAction actionWithTitle:[VectorL10n retry]
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action) {
            MXStrongifyAndReturnIfNil(self);
            
            [self cancelEventSelection];
            
            // Let the datasource resend. It will manage local echo, etc.
            [self.roomDataSource resendEventWithEventId:selectedEvent.eventId success:nil failure:nil];
        }]];
        
        [actionsMenu addAction:[UIAlertAction actionWithTitle:[VectorL10n roomEventActionDelete]
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action) {
            MXStrongifyAndReturnIfNil(self);
            
            [self cancelEventSelection];
            
            [self.roomDataSource removeEventWithEventId:selectedEvent.eventId];
        }]];
    }
    
    // Add actions for text message
    if (!attachment)
    {
        // Retrieved data related to the selected event
        NSArray *components = roomBubbleTableViewCell.bubbleData.bubbleComponents;
        MXKRoomBubbleComponent *selectedComponent;
        for (selectedComponent in components)
        {
            if ([selectedComponent.event.eventId isEqualToString:selectedEvent.eventId])
            {
                break;
            }
            selectedComponent = nil;
        }
        
        
        // Check status of the selected event
        if (selectedEvent.sentState == MXEventSentStatePreparing ||
            selectedEvent.sentState == MXEventSentStateEncrypting ||
            selectedEvent.sentState == MXEventSentStateSending)
        {
            [actionsMenu addAction:[UIAlertAction actionWithTitle:[VectorL10n roomEventActionCancelSend]
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                MXStrongifyAndReturnIfNil(self);
                
                self->currentAlert = nil;
                
                // Cancel and remove the outgoing message
                [self.roomDataSource.room cancelSendingOperation:selectedEvent.eventId];
                [self.roomDataSource removeEventWithEventId:selectedEvent.eventId];
                
                [self cancelEventSelection];
            }]];
        }
        
        if (selectedEvent.sentState == MXEventSentStateSent && selectedEvent.eventType != MXEventTypePollStart)
        {
            [actionsMenu addAction:[UIAlertAction actionWithTitle:[VectorL10n roomEventActionForward]
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                MXStrongifyAndReturnIfNil(self);
                [self presentEventForwardingDialogForSelectedEvent:selectedEvent];
            }]];
        }
        
        if (!isJitsiCallEvent && selectedEvent.eventType != MXEventTypePollStart)
        {
            [actionsMenu addAction:[UIAlertAction actionWithTitle:[VectorL10n roomEventActionQuote]
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                MXStrongifyAndReturnIfNil(self);
                
                [self cancelEventSelection];
                
                // Quote the message a la Markdown into the input toolbar composer
                self.inputToolbarView.textMessage = [NSString stringWithFormat:@"%@\n>%@\n\n", self.inputToolbarView.textMessage, selectedComponent.textMessage];
                
                // And display the keyboard
                [self.inputToolbarView becomeFirstResponder];
            }]];
        }
        
        if (!isJitsiCallEvent && BuildSettings.messageDetailsAllowShare && selectedEvent.eventType != MXEventTypePollStart)
        {
            [actionsMenu addAction:[UIAlertAction actionWithTitle:[VectorL10n roomEventActionShare]
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                MXStrongifyAndReturnIfNil(self);
                
                [self cancelEventSelection];
                
                NSArray *activityItems = @[selectedComponent.textMessage];
                
                UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
                
                if (activityViewController)
                {
                    activityViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                    activityViewController.popoverPresentationController.sourceView = roomBubbleTableViewCell;
                    activityViewController.popoverPresentationController.sourceRect = roomBubbleTableViewCell.bounds;
                    
                    [self presentViewController:activityViewController animated:YES completion:nil];
                }
            }]];
        }
    }
    else // Add action for attachment
    {
        // Forwarding for already sent attachments
        if (selectedEvent.sentState == MXEventSentStateSent && (attachment.type == MXKAttachmentTypeFile ||
                                                                attachment.type == MXKAttachmentTypeImage ||
                                                                attachment.type == MXKAttachmentTypeVideo ||
                                                                attachment.type == MXKAttachmentTypeVoiceMessage)) {
            [actionsMenu addAction:[UIAlertAction actionWithTitle:[VectorL10n roomEventActionForward]
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                MXStrongifyAndReturnIfNil(self);
                [self presentEventForwardingDialogForSelectedEvent:selectedEvent];
            }]];
        }
        
        if (BuildSettings.messageDetailsAllowSave)
        {
            if (attachment.type == MXKAttachmentTypeImage || attachment.type == MXKAttachmentTypeVideo)
            {
                [actionsMenu addAction:[UIAlertAction actionWithTitle:[VectorL10n roomEventActionSave]
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                    MXStrongifyAndReturnIfNil(self);
                    
                    [self cancelEventSelection];
                    
                    [self startActivityIndicator];
                    
                    MXWeakify(self);
                    [attachment save:^{
                        MXStrongifyAndReturnIfNil(self);
                        [self stopActivityIndicator];
                    } failure:^(NSError *error) {
                        MXStrongifyAndReturnIfNil(self);
                        [self stopActivityIndicator];
                        
                        //Alert user
                        [self showError:error];
                    }];
                    
                    // Start animation in case of download during attachment preparing
                    [roomBubbleTableViewCell startProgressUI];
                }]];
            }
        }
        
        // Check status of the selected event
        if (selectedEvent.sentState == MXEventSentStatePreparing ||
            selectedEvent.sentState == MXEventSentStateEncrypting ||
            selectedEvent.sentState == MXEventSentStateUploading ||
            selectedEvent.sentState == MXEventSentStateSending)
        {
            // Upload id is stored in attachment url (nasty trick)
            NSString *uploadId = roomBubbleTableViewCell.bubbleData.attachment.contentURL;
            if ([MXMediaManager existingUploaderWithId:uploadId])
            {
                [actionsMenu addAction:[UIAlertAction actionWithTitle:[VectorL10n roomEventActionCancelSend]
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                    
                    MXStrongifyAndReturnIfNil(self);
                    
                    // Get again the loader
                    MXMediaLoader *loader = [MXMediaManager existingUploaderWithId:uploadId];
                    if (loader)
                    {
                        [loader cancel];
                    }
                    // Hide the progress animation
                    roomBubbleTableViewCell.progressView.hidden = YES;
                    
                    self->currentAlert = nil;
                    
                    // Remove the outgoing message and its related cached file.
                    [[NSFileManager defaultManager] removeItemAtPath:roomBubbleTableViewCell.bubbleData.attachment.cacheFilePath error:nil];
                    [[NSFileManager defaultManager] removeItemAtPath:roomBubbleTableViewCell.bubbleData.attachment.thumbnailCachePath error:nil];
                    
                    // Cancel and remove the outgoing message
                    [self.roomDataSource.room cancelSendingOperation:selectedEvent.eventId];
                    [self.roomDataSource removeEventWithEventId:selectedEvent.eventId];
                    
                    [self cancelEventSelection];
                }]];
            }
        }
        
        if (attachment.type != MXKAttachmentTypeSticker)
        {
            if (BuildSettings.messageDetailsAllowShare)
            {
                [actionsMenu addAction:[UIAlertAction actionWithTitle:[VectorL10n roomEventActionShare]
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                    MXStrongifyAndReturnIfNil(self);
                    
                    [self cancelEventSelection];
                    
                    [self startActivityIndicator];
                    
                    MXWeakify(self);
                    [attachment prepareShare:^(NSURL *fileURL) {
                        MXStrongifyAndReturnIfNil(self);
                        
                        [self stopActivityIndicator];
                        
                        self->documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
                        [self->documentInteractionController setDelegate:self];
                        self->currentSharedAttachment = attachment;
                        
                        if (![self->documentInteractionController presentOptionsMenuFromRect:self.view.frame inView:self.view animated:YES])
                        {
                            self->documentInteractionController = nil;
                            [attachment onShareEnded];
                            self->currentSharedAttachment = nil;
                        }
                        
                    } failure:^(NSError *error) {
                        [self showError:error];
                        [self stopActivityIndicator];
                    }];
                    
                    // Start animation in case of download during attachment preparing
                    [roomBubbleTableViewCell startProgressUI];
                }]];
            }
        }
    }
    
    // Check status of the selected event
    if (selectedEvent.sentState == MXEventSentStateSent)
    {
        // Check whether download is in progress
        if (selectedEvent.isMediaAttachment)
        {
            NSString *downloadId = roomBubbleTableViewCell.bubbleData.attachment.downloadId;
            if ([MXMediaManager existingDownloaderWithIdentifier:downloadId])
            {
                [actionsMenu addAction:[UIAlertAction actionWithTitle:[VectorL10n roomEventActionCancelDownload]
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                    MXStrongifyAndReturnIfNil(self);
                    
                    [self cancelEventSelection];
                    
                    // Get again the loader
                    MXMediaLoader *loader = [MXMediaManager existingDownloaderWithIdentifier:downloadId];
                    if (loader)
                    {
                        [loader cancel];
                    }
                    // Hide the progress animation
                    roomBubbleTableViewCell.progressView.hidden = YES;
                }]];
            }
        }
        
        // Do not allow to redact the event that enabled encryption (m.room.encryption)
        // because it breaks everything
        if (selectedEvent.eventType != MXEventTypeRoomEncryption)
        {
            NSString *title;
            if (selectedEvent.eventType == MXEventTypePollStart)
            {
                title = [VectorL10n roomEventActionRemovePoll];
            }
            else
            {
                title = [VectorL10n roomEventActionRedact];
            }
            
            [actionsMenu addAction:[UIAlertAction actionWithTitle:title
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                MXStrongifyAndReturnIfNil(self);
                
                [self cancelEventSelection];
                
                [self startActivityIndicator];
                
                MXWeakify(self);
                [self.roomDataSource.room redactEvent:selectedEvent.eventId reason:nil success:^{
                    MXStrongifyAndReturnIfNil(self);
                    [self stopActivityIndicator];
                } failure:^(NSError *error) {
                    MXStrongifyAndReturnIfNil(self);
                    [self stopActivityIndicator];
                    
                    MXLogDebug(@"[RoomVC] Redact event (%@) failed", selectedEvent.eventId);
                    //Alert user
                    [self showError:error];
                }];
            }]];
        }
        
        if (selectedEvent.eventType == MXEventTypePollStart && [selectedEvent.sender isEqualToString:self.mainSession.myUser.userId]) {
            if ([self.delegate roomViewController:self canEndPollWithEventIdentifier:selectedEvent.eventId]) {
                [actionsMenu addAction:[UIAlertAction actionWithTitle:[VectorL10n roomEventActionEndPoll]
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                    MXStrongifyAndReturnIfNil(self);
                    
                    [self.delegate roomViewController:self endPollWithEventIdentifier:selectedEvent.eventId];
                    
                    [self hideContextualMenuAnimated:YES];
                }]];
            }
        }
        
        [actionsMenu addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction * action) {
            MXStrongifyAndReturnIfNil(self);
            
            [self hideContextualMenuAnimated:YES];
        }]];
        
        if (BuildSettings.messageDetailsAllowPermalink)
        {
            [actionsMenu addAction:[UIAlertAction actionWithTitle:[VectorL10n roomEventActionPermalink]
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                MXStrongifyAndReturnIfNil(self);
                
                [self cancelEventSelection];
                
                // Create a matrix.to permalink that is common to all matrix clients
                NSString *permalink = [MXTools permalinkToEvent:selectedEvent.eventId inRoom:selectedEvent.roomId];
                
                if (permalink)
                {
                    MXKPasteboardManager.shared.pasteboard.string = permalink;
                }
                else
                {
                    MXLogDebug(@"[RoomViewController] Contextual menu permalink action failed. Permalink is nil room id/event id: %@/%@", selectedEvent.roomId, selectedEvent.eventId);
                }
            }]];
        }
        
        // Add reaction history if event contains reactions
        if (roomBubbleTableViewCell.bubbleData.reactions[selectedEvent.eventId].aggregatedReactionsWithNonZeroCount)
        {
            [actionsMenu addAction:[UIAlertAction actionWithTitle:[VectorL10n roomEventActionReactionHistory]
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                MXStrongifyAndReturnIfNil(self);
                
                [self cancelEventSelection];
                
                // Show reaction history
                [self showReactionHistoryForEventId:selectedEvent.eventId animated:YES];
            }]];
        }
        
        if (BuildSettings.messageDetailsAllowViewSource)
        {
            [actionsMenu addAction:[UIAlertAction actionWithTitle:[VectorL10n roomEventActionViewSource]
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                MXStrongifyAndReturnIfNil(self);
                
                [self cancelEventSelection];
                
                // Display event details
                [self showEventDetails:selectedEvent];
            }]];
            
            
            // Add "View Decrypted Source" for e2ee event we can decrypt
            if (selectedEvent.isEncrypted && selectedEvent.clearEvent)
            {
                [actionsMenu addAction:[UIAlertAction actionWithTitle:[VectorL10n roomEventActionViewDecryptedSource]
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                    MXStrongifyAndReturnIfNil(self);
                    
                    [self cancelEventSelection];
                    
                    // Display clear event details
                    [self showEventDetails:selectedEvent.clearEvent];
                }]];
            }
        }
        
        if (![selectedEvent.sender isEqualToString:self.mainSession.myUser.userId] && RiotSettings.shared.roomContextualMenuShowReportContentOption)
        {
            [actionsMenu addAction:[UIAlertAction actionWithTitle:[VectorL10n roomEventActionReport]
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                MXStrongifyAndReturnIfNil(self);
                
                [self cancelEventSelection];
                
                // Prompt user to enter a description of the problem content.
                UIAlertController *reportReasonAlert = [UIAlertController alertControllerWithTitle:[VectorL10n roomEventActionReportPromptReason]
                                                                                           message:nil
                                                                                    preferredStyle:UIAlertControllerStyleAlert];
                
                [reportReasonAlert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                    textField.secureTextEntry = NO;
                    textField.placeholder = nil;
                    textField.keyboardType = UIKeyboardTypeDefault;
                }];
                
                MXWeakify(self);
                [reportReasonAlert addAction:[UIAlertAction actionWithTitle:[MatrixKitL10n ok] style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                    MXStrongifyAndReturnIfNil(self);
                    
                    NSString *text = [self->currentAlert textFields].firstObject.text;
                    self->currentAlert = nil;
                    
                    [self startActivityIndicator];
                    
                    MXWeakify(self);
                    [self.roomDataSource.room reportEvent:selectedEvent.eventId score:-100 reason:text success:^{
                        MXStrongifyAndReturnIfNil(self);
                        
                        [self stopActivityIndicator];
                        
                        // Prompt user to ignore content from this user
                        UIAlertController *ignoreUserAlert = [UIAlertController alertControllerWithTitle:[VectorL10n roomEventActionReportPromptIgnoreUser]
                                                                                                 message:nil
                                                                                          preferredStyle:UIAlertControllerStyleAlert];
                        
                        MXWeakify(self);
                        [ignoreUserAlert addAction:[UIAlertAction actionWithTitle:[MatrixKitL10n yes] style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                            
                            MXStrongifyAndReturnIfNil(self);
                            self->currentAlert = nil;
                            
                            [self startActivityIndicator];
                            
                            MXWeakify(self);
                            // Add the user to the blacklist: ignored users
                            [self.mainSession ignoreUsers:@[selectedEvent.sender] success:^{
                                MXStrongifyAndReturnIfNil(self);
                                [self stopActivityIndicator];
                            } failure:^(NSError *error) {
                                MXStrongifyAndReturnIfNil(self);
                                [self stopActivityIndicator];
                                
                                MXLogDebug(@"[RoomVC] Ignore user (%@) failed", selectedEvent.sender);
                                //Alert user
                                [self showError:error];
                            }];
                        }]];
                        
                        [ignoreUserAlert addAction:[UIAlertAction actionWithTitle:[MatrixKitL10n no] style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                            MXStrongifyAndReturnIfNil(self);
                            self->currentAlert = nil;
                        }]];
                        
                        [self presentViewController:ignoreUserAlert animated:YES completion:nil];
                        self->currentAlert = ignoreUserAlert;
                        
                    } failure:^(NSError *error) {
                        MXStrongifyAndReturnIfNil(self);
                        [self stopActivityIndicator];
                        
                        MXLogDebug(@"[RoomVC] Report event (%@) failed", selectedEvent.eventId);
                        //Alert user
                        [self showError:error];
                        
                    }];
                }]];
                
                [reportReasonAlert addAction:[UIAlertAction actionWithTitle:[MatrixKitL10n cancel] style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
                    MXStrongifyAndReturnIfNil(self);
                    self->currentAlert = nil;
                }]];
                
                [self presentViewController:reportReasonAlert animated:YES completion:nil];
                self->currentAlert = reportReasonAlert;
            }]];
        }
        
        if (!isJitsiCallEvent && self.roomDataSource.room.summary.isEncrypted)
        {
            [actionsMenu addAction:[UIAlertAction actionWithTitle:[VectorL10n roomEventActionViewEncryption]
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                MXStrongifyAndReturnIfNil(self);
                
                [self cancelEventSelection];
                
                // Display encryption details
                [self showEncryptionInformation:selectedEvent];
            }]];
        }
        
    }
    
    // Do not display empty action sheet
    if (actionsMenu.actions.count > 1)
    {
        NSInteger bubbleComponentIndex = [roomBubbleTableViewCell.bubbleData bubbleComponentIndexForEventId:selectedEvent.eventId];
        
        CGRect sourceRect = [roomBubbleTableViewCell componentFrameInContentViewForIndex:bubbleComponentIndex];
        
        [actionsMenu mxk_setAccessibilityIdentifier:@"RoomVCEventMenuAlert"];
        [actionsMenu popoverPresentationController].sourceView = roomBubbleTableViewCell;
        [actionsMenu popoverPresentationController].sourceRect = sourceRect;
        [self presentViewController:actionsMenu animated:animated completion:nil];
        currentAlert = actionsMenu;
    }
}

- (void)presentEventForwardingDialogForSelectedEvent:(MXEvent *)selectedEvent
{
    ForwardingShareItemSender *shareItemSender = [[ForwardingShareItemSender alloc] initWithEvent:selectedEvent];
    self.shareManager = [[ShareManager alloc] initWithShareItemSender:shareItemSender
                                                                 type:ShareManagerTypeForward];
    
    MXWeakify(self);
    [self.shareManager setCompletionCallback:^(ShareManagerResult result) {
        MXStrongifyAndReturnIfNil(self);
        if ([self.presentedViewController isEqual:self.shareManager.mainViewController])
        {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        self.shareManager = nil;
    }];
    
    [self presentViewController:self.shareManager.mainViewController animated:YES completion:nil];
}

- (BOOL)dataSource:(MXKDataSource *)dataSource shouldDoAction:(NSString *)actionIdentifier inCell:(id<MXKCellRendering>)cell userInfo:(NSDictionary *)userInfo defaultValue:(BOOL)defaultValue
{
    BOOL shouldDoAction = defaultValue;
    
    if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellShouldInteractWithURL])
    {
        // Try to catch universal link supported by the app
        NSURL *url = userInfo[kMXKRoomBubbleCellUrl];
        // Retrieve the type of interaction expected with the URL (See UITextItemInteraction)
        NSNumber *urlItemInteractionValue = userInfo[kMXKRoomBubbleCellUrlItemInteraction];
        
        RoomMessageURLType roomMessageURLType = RoomMessageURLTypeUnknown;
        
        if (url)
        {
            roomMessageURLType = [self.roomMessageURLParser parseURL:url];
        }
        
        // When a link refers to a room alias/id, a user id or an event id, the non-ASCII characters (like '#' in room alias) has been escaped
        // to be able to convert it into a legal URL string.
        NSString *absoluteURLString = [url.absoluteString stringByRemovingPercentEncoding];
        
        // If the link can be open it by the app, let it do
        if ([Tools isUniversalLink:url])
        {
            shouldDoAction = NO;
            
            [self handleUniversalLinkURL:url];
        }
        // Open a detail screen about the clicked user
        else if ([MXTools isMatrixUserIdentifier:absoluteURLString])
        {
            shouldDoAction = NO;
            
            NSString *userId = absoluteURLString;
            
            MXRoomMember* member = [self.roomDataSource.roomState.members memberWithUserId:userId];
            if (member)
            {
                // Use the room member detail VC for room members
                [self showMemberDetails:member];
            }
            else
            {
                // Use the contact detail VC for other users
                MXUser *user = [self.roomDataSource.room.mxSession userWithUserId:userId];
                if (user)
                {
                    selectedContact = [[MXKContact alloc] initMatrixContactWithDisplayName:((user.displayname.length > 0) ? user.displayname : user.userId) andMatrixID:user.userId];
                }
                else
                {
                    selectedContact = [[MXKContact alloc] initMatrixContactWithDisplayName:userId andMatrixID:userId];
                }
                [self performSegueWithIdentifier:@"showContactDetails" sender:self];
            }
        }
        // Open the clicked room
        else if ([MXTools isMatrixRoomIdentifier:absoluteURLString] || [MXTools isMatrixRoomAlias:absoluteURLString])
        {
            shouldDoAction = NO;
            
            NSString *roomIdOrAlias = absoluteURLString;
            
            // Open the room or preview it
            NSString *fragment = [NSString stringWithFormat:@"/room/%@", [MXTools encodeURIComponent:roomIdOrAlias]];
            
            [self handleUniversalLinkFragment:fragment fromURL:url];
        }
        // Preview the clicked group
        else if ([MXTools isMatrixGroupIdentifier:absoluteURLString])
        {
            shouldDoAction = NO;
            
            // Open the group or preview it
            NSString *fragment = [NSString stringWithFormat:@"/group/%@", [MXTools encodeURIComponent:absoluteURLString]];
            
            [self handleUniversalLinkFragment:fragment fromURL:url];
        }
        else if ([absoluteURLString hasPrefix:EventFormatterOnReRequestKeysLinkAction])
        {
            NSArray<NSString*> *arguments = [absoluteURLString componentsSeparatedByString:EventFormatterLinkActionSeparator];
            if (arguments.count > 1)
            {
                NSString *eventId = arguments[1];
                MXEvent *event = [self.roomDataSource eventWithEventId:eventId];
                
                if (event)
                {
                    [self reRequestKeysAndShowExplanationAlert:event];
                }
            }
        }
        else if ([absoluteURLString hasPrefix:EventFormatterEditedEventLinkAction])
        {
            NSArray<NSString*> *arguments = [absoluteURLString componentsSeparatedByString:EventFormatterLinkActionSeparator];
            if (arguments.count > 1)
            {
                NSString *eventId = arguments[1];
                [self showEditHistoryForEventId:eventId animated:YES];
            }
            shouldDoAction = NO;
        }
        else if (url && urlItemInteractionValue)
        {
            // Fallback case for external links
            switch (urlItemInteractionValue.integerValue) {
                case UITextItemInteractionInvokeDefaultAction:
                {
                    switch (roomMessageURLType) {
                        case RoomMessageURLTypeAppleDataDetector:
                            // Keep the default OS behavior on single tap when UITextView data detector detect a known type.
                            shouldDoAction = YES;
                            break;
                        case RoomMessageURLTypeDummy:
                            // Do nothing for dummy links
                            shouldDoAction = NO;
                            break;
                        default:
                        {
                            MXEvent *tappedEvent = userInfo[kMXKRoomBubbleCellEventKey];
                            NSString *format = tappedEvent.content[@"format"];
                            NSString *formattedBody = tappedEvent.content[@"formatted_body"];
                            //  if an html formatted body exists
                            if ([format isEqualToString:kMXRoomMessageFormatHTML] && formattedBody)
                            {
                                NSURL *visibleURL = [formattedBodyParser getVisibleURLForURL:url inFormattedBody:formattedBody];
                                
                                if (visibleURL && ![url isEqual:visibleURL])
                                {
                                    //  urls are different, show confirmation alert
                                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[VectorL10n externalLinkConfirmationTitle] message:[VectorL10n externalLinkConfirmationMessage:visibleURL.absoluteString :url.absoluteString] preferredStyle:UIAlertControllerStyleAlert];
                                    
                                    UIAlertAction *continueAction = [UIAlertAction actionWithTitle:[VectorL10n continue] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                        // Try to open the link
                                        [[UIApplication sharedApplication] vc_open:url completionHandler:^(BOOL success) {
                                            if (!success)
                                            {
                                                [self showUnableToOpenLinkErrorAlert];
                                            }
                                        }];
                                    }];
                                    
                                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[VectorL10n cancel] style:UIAlertActionStyleCancel handler:nil];
                                    
                                    [alert addAction:continueAction];
                                    [alert addAction:cancelAction];
                                    
                                    [self presentViewController:alert animated:YES completion:nil];
                                    return NO;
                                }
                            }
                            // Try to open the link
                            [[UIApplication sharedApplication] vc_open:url completionHandler:^(BOOL success) {
                                if (!success)
                                {
                                    [self showUnableToOpenLinkErrorAlert];
                                }
                            }];
                            shouldDoAction = NO;
                            break;
                        }
                    }
                }
                    break;
                case UITextItemInteractionPresentActions:
                {
                    // Retrieve the tapped event
                    MXEvent *tappedEvent = userInfo[kMXKRoomBubbleCellEventKey];
                    
                    if (tappedEvent)
                    {
                        // Long press on link, present room contextual menu.
                        [self showContextualMenuForEvent:tappedEvent fromSingleTapGesture:NO cell:cell animated:YES];
                    }
                    
                    shouldDoAction = NO;
                }
                    break;
                case UITextItemInteractionPreview:
                    // Force touch on link, let MXKRoomBubbleTableViewCell UITextView use default peek and pop behavior.
                    break;
                default:
                    break;
            }
        }
        else
        {
            [self showUnableToOpenLinkErrorAlert];
        }
    }
    
    return shouldDoAction;
}

- (void)selectEventWithId:(NSString*)eventId
{
    [self selectEventWithId:eventId inputToolBarSendMode:RoomInputToolbarViewSendModeSend showTimestamp:YES];
}

- (void)selectEventWithId:(NSString*)eventId inputToolBarSendMode:(RoomInputToolbarViewSendMode)inputToolBarSendMode showTimestamp:(BOOL)showTimestamp
{
    [self setInputToolBarSendMode:inputToolBarSendMode forEventWithId:eventId];
    
    customizedRoomDataSource.showBubbleDateTimeOnSelection = showTimestamp;
    customizedRoomDataSource.selectedEventId = eventId;
    
    // Force table refresh
    [self dataSource:self.roomDataSource didCellChange:nil];
}

- (void)cancelEventSelection
{
    [self setInputToolBarSendMode:RoomInputToolbarViewSendModeSend forEventWithId:nil];
    
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
    
    customizedRoomDataSource.showBubbleDateTimeOnSelection = YES;
    customizedRoomDataSource.selectedEventId = nil;
    
    [self restoreTextMessageBeforeEditing];
    
    // Force table refresh
    [self dataSource:self.roomDataSource didCellChange:nil];
}

- (void)showUnableToOpenLinkErrorAlert
{
    [self showAlertWithTitle:[MatrixKitL10n error]
                     message:[VectorL10n roomMessageUnableOpenLinkErrorMessage]];
}

- (void)editEventContentWithId:(NSString*)eventId
{
    MXEvent *event = [self.roomDataSource eventWithEventId:eventId];
    
    RoomInputToolbarView *roomInputToolbarView = [self inputToolbarViewAsRoomInputToolbarView];
    
    if (roomInputToolbarView)
    {
        self.textMessageBeforeEditing = roomInputToolbarView.textMessage;
        roomInputToolbarView.textMessage = [self.roomDataSource editableTextMessageForEvent:event];
    }
    
    [self selectEventWithId:eventId inputToolBarSendMode:RoomInputToolbarViewSendModeEdit showTimestamp:YES];
}

- (void)restoreTextMessageBeforeEditing
{
    RoomInputToolbarView *roomInputToolbarView = [self inputToolbarViewAsRoomInputToolbarView];
    
    if (self.textMessageBeforeEditing)
    {
        roomInputToolbarView.textMessage = self.textMessageBeforeEditing;
    }
    
    self.textMessageBeforeEditing = nil;
}

- (RoomInputToolbarView*)inputToolbarViewAsRoomInputToolbarView
{
    RoomInputToolbarView *roomInputToolbarView;
    
    if (self.inputToolbarView && [self.inputToolbarView isKindOfClass:[RoomInputToolbarView class]])
    {
        roomInputToolbarView = (RoomInputToolbarView*)self.inputToolbarView;
    }
    
    return roomInputToolbarView;
}

#pragma mark - RoomDataSourceDelegate

- (void)roomDataSource:(RoomDataSource *)roomDataSource didUpdateEncryptionTrustLevel:(RoomEncryptionTrustLevel)roomEncryptionTrustLevel
{
    [self updateInputToolbarEncryptionDecoration];
    [self updateTitleViewEncryptionDecoration];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Keep ref on destinationViewController
    [super prepareForSegue:segue sender:sender];
    
    id pushedViewController = [segue destinationViewController];
    
    if ([[segue identifier] isEqualToString:@"showRoomSearch"])
    {
        // Dismiss keyboard
        [self dismissKeyboard];
        
        RoomSearchViewController* roomSearchViewController = (RoomSearchViewController*)pushedViewController;
        // Add the current data source to be able to search messages.
        roomSearchViewController.roomDataSource = self.roomDataSource;
    }
    else if ([[segue identifier] isEqualToString:@"showContactDetails"])
    {
        if (selectedContact)
        {
            ContactDetailsViewController *contactDetailsViewController = segue.destinationViewController;
            contactDetailsViewController.enableVoipCall = NO;
            contactDetailsViewController.contact = selectedContact;
            
            selectedContact = nil;
        }
    }
    else if ([[segue identifier] isEqualToString:@"showUnknownDevices"])
    {
        if (unknownDevices)
        {
            UsersDevicesViewController *usersDevicesViewController = (UsersDevicesViewController *)segue.destinationViewController.childViewControllers.firstObject;
            [usersDevicesViewController displayUsersDevices:unknownDevices andMatrixSession:self.roomDataSource.mxSession onComplete:nil];
            
            unknownDevices = nil;
        }
    }
    
    // Hide back button title
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
}

#pragma mark - VoIP

- (void)placeCallWithVideo:(BOOL)video
{
    __weak __typeof(self) weakSelf = self;
    
    // Check app permissions first
    [MXKTools checkAccessForCall:video
     manualChangeMessageForAudio:[MatrixKitL10n microphoneAccessNotGrantedForCall:AppInfo.current.displayName]
     manualChangeMessageForVideo:[MatrixKitL10n cameraAccessNotGrantedForCall:AppInfo.current.displayName]
       showPopUpInViewController:self completionHandler:^(BOOL granted) {
        
        if (weakSelf)
        {
            typeof(self) self = weakSelf;
            
            if (granted)
            {
                if (video)
                {
                    [self placeCallWithVideo2:video];
                }
                else if (self.mainSession.callManager.supportsPSTN)
                {
                    [self showVoiceCallActionSheet];
                }
                else
                {
                    [self placeCallWithVideo2:NO];
                }
            }
            else
            {
                MXLogDebug(@"RoomViewController: Warning: The application does not have the permission to place the call");
            }
        }
    }];
}

- (void)showVoiceCallActionSheet
{
    // Ask the user the kind of the call: voice or dialpad?
    UIAlertController *callActionSheet = [UIAlertController alertControllerWithTitle:nil
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    
    __weak typeof(self) weakSelf = self;
    [callActionSheet addAction:[UIAlertAction actionWithTitle:[VectorL10n roomPlaceVoiceCall]
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action) {
        
        if (weakSelf)
        {
            typeof(self) self = weakSelf;
            self->currentAlert = nil;
            
            [self placeCallWithVideo2:NO];
        }
        
    }]];
    
    [callActionSheet addAction:[UIAlertAction actionWithTitle:[VectorL10n roomOpenDialpad]
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action) {
        
        if (weakSelf)
        {
            typeof(self) self = weakSelf;
            self->currentAlert = nil;
            
            [self openDialpad];
        }
        
    }]];
    
    [callActionSheet addAction:[UIAlertAction actionWithTitle:[MatrixKitL10n cancel]
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction * action) {
        
        if (weakSelf)
        {
            typeof(self) self = weakSelf;
            self->currentAlert = nil;
        }
        
    }]];
    
    [callActionSheet popoverPresentationController].barButtonItem = self.navigationItem.rightBarButtonItems.firstObject;
    [callActionSheet popoverPresentationController].permittedArrowDirections = UIPopoverArrowDirectionUp;
    [self presentViewController:callActionSheet animated:YES completion:nil];
    currentAlert = callActionSheet;
}

- (void)placeCallWithVideo2:(BOOL)video
{
    Widget *jitsiWidget = [customizedRoomDataSource jitsiWidget];
    if (jitsiWidget)
    {
        //  If there is already a Jitsi call, join it
        [self showJitsiCallWithWidget:jitsiWidget];
    }
    else
    {
        if (self.roomDataSource.room.summary.membersCount.joined == 2 && self.roomDataSource.room.isDirect)
        {
            //  Matrix call
            [self.roomDataSource.room placeCallWithVideo:video success:nil failure:nil];
        }
        else
        {
            //  Jitsi call
            if (self.canEditJitsiWidget)
            {
                //  User has right to add a Jitsi widget
                //  Create the Jitsi widget and open it directly
                [self startActivityIndicator];
                
                MXWeakify(self);
                
                [[WidgetManager sharedManager] createJitsiWidgetInRoom:self.roomDataSource.room
                                                             withVideo:video
                                                               success:^(Widget *jitsiWidget)
                 {
                    MXStrongifyAndReturnIfNil(self);
                    [self stopActivityIndicator];
                    
                    [self showJitsiCallWithWidget:jitsiWidget];
                }
                                                               failure:^(NSError *error)
                 {
                    MXStrongifyAndReturnIfNil(self);
                    [self stopActivityIndicator];
                    
                    [self showJitsiErrorAsAlert:error];
                }];
            }
            else
            {
                //  Insufficient privileges to add a Jitsi widget
                MXWeakify(self);
                [currentAlert dismissViewControllerAnimated:NO completion:nil];
                
                UIAlertController *unprivilegedAlert = [UIAlertController alertControllerWithTitle:[VectorL10n roomNoPrivilegesToCreateGroupCall]
                                                                                           message:nil
                                                                                    preferredStyle:UIAlertControllerStyleAlert];
                
                [unprivilegedAlert addAction:[UIAlertAction actionWithTitle:[MatrixKitL10n ok]
                                                                      style:UIAlertActionStyleDefault
                                                                    handler:^(UIAlertAction * action)
                                         {
                    MXStrongifyAndReturnIfNil(self);
                    self->currentAlert = nil;
                }]];
                
                [unprivilegedAlert mxk_setAccessibilityIdentifier:@"RoomVCCallAlert"];
                [self presentViewController:unprivilegedAlert animated:YES completion:nil];
                currentAlert = unprivilegedAlert;
            }
        }
    }
}

- (void)hangupCall
{
    MXCall *callInRoom = [self.roomDataSource.mxSession.callManager callInRoom:self.roomDataSource.roomId];
    if (callInRoom)
    {
        [callInRoom hangup];
    }
    else if (self.isRoomHavingAJitsiCall)
    {
        [self endActiveJitsiCall];
        [self reloadBubblesTable:YES];
    }
    
    [self refreshActivitiesViewDisplay];
    [self refreshRoomInputToolbar];
}

#pragma mark - MXKRoomInputToolbarViewDelegate

- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView isTyping:(BOOL)typing
{
    [super roomInputToolbarView:toolbarView isTyping:typing];
    
    // Cancel potential selected event (to leave edition mode)
    NSString *selectedEventId = customizedRoomDataSource.selectedEventId;
    if (typing && selectedEventId && ![self.roomDataSource canReplyToEventWithId:selectedEventId])
    {
        [self cancelEventSelection];
    }
}

- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView heightDidChanged:(CGFloat)height completion:(void (^)(BOOL finished))completion
{
    if (self.roomInputToolbarContainerHeightConstraint.constant != height)
    {
        // Hide temporarily the placeholder to prevent its distorsion during height animation
        if (!savedInputToolbarPlaceholder)
        {
            savedInputToolbarPlaceholder = toolbarView.placeholder.length ? toolbarView.placeholder : @"";
        }
        toolbarView.placeholder = nil;
        
        [super roomInputToolbarView:toolbarView heightDidChanged:height completion:^(BOOL finished) {
            
            if (completion)
            {
                completion (finished);
            }
            
            // Consider here the saved placeholder only if no new placeholder has been defined during the height animation.
            if (!toolbarView.placeholder)
            {
                // Restore the placeholder if any
                toolbarView.placeholder = self->savedInputToolbarPlaceholder.length ? self->savedInputToolbarPlaceholder : nil;
            }
            self->savedInputToolbarPlaceholder = nil;
        }];
    }
}

- (void)roomInputToolbarViewDidTapCancel:(MXKRoomInputToolbarView*)toolbarView
{
    [self cancelEventSelection];
}
 
- (void)roomInputToolbarViewDidChangeTextMessage:(MXKRoomInputToolbarView *)toolbarView
{
    [self.userSuggestionCoordinator processTextMessage:toolbarView.textMessage];
}

#pragma mark - MXKRoomMemberDetailsViewControllerDelegate

- (void)roomMemberDetailsViewController:(MXKRoomMemberDetailsViewController *)roomMemberDetailsViewController startChatWithMemberId:(NSString *)matrixId completion:(void (^)(void))completion
{
    [self startChatWithUserId:matrixId completion:completion];
}

- (void)roomMemberDetailsViewController:(MXKRoomMemberDetailsViewController *)roomMemberDetailsViewController mention:(MXRoomMember*)member
{
    [self mention:member];
}

#pragma mark - Action

- (IBAction)onVoiceCallPressed:(id)sender
{
    if (self.isCallActive)
    {
        [self hangupCall];
    }
    else
    {
        [self placeCallWithVideo:NO];
    }
}

- (IBAction)onVideoCallPressed:(id)sender
{
    [self placeCallWithVideo:YES];
}

- (IBAction)onIntegrationsPressed:(id)sender
{
    WidgetPickerViewController *widgetPicker = [[WidgetPickerViewController alloc] initForMXSession:self.roomDataSource.mxSession
                                                                                             inRoom:self.roomDataSource.roomId];
    
    [widgetPicker showInViewController:self];
}

- (void)scrollToBottomAction:(id)sender
{
    [self goBackToLive];
}

- (IBAction)onButtonPressed:(id)sender
{
    if (sender == self.jumpToLastUnreadButton)
    {
        // Dismiss potential keyboard.
        [self dismissKeyboard];
        
        // Jump to the last unread event by using a temporary room data source initialized with the last unread event id.
        MXWeakify(self);
        [RoomDataSource loadRoomDataSourceWithRoomId:self.roomDataSource.roomId initialEventId:self.roomDataSource.room.accountData.readMarkerEventId andMatrixSession:self.mainSession onComplete:^(id roomDataSource) {
            MXStrongifyAndReturnIfNil(self);
            
            [roomDataSource finalizeInitialization];
            
            // Center the bubbles table content on the bottom of the read marker event in order to display correctly the read marker view.
            self.centerBubblesTableViewContentOnTheInitialEventBottom = YES;
            [self displayRoom:roomDataSource];
            
            // Give the data source ownership to the room view controller.
            self.hasRoomDataSourceOwnership = YES;
        }];
    }
    else if (sender == self.resetReadMarkerButton)
    {
        // Move the read marker to the current read receipt position.
        [self.roomDataSource.room forgetReadMarker];
        
        // Hide the banner
        self.jumpToLastUnreadBannerContainer.hidden = YES;
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = ThemeService.shared.theme.backgroundColor;
    
    // Update the selected background view
    if (ThemeService.shared.theme.selectedBackgroundColor)
    {
        cell.selectedBackgroundView = [[UIView alloc] init];
        cell.selectedBackgroundView.backgroundColor = ThemeService.shared.theme.selectedBackgroundColor;
    }
    else
    {
        if (tableView.style == UITableViewStylePlain)
        {
            cell.selectedBackgroundView = nil;
        }
        else
        {
            cell.selectedBackgroundView.backgroundColor = nil;
        }
    }
    
    if ([cell isKindOfClass:MXKRoomBubbleTableViewCell.class])
    {
        MXKRoomBubbleTableViewCell *roomBubbleTableViewCell = (MXKRoomBubbleTableViewCell*)cell;
        if (roomBubbleTableViewCell.readMarkerView)
        {
            readMarkerTableViewCell = roomBubbleTableViewCell;
            
            [self checkReadMarkerVisibility];
        }
    }
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (cell == readMarkerTableViewCell)
    {
        readMarkerTableViewCell = nil;
    }
    
    [super tableView:tableView didEndDisplayingCell:cell forRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

#pragma mark -

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [super scrollViewDidScroll:scrollView];
    
    [self checkReadMarkerVisibility];
    
    // Switch back to the live mode when the user scrolls to the bottom of the non live timeline.
    if (!self.roomDataSource.isLive && ![self isRoomPreview])
    {
        CGFloat contentBottomPosY = self.bubblesTableView.contentOffset.y + self.bubblesTableView.frame.size.height - self.bubblesTableView.adjustedContentInset.bottom;
        if (contentBottomPosY >= self.bubblesTableView.contentSize.height && ![self.roomDataSource.timeline canPaginate:MXTimelineDirectionForwards])
        {
            [self goBackToLive];
        }
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if ([MXKRoomViewController instancesRespondToSelector:@selector(scrollViewWillBeginDragging:)])
    {
        [super scrollViewWillBeginDragging:scrollView];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if ([MXKRoomViewController instancesRespondToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)])
    {
        [super scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    }
    
    if (decelerate == NO)
    {
        // Handle swipe on expanded header
        [self onScrollViewDidEndScrolling:scrollView];
        
        [self refreshActivitiesViewDisplay];
        [self refreshJumpToLastUnreadBannerDisplay];
    }
    else
    {
        // Dispatch async the expanded header handling in order to let the deceleration go first.
        dispatch_async(dispatch_get_main_queue(), ^{
            
            // Handle swipe on expanded header
            [self onScrollViewDidEndScrolling:scrollView];
            
        });
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ([MXKRoomViewController instancesRespondToSelector:@selector(scrollViewDidEndDecelerating:)])
    {
        [super scrollViewDidEndDecelerating:scrollView];
    }
    
    [self refreshActivitiesViewDisplay];
    [self refreshJumpToLastUnreadBannerDisplay];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    if ([MXKRoomViewController instancesRespondToSelector:@selector(scrollViewDidEndScrollingAnimation:)])
    {
        [super scrollViewDidEndScrollingAnimation:scrollView];
    }
    
    [self refreshActivitiesViewDisplay];
    [self refreshJumpToLastUnreadBannerDisplay];
}

- (void)onScrollViewDidEndScrolling:(UIScrollView *)scrollView
{
    
}

#pragma mark - MXKRoomTitleViewDelegate

- (BOOL)roomTitleViewShouldBeginEditing:(MXKRoomTitleView*)titleView
{
    // Disable room name edition
    return NO;
}

#pragma mark - RoomTitleViewTapGestureDelegate

- (void)roomTitleView:(RoomTitleView*)titleView recognizeTapGesture:(UITapGestureRecognizer*)tapGestureRecognizer
{
    UIView *tappedView = tapGestureRecognizer.view;
    
    if (tappedView == titleView.titleMask)
    {
        [self showRoomInfo];
    }
    else if (tappedView == previewHeader.rightButton)
    {
        // 'Join' button has been pressed
        if (!roomPreviewData)
        {
            [self joinRoom:^(MXKRoomViewControllerJoinRoomResult result) {
                switch (result)
                {
                    case MXKRoomViewControllerJoinRoomResultSuccess:
                        [self refreshRoomTitle];
                        break;
                    case MXKRoomViewControllerJoinRoomResultFailureRoomEmpty:
                        [self declineRoomInvitation];
                        break;
                    default:
                        break;
                }
            }];
            
            return;
        }
        
        // Attempt to join the room (keep reference on the potential eventId, the preview data will be removed automatically in case of success).
        NSString *eventId = roomPreviewData.eventId;
        
        // We promote here join by room alias instead of room id when an alias is available.
        NSString *roomIdOrAlias = roomPreviewData.roomId;
        
        if (roomPreviewData.roomCanonicalAlias.length)
        {
            roomIdOrAlias = roomPreviewData.roomCanonicalAlias;
        }
        else if (roomPreviewData.roomAliases.count)
        {
            roomIdOrAlias = roomPreviewData.roomAliases.firstObject;
        }
        
        // Note in case of simple link to a room the signUrl param is nil
        [self joinRoomWithRoomIdOrAlias:roomIdOrAlias viaServers:roomPreviewData.viaServers
                             andSignUrl:roomPreviewData.emailInvitation.signUrl
                             completion:^(MXKRoomViewControllerJoinRoomResult result) {
            
            switch (result)
            {
                case MXKRoomViewControllerJoinRoomResultSuccess:
                {
                    // If an event was specified, replace the datasource by a non live datasource showing the event
                    if (eventId)
                    {
                        MXWeakify(self);
                        [RoomDataSource loadRoomDataSourceWithRoomId:self.roomDataSource.roomId initialEventId:eventId andMatrixSession:self.mainSession onComplete:^(id roomDataSource) {
                            MXStrongifyAndReturnIfNil(self);
                            
                            [roomDataSource finalizeInitialization];
                            ((RoomDataSource*)roomDataSource).markTimelineInitialEvent = YES;
                            
                            [self displayRoom:roomDataSource];
                            
                            self.hasRoomDataSourceOwnership = YES;
                        }];
                    }
                    else
                    {
                        // Enable back the text input
                        [self setRoomInputToolbarViewClass:RoomInputToolbarView.class];
                        [self updateInputToolBarViewHeight];
                        
                        // And the extra area
                        [self setRoomActivitiesViewClass:RoomActivitiesView.class];
                        
                        [self refreshRoomTitle];
                        [self refreshRoomInputToolbar];
                    }
                    break;
                }
                case MXKRoomViewControllerJoinRoomResultFailureRoomEmpty:
                    [self declineRoomInvitation];
                    break;
                default:
                    break;
            }
        }];
    }
    else if (tappedView == previewHeader.leftButton)
    {
        [self declineRoomInvitation];
    }
}

- (void)declineRoomInvitation
{
    // 'Decline' button has been pressed
    if (roomPreviewData)
    {
        [self roomPreviewDidTapCancelAction];
    }
    else
    {
        [self startActivityIndicator];
        
        [self.roomDataSource.room leave:^{
            
            [self stopActivityIndicator];
            
            // We remove the current view controller.
            // Pop to homes view controller
            [[AppDelegate theDelegate] restoreInitialDisplay:^{}];
            
        } failure:^(NSError *error) {
            
            [self stopActivityIndicator];
            MXLogDebug(@"[RoomVC] Failed to reject an invited room (%@) failed", self.roomDataSource.room.roomId);
            
        }];
    }
}

#pragma mark - Typing management

- (void)removeTypingNotificationsListener
{
    if (self.roomDataSource)
    {
        // Remove the previous live listener
        if (typingNotifListener)
        {
            MXWeakify(self);
            [self.roomDataSource.room liveTimeline:^(MXEventTimeline *liveTimeline) {
                MXStrongifyAndReturnIfNil(self);
                
                [liveTimeline removeListener:self->typingNotifListener];
                self->typingNotifListener = nil;
            }];
        }
    }
    
    currentTypingUsers = nil;
}

- (void)listenTypingNotifications
{
    if (self.roomDataSource)
    {
        // Add typing notification listener
        MXWeakify(self);
        self->typingNotifListener = [self.roomDataSource.room listenToEventsOfTypes:@[kMXEventTypeStringTypingNotification] onEvent:^(MXEvent *event, MXTimelineDirection direction, MXRoomState *roomState) {
            MXStrongifyAndReturnIfNil(self);
            
            // Handle only live events
            if (direction == MXTimelineDirectionForwards)
            {
                // Retrieve typing users list
                NSMutableArray *typingUsers = [NSMutableArray arrayWithArray:self.roomDataSource.room.typingUsers];
                // Remove typing info for the current user
                NSUInteger index = [typingUsers indexOfObject:self.mainSession.myUser.userId];
                if (index != NSNotFound)
                {
                    [typingUsers removeObjectAtIndex:index];
                }
                
                // Ignore this notification if both arrays are empty
                if (self->currentTypingUsers.count || typingUsers.count)
                {
                    self->currentTypingUsers = typingUsers;
                    [self refreshActivitiesViewDisplay];
                }
            }
        }];
        
        // Retrieve the current typing users list
        NSMutableArray *typingUsers = [NSMutableArray arrayWithArray:self.roomDataSource.room.typingUsers];
        // Remove typing info for the current user
        NSUInteger index = [typingUsers indexOfObject:self.mainSession.myUser.userId];
        if (index != NSNotFound)
        {
            [typingUsers removeObjectAtIndex:index];
        }
        currentTypingUsers = typingUsers;
        [self refreshActivitiesViewDisplay];
    }
}

- (void)refreshTypingNotification
{
    RoomDataSource *roomDataSource = (RoomDataSource *) self.roomDataSource;
    BOOL needsUpdate = currentTypingUsers.count != roomDataSource.currentTypingUsers.count;

    NSMutableArray *typingUsers = [NSMutableArray new];
    for (NSUInteger i = 0 ; i < currentTypingUsers.count ; i++) {
        NSString *userId = currentTypingUsers[i];
        MXRoomMember* member = [self.roomDataSource.roomState.members memberWithUserId:userId];
        TypingUserInfo *userInfo;
        if (member)
        {
            userInfo = [[TypingUserInfo alloc] initWithMember: member];
        }
        else
        {
            userInfo = [[TypingUserInfo alloc] initWithUserId: userId];
        }
        [typingUsers addObject:userInfo];
        needsUpdate = needsUpdate || userInfo.userId != ((MXRoomMember *) roomDataSource.currentTypingUsers[i]).userId;
    }

    if (needsUpdate)
    {
//        BOOL needsReload = roomDataSource.currentTypingUsers == nil;
        // Quick fix for https://github.com/vector-im/element-ios/issues/4230
        BOOL needsReload = YES;
        roomDataSource.currentTypingUsers = typingUsers;
        if (needsReload)
        {
            [self.bubblesTableView reloadData];
        }
        else
        {
            NSInteger count = [self.bubblesTableView numberOfRowsInSection:0];
            NSIndexPath *lastIndexPath = [NSIndexPath indexPathForRow:count - 1 inSection:0];
            [self.bubblesTableView reloadRowsAtIndexPaths:@[lastIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
        
        if (self.isScrollToBottomHidden
            && !self.bubblesTableView.isDragging
            && !self.bubblesTableView.isDecelerating)
        {
            NSInteger count = [self.bubblesTableView numberOfRowsInSection:0];
            if (count)
            {
                [self scrollBubblesTableViewToBottomAnimated:YES];
            }
        }
    }
}

#pragma mark - Call notifications management

- (void)removeCallNotificationsListeners
{
    if (kMXCallStateDidChangeObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kMXCallStateDidChangeObserver];
        kMXCallStateDidChangeObserver = nil;
    }
    if (kMXCallManagerConferenceStartedObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kMXCallManagerConferenceStartedObserver];
        kMXCallManagerConferenceStartedObserver = nil;
    }
    if (kMXCallManagerConferenceFinishedObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kMXCallManagerConferenceFinishedObserver];
        kMXCallManagerConferenceFinishedObserver = nil;
    }
}

- (void)listenCallNotifications
{
    MXWeakify(self);
    
    kMXCallStateDidChangeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXCallStateDidChange object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXStrongifyAndReturnIfNil(self);
        
        MXCall *call = notif.object;
        if ([call.room.roomId isEqualToString:self->customizedRoomDataSource.roomId])
        {
            [self refreshActivitiesViewDisplay];
            [self refreshRoomInputToolbar];
        }
    }];
    kMXCallManagerConferenceStartedObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXCallManagerConferenceStarted object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXStrongifyAndReturnIfNil(self);
        
        NSString *roomId = notif.object;
        if ([roomId isEqualToString:self->customizedRoomDataSource.roomId])
        {
            [self refreshActivitiesViewDisplay];
        }
    }];
    kMXCallManagerConferenceFinishedObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXCallManagerConferenceFinished object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXStrongifyAndReturnIfNil(self);
        
        NSString *roomId = notif.object;
        if ([roomId isEqualToString:self->customizedRoomDataSource.roomId])
        {
            [self refreshActivitiesViewDisplay];
            [self refreshRoomInputToolbar];
        }
    }];
}


#pragma mark - Server notices management

- (void)removeServerNoticesListener
{
    if (serverNotices)
    {
        [serverNotices close];
        serverNotices = nil;
    }
}

- (void)listenToServerNotices
{
    if (!serverNotices)
    {
        serverNotices = [[MXServerNotices alloc] initWithMatrixSession:self.roomDataSource.mxSession];
        serverNotices.delegate = self;
    }
}

- (void)serverNoticesDidChangeState:(MXServerNotices *)serverNotices
{
    [self refreshActivitiesViewDisplay];
}

#pragma mark - Widget notifications management

- (void)removeWidgetNotificationsListeners
{
    if (kMXKWidgetManagerDidUpdateWidgetObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kMXKWidgetManagerDidUpdateWidgetObserver];
        kMXKWidgetManagerDidUpdateWidgetObserver = nil;
    }
}

- (void)listenWidgetNotifications
{
    MXWeakify(self);
    
    kMXKWidgetManagerDidUpdateWidgetObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kWidgetManagerDidUpdateWidgetNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXStrongifyAndReturnIfNil(self);
        
        Widget *widget = notif.object;
        if (widget.mxSession == self.roomDataSource.mxSession
            && [widget.roomId isEqualToString:self->customizedRoomDataSource.roomId])
        {
            //  Call button update
            [self refreshRoomTitle];
            //  Remove Jitsi widget view update
            [self refreshRemoveJitsiWidgetView];
        }
    }];
}

- (void)showJitsiErrorAsAlert:(NSError*)error
{
    // Customise the error for permission issues
    if ([error.domain isEqualToString:WidgetManagerErrorDomain] && error.code == WidgetManagerErrorCodeNotEnoughPower)
    {
        error = [NSError errorWithDomain:error.domain
                                    code:error.code
                                userInfo:@{
                                    NSLocalizedDescriptionKey: [VectorL10n roomConferenceCallNoPower]
                                }];
    }
    
    // Alert user
    [self showError:error];
}

- (NSUInteger)widgetsCount:(BOOL)includeUserWidgets
{
    NSUInteger widgetsCount = [[WidgetManager sharedManager] widgetsNotOfTypes:@[kWidgetTypeJitsiV1, kWidgetTypeJitsiV2]
                                                                        inRoom:self.roomDataSource.room
                                                                 withRoomState:self.roomDataSource.roomState].count;
    if (includeUserWidgets)
    {
        widgetsCount += [[WidgetManager sharedManager] userWidgets:self.roomDataSource.room.mxSession].count;
    }
    
    return widgetsCount;
}

#pragma mark - Unreachable Network Handling

- (void)refreshActivitiesViewDisplay
{
    if ([self.activitiesView isKindOfClass:RoomActivitiesView.class])
    {
        RoomActivitiesView *roomActivitiesView = (RoomActivitiesView*)self.activitiesView;
        
        // Reset gesture recognizers
        while (roomActivitiesView.gestureRecognizers.count)
        {
            [roomActivitiesView removeGestureRecognizer:roomActivitiesView.gestureRecognizers[0]];
        }
        
        if ([self.roomDataSource.mxSession.syncError.errcode isEqualToString:kMXErrCodeStringResourceLimitExceeded])
        {
            self.activitiesViewExpanded = YES;
            [roomActivitiesView showResourceLimitExceededError:self.roomDataSource.mxSession.syncError.userInfo onAdminContactTapped:^(NSURL *adminContactURL) {
                [[UIApplication sharedApplication] vc_open:adminContactURL completionHandler:^(BOOL success) {
                    if (!success)
                    {
                        MXLogDebug(@"[RoomVC] refreshActivitiesViewDisplay: adminContact(%@) cannot be opened", adminContactURL);
                    }
                }];
            }];
        }
        else if ([AppDelegate theDelegate].isOffline)
        {
            self.activitiesViewExpanded = YES;
            [roomActivitiesView displayNetworkErrorNotification:[VectorL10n roomOfflineNotification]];
        }
        else if (customizedRoomDataSource.roomState.isObsolete)
        {
            self.activitiesViewExpanded = YES;
            MXWeakify(self);
            [roomActivitiesView displayRoomReplacementWithRoomLinkTappedHandler:^{
                MXStrongifyAndReturnIfNil(self);
                
                MXEvent *stoneTombEvent = [self->customizedRoomDataSource.roomState stateEventsWithType:kMXEventTypeStringRoomTombStone].lastObject;
                
                NSString *replacementRoomId = self->customizedRoomDataSource.roomState.tombStoneContent.replacementRoomId;
                if ([self.roomDataSource.mxSession roomWithRoomId:replacementRoomId])
                {
                    // Open the room if it is already joined
                    [self showRoomWithId:replacementRoomId];
                }
                else
                {
                    // Else auto join it via the server that sent the event
                    MXLogDebug(@"[RoomVC] Auto join an upgraded room: %@ -> %@. Sender: %@",                              self->customizedRoomDataSource.roomState.roomId,
                          replacementRoomId, stoneTombEvent.sender);
                    
                    NSString *viaSenderServer = [MXTools serverNameInMatrixIdentifier:stoneTombEvent.sender];
                    
                    if (viaSenderServer)
                    {
                        [self startActivityIndicator];
                        [self.roomDataSource.mxSession joinRoom:replacementRoomId viaServers:@[viaSenderServer] success:^(MXRoom *room) {
                            [self stopActivityIndicator];

                            [self showRoomWithId:replacementRoomId];
                            
                        } failure:^(NSError *error) {
                            [self stopActivityIndicator];
                            
                            MXLogDebug(@"[RoomVC] Failed to join an upgraded room. Error: %@",
                                  error);
                            [self showError:error];
                        }];
                    }
                }
            }];
        }
        else if ([self checkUnsentMessages] == NO)
        {
            // Show "scroll to bottom" icon when the most recent message is not visible,
            // or when the timelime is not live (this icon is used to go back to live).
            // Note: we check if `currentEventIdAtTableBottom` is set to know whether the table has been rendered at least once.
            if (!self.roomDataSource.isLive || (currentEventIdAtTableBottom && [self isBubblesTableScrollViewAtTheBottom] == NO))
            {
                if (self.roomDataSource.room)
                {
                    // Retrieve the unread messages count
                    NSUInteger unreadCount = self.roomDataSource.room.summary.localUnreadEventCount;
                    
                    self.scrollToBottomBadgeLabel.text = unreadCount ? [NSString stringWithFormat:@"%lu", unreadCount] : nil;
                    self.scrollToBottomHidden = NO;
                }
                else
                {
                    //  will be here for left rooms
                    self.scrollToBottomBadgeLabel.text = nil;
                    self.scrollToBottomHidden = YES;
                }
            }
            else if (serverNotices.usageLimit && serverNotices.usageLimit.isServerNoticeUsageLimit)
            {
                self.scrollToBottomHidden = YES;
                self.activitiesViewExpanded = YES;
                [roomActivitiesView showResourceUsageLimitNotice:serverNotices.usageLimit onAdminContactTapped:^(NSURL *adminContactURL) {
                    [[UIApplication sharedApplication] vc_open:adminContactURL completionHandler:^(BOOL success) {
                        if (!success)
                        {
                            MXLogDebug(@"[RoomVC] refreshActivitiesViewDisplay: adminContact(%@) cannot be opened", adminContactURL);
                        }
                    }];
                }];
            }
            else
            {
                self.scrollToBottomHidden = YES;
                self.activitiesViewExpanded = NO;
                [self refreshTypingNotification];
            }
        }
        
        // Recognize swipe downward to dismiss keyboard if any
        UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(onSwipeGesture:)];
        [swipe setNumberOfTouchesRequired:1];
        [swipe setDirection:UISwipeGestureRecognizerDirectionDown];
        [roomActivitiesView addGestureRecognizer:swipe];
    }
}

- (void)goBackToLive
{
    if (self.roomDataSource.isLive)
    {
        // Enable the read marker display, and disable its update (in order to not mark as read all the new messages by default).
        self.roomDataSource.showReadMarker = YES;
        self.updateRoomReadMarker = NO;
        
        [self scrollBubblesTableViewToBottomAnimated:YES];
    }
    else
    {
        // Switch back to the room live timeline managed by MXKRoomDataSourceManager
        MXKRoomDataSourceManager *roomDataSourceManager = [MXKRoomDataSourceManager sharedManagerForMatrixSession:self.mainSession];
        
        MXWeakify(self);
        [roomDataSourceManager roomDataSourceForRoom:self.roomDataSource.roomId create:YES onComplete:^(MXKRoomDataSource *roomDataSource) {
            MXStrongifyAndReturnIfNil(self);
            
            // Scroll to bottom the bubble history on the display refresh.
            self->shouldScrollToBottomOnTableRefresh = YES;
            
            [self displayRoom:roomDataSource];
            
            // The room view controller do not have here the data source ownership.
            self.hasRoomDataSourceOwnership = NO;
            
            [self refreshActivitiesViewDisplay];
            [self refreshJumpToLastUnreadBannerDisplay];
            
            if (self.saveProgressTextInput)
            {
                // Restore the potential message partially typed before jump to last unread messages.
                self.inputToolbarView.textMessage = roomDataSource.partialTextMessage;
            }
        }];
    }
}

#pragma mark - Missed discussions handling

- (void)refreshMissedDiscussionsCount:(BOOL)force
{
    // Ignore this action when no room is displayed
    if (!self.showMissedDiscussionsBadge || !self.roomDataSource || !missedDiscussionsBadgeLabel
        || [UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPhone
        || ([[UIScreen mainScreen] nativeBounds].size.height > 2532 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)))
    {
        self.missedDiscussionsBadgeHidden = YES;
        return;
    }
    
    self.missedDiscussionsBadgeHidden = NO;

    NSUInteger highlightCount = 0;
    NSUInteger missedCount = [[AppDelegate theDelegate].masterTabBarController missedDiscussionsCount];
    
    // Compute the missed notifications count of the current room by considering its notification mode in Riot.
    NSUInteger roomNotificationCount = self.roomDataSource.room.summary.notificationCount;
    if (self.roomDataSource.room.isMentionsOnly)
    {
        // Only the highlighted missed messages must be considered here.
        roomNotificationCount = self.roomDataSource.room.summary.highlightCount;
    }
    
    // Remove the current room from the missed discussion counter.
    if (missedCount && roomNotificationCount)
    {
        missedCount--;
    }
    
    if (missedCount)
    {
        // Compute the missed highlight count
        highlightCount = [[AppDelegate theDelegate].masterTabBarController missedHighlightDiscussionsCount];
        if (highlightCount && self.roomDataSource.room.summary.highlightCount)
        {
            // Remove the current room from the missed highlight counter
            highlightCount--;
        }
    }
    
    if (force || missedDiscussionsCount != missedCount || missedHighlightCount != highlightCount)
    {
        missedDiscussionsCount = missedCount;
        missedHighlightCount = highlightCount;
        
        if (missedCount)
        {
            // Refresh missed discussions count label
            if (missedCount > 99)
            {
                missedDiscussionsBadgeLabel.text = @"99+";
            }
            else
            {
                missedDiscussionsBadgeLabel.text = [NSString stringWithFormat:@"%tu", missedCount];
            }
            
            missedDiscussionsDotView.alpha = highlightCount == 0 ? 0 : 1;
        }
        else
        {
            missedDiscussionsBadgeLabel.text = nil;
        }
    }
}

#pragma mark - Unsent Messages Handling

-(BOOL)checkUnsentMessages
{
    MXRoomSummarySentStatus sentStatus = MXRoomSummarySentStatusOk;
    if ([self.activitiesView isKindOfClass:RoomActivitiesView.class])
    {
        sentStatus = self.roomDataSource.room.summary.sentStatus;
        
        if (sentStatus != MXRoomSummarySentStatusOk)
        {
            NSString *notification = sentStatus == MXRoomSummarySentStatusSentFailedDueToUnknownDevices ?
            [VectorL10n roomUnsentMessagesUnknownDevicesNotification] :
            [VectorL10n roomUnsentMessagesNotification];
            
            MXWeakify(self);
            RoomActivitiesView *roomActivitiesView = (RoomActivitiesView*) self.activitiesView;
            self.activitiesViewExpanded = YES;
            [roomActivitiesView displayUnsentMessagesNotification:notification withResendLink:^{
                
                [self resendAllUnsentMessages];
                
            } andCancelLink:^{
                
                [self cancelAllUnsentMessages];
                
            } andIconTapGesture:^{
                MXStrongifyAndReturnIfNil(self);
                
                if (self->currentAlert)
                {
                    [self->currentAlert dismissViewControllerAnimated:NO completion:nil];
                }
                
                MXWeakify(self);
                UIAlertController *resendAlert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
                
                [resendAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n roomResendUnsentMessages]
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                    
                    MXStrongifyAndReturnIfNil(self);
                    
                    [self resendAllUnsentMessages];
                    self->currentAlert = nil;
                    
                }]];
                
                [resendAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n roomDeleteUnsentMessages]
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                    
                    MXStrongifyAndReturnIfNil(self);
                    
                    [self cancelAllUnsentMessages];
                    self->currentAlert = nil;
                    
                }]];
                
                [resendAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                                style:UIAlertActionStyleCancel
                                                              handler:^(UIAlertAction * action) {
                    
                    MXStrongifyAndReturnIfNil(self);
                    
                    self->currentAlert = nil;
                    
                }]];
                
                [resendAlert mxk_setAccessibilityIdentifier:@"RoomVCUnsentMessagesMenuAlert"];
                [resendAlert popoverPresentationController].sourceView = roomActivitiesView;
                [resendAlert popoverPresentationController].sourceRect = roomActivitiesView.bounds;
                [self presentViewController:resendAlert animated:YES completion:nil];
                self->currentAlert = resendAlert;
                
            }];
        }
    }
    
    return sentStatus != MXRoomSummarySentStatusOk;
}

- (void)eventDidChangeSentState:(NSNotification *)notif
{
    // We are only interested by event that has just failed in their encryption
    // because of unknown devices in the room
    MXEvent *event = notif.object;
    if (event.sentState == MXEventSentStateFailed &&
        [event.roomId isEqualToString:self.roomDataSource.roomId]
        && [event.sentError.domain isEqualToString:MXEncryptingErrorDomain]
        && event.sentError.code == MXEncryptingErrorUnknownDeviceCode
        && !unknownDevices)   // Show the alert once in case of resending several events
    {
        __weak __typeof(self) weakSelf = self;
        
        [self dismissTemporarySubViews];
        
        // List all unknown devices
        unknownDevices  = [[MXUsersDevicesMap alloc] init];
        
        NSArray<MXEvent*> *outgoingMsgs = self.roomDataSource.room.outgoingMessages;
        for (MXEvent *event in outgoingMsgs)
        {
            if (event.sentState == MXEventSentStateFailed
                && [event.sentError.domain isEqualToString:MXEncryptingErrorDomain]
                && event.sentError.code == MXEncryptingErrorUnknownDeviceCode)
            {
                MXUsersDevicesMap<MXDeviceInfo*> *eventUnknownDevices = event.sentError.userInfo[MXEncryptingErrorUnknownDeviceDevicesKey];
                
                [unknownDevices addEntriesFromMap:eventUnknownDevices];
            }
        }
        
        UIAlertController *unknownDevicesAlert = [UIAlertController alertControllerWithTitle:[VectorL10n unknownDevicesAlertTitle]
                                                                                     message:[VectorL10n unknownDevicesAlert]
                                                                              preferredStyle:UIAlertControllerStyleAlert];
        
        [unknownDevicesAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n unknownDevicesVerify]
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
            
            if (weakSelf)
            {
                typeof(self) self = weakSelf;
                self->currentAlert = nil;
                
                [self performSegueWithIdentifier:@"showUnknownDevices" sender:self];
            }
            
        }]];
        
        [unknownDevicesAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n unknownDevicesSendAnyway]
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
            
            if (weakSelf)
            {
                typeof(self) self = weakSelf;
                self->currentAlert = nil;
                
                // Acknowledge the existence of all devices
                [self startActivityIndicator];
                [self.mainSession.crypto setDevicesKnown:self->unknownDevices complete:^{
                    
                    self->unknownDevices = nil;
                    [self stopActivityIndicator];
                    
                    // And resend pending messages
                    [self resendAllUnsentMessages];
                }];
            }
            
        }]];
        
        [unknownDevicesAlert mxk_setAccessibilityIdentifier:@"RoomVCUnknownDevicesAlert"];
        [self presentViewController:unknownDevicesAlert animated:YES completion:nil];
        currentAlert = unknownDevicesAlert;
    }
}

- (void)eventDidChangeIdentifier:(NSNotification *)notif
{
    MXEvent *event = notif.object;
    NSString *previousId = notif.userInfo[kMXEventIdentifierKey];
    
    if ([customizedRoomDataSource.selectedEventId isEqualToString:previousId])
    {
        MXLogDebug(@"[RoomVC] eventDidChangeIdentifier: Update selectedEventId");
        customizedRoomDataSource.selectedEventId = event.eventId;
    }
}


- (void)resendAllUnsentMessages
{
    // List unsent event ids
    NSArray *outgoingMsgs = self.roomDataSource.room.outgoingMessages;
    NSMutableArray *failedEventIds = [NSMutableArray arrayWithCapacity:outgoingMsgs.count];
    
    for (MXEvent *event in outgoingMsgs)
    {
        if (event.sentState == MXEventSentStateFailed)
        {
            [failedEventIds addObject:event.eventId];
        }
    }
    
    // Launch iterative operation
    [self resendFailedEvent:0 inArray:failedEventIds];
}

- (void)resendFailedEvent:(NSUInteger)index inArray:(NSArray*)failedEventIds
{
    if (index < failedEventIds.count)
    {
        NSString *failedEventId = failedEventIds[index];
        NSUInteger nextIndex = index + 1;
        
        // Let the datasource resend. It will manage local echo, etc.
        [self.roomDataSource resendEventWithEventId:failedEventId success:^(NSString *eventId) {
            
            [self resendFailedEvent:nextIndex inArray:failedEventIds];
            
        } failure:^(NSError *error) {
            
            [self resendFailedEvent:nextIndex inArray:failedEventIds];
            
        }];
        
        return;
    }
    
    // Refresh activities view
    [self refreshActivitiesViewDisplay];
}

- (void)cancelAllUnsentMessages
{
    UIAlertController *cancelAlert = [UIAlertController alertControllerWithTitle:[VectorL10n roomUnsentMessagesCancelTitle]
                                                                         message:[VectorL10n roomUnsentMessagesCancelMessage]
                                                                  preferredStyle:UIAlertControllerStyleAlert];
    
    MXWeakify(self);
    [cancelAlert addAction:[UIAlertAction actionWithTitle:[MatrixKitL10n cancel] style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
        MXStrongifyAndReturnIfNil(self);
        self->currentAlert = nil;
    }]];
    
    [cancelAlert addAction:[UIAlertAction actionWithTitle:[MatrixKitL10n delete] style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
        MXStrongifyAndReturnIfNil(self);
        // Remove unsent event ids
        for (NSUInteger index = 0; index < self.roomDataSource.room.outgoingMessages.count;)
        {
            MXEvent *event = self.roomDataSource.room.outgoingMessages[index];
            if (event.sentState == MXEventSentStateFailed)
            {
                [self.roomDataSource removeEventWithEventId:event.eventId];
            }
            else
            {
                index ++;
            }
        }
        
        [self refreshActivitiesViewDisplay];
        self->currentAlert = nil;
    }]];
    
    [self presentViewController:cancelAlert animated:YES completion:nil];
    currentAlert = cancelAlert;
}

# pragma mark - Encryption Information view

- (void)showEncryptionInformation:(MXEvent *)event
{
    [self dismissKeyboard];
    
    // Remove potential existing subviews
    [self dismissTemporarySubViews];
    
    EncryptionInfoView *encryptionInfoView = [[EncryptionInfoView alloc] initWithEvent:event andMatrixSession:self.roomDataSource.mxSession];
    
    // Add shadow on added view
    encryptionInfoView.layer.cornerRadius = 5;
    encryptionInfoView.layer.shadowOffset = CGSizeMake(0, 1);
    encryptionInfoView.layer.shadowOpacity = 0.5f;
    
    // Add the view and define edge constraints
    [self.view addSubview:encryptionInfoView];
    
    self->encryptionInfoView = encryptionInfoView;
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:encryptionInfoView
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.topLayoutGuide
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1.0f
                                                           constant:10.0f]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:encryptionInfoView
                                                          attribute:NSLayoutAttributeBottom
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.bottomLayoutGuide
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1.0f
                                                           constant:-10.0f]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view
                                                          attribute:NSLayoutAttributeLeading
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:encryptionInfoView
                                                          attribute:NSLayoutAttributeLeading
                                                         multiplier:1.0f
                                                           constant:-10.0f]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view
                                                          attribute:NSLayoutAttributeTrailing
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:encryptionInfoView
                                                          attribute:NSLayoutAttributeTrailing
                                                         multiplier:1.0f
                                                           constant:10.0f]];
    [self.view setNeedsUpdateConstraints];
}



#pragma mark - Read marker handling

- (void)checkReadMarkerVisibility
{
    if (readMarkerTableViewCell && isAppeared && !self.isBubbleTableViewDisplayInTransition)
    {
        // Check whether the read marker is visible
        CGFloat contentTopPosY = self.bubblesTableView.contentOffset.y + self.bubblesTableView.adjustedContentInset.top;
        CGFloat readMarkerViewPosY = readMarkerTableViewCell.frame.origin.y + readMarkerTableViewCell.readMarkerView.frame.origin.y;
        if (contentTopPosY <= readMarkerViewPosY)
        {
            // Compute the max vertical position visible according to contentOffset
            CGFloat contentBottomPosY = self.bubblesTableView.contentOffset.y + self.bubblesTableView.frame.size.height - self.bubblesTableView.adjustedContentInset.bottom;
            if (readMarkerViewPosY <= contentBottomPosY)
            {
                // Launch animation
                [self animateReadMarkerView];
                
                // Disable the read marker display when it has been rendered once.
                self.roomDataSource.showReadMarker = NO;
                [self refreshJumpToLastUnreadBannerDisplay];
                
                // Update the read marker position according the events acknowledgement in this view controller.
                self.updateRoomReadMarker = YES;
                
                if (self.roomDataSource.isLive)
                {
                    // Move the read marker to the current read receipt position.
                    [self.roomDataSource.room forgetReadMarker];
                }
            }
        }
    }
}

- (void)animateReadMarkerView
{
    // Check whether the cell with the read marker is known and if the marker is not animated yet.
    if (readMarkerTableViewCell && readMarkerTableViewCell.readMarkerView.isHidden)
    {
        RoomBubbleCellData *cellData = (RoomBubbleCellData*)readMarkerTableViewCell.bubbleData;
        
        // Do not display the marker if this is the last message.
        if (cellData.containsLastMessage && readMarkerTableViewCell.readMarkerView.tag == cellData.mostRecentComponentIndex)
        {
            readMarkerTableViewCell.readMarkerView.hidden = YES;
            readMarkerTableViewCell = nil;
        }
        else
        {
            readMarkerTableViewCell.readMarkerView.hidden = NO;
            
            // Animate the layout to hide the read marker
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                [UIView animateWithDuration:1.5 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseIn
                                 animations:^{
                    
                    readMarkerTableViewCell.readMarkerViewLeadingConstraint.constant = readMarkerTableViewCell.readMarkerViewTrailingConstraint.constant = readMarkerTableViewCell.bubbleOverlayContainer.frame.size.width / 2;
                    readMarkerTableViewCell.readMarkerView.alpha = 0;
                    
                    // Force to render the view
                    [readMarkerTableViewCell.bubbleOverlayContainer layoutIfNeeded];
                    
                }
                                 completion:^(BOOL finished){
                    
                    readMarkerTableViewCell.readMarkerView.hidden = YES;
                    readMarkerTableViewCell.readMarkerView.alpha = 1;
                    
                    readMarkerTableViewCell = nil;
                }];
                
            });
        }
    }
}

- (void)refreshRemoveJitsiWidgetView
{
    if (self.roomDataSource.isLive && !self.roomDataSource.isPeeking)
    {
        Widget *jitsiWidget = [customizedRoomDataSource jitsiWidget];
        
        if (jitsiWidget && self.canEditJitsiWidget)
        {
            [self.removeJitsiWidgetView reset];
            self.removeJitsiWidgetContainer.hidden = NO;
            self.removeJitsiWidgetView.delegate = self;
        }
        else
        {
            self.removeJitsiWidgetContainer.hidden = YES;
            self.removeJitsiWidgetView.delegate = nil;
        }
    }
    else
    {
        [self.removeJitsiWidgetView reset];
        self.removeJitsiWidgetContainer.hidden = YES;
        self.removeJitsiWidgetView.delegate = self;
    }
}

- (void)refreshJumpToLastUnreadBannerDisplay
{
    // This banner is only displayed when the room timeline is in live (and no peeking).
    // Check whether the read marker exists and has not been rendered yet.
    if (self.roomDataSource.isLive && !self.roomDataSource.isPeeking && self.roomDataSource.showReadMarker && self.roomDataSource.room.accountData.readMarkerEventId)
    {
        UITableViewCell *cell = [self.bubblesTableView visibleCells].firstObject;
        if ([cell isKindOfClass:MXKRoomBubbleTableViewCell.class])
        {
            MXKRoomBubbleTableViewCell *roomBubbleTableViewCell = (MXKRoomBubbleTableViewCell*)cell;
            // Check whether the read marker is inside the first displayed cell.
            if (roomBubbleTableViewCell.readMarkerView)
            {
                // The read marker display is still enabled (see roomDataSource.showReadMarker flag),
                // this means the read marker was not been visible yet.
                // We show the banner if the marker is located in the top hidden part of the cell.
                CGFloat contentTopPosY = self.bubblesTableView.contentOffset.y + self.bubblesTableView.adjustedContentInset.top;
                CGFloat readMarkerViewPosY = roomBubbleTableViewCell.frame.origin.y + roomBubbleTableViewCell.readMarkerView.frame.origin.y;
                self.jumpToLastUnreadBannerContainer.hidden = (contentTopPosY < readMarkerViewPosY);
            }
            else
            {
                // Check whether the read marker event is anterior to the first event displayed in the first rendered cell.
                MXKRoomBubbleComponent *component = roomBubbleTableViewCell.bubbleData.bubbleComponents.firstObject;
                MXEvent *firstDisplayedEvent = component.event;
                MXEvent *currentReadMarkerEvent = [self.roomDataSource.mxSession.store eventWithEventId:self.roomDataSource.room.accountData.readMarkerEventId inRoom:self.roomDataSource.roomId];
                
                if (!currentReadMarkerEvent || (currentReadMarkerEvent.originServerTs < firstDisplayedEvent.originServerTs))
                {
                    self.jumpToLastUnreadBannerContainer.hidden = NO;
                }
                else
                {
                    self.jumpToLastUnreadBannerContainer.hidden = YES;
                }
            }
        }
    }
    else
    {
        self.jumpToLastUnreadBannerContainer.hidden = YES;
        
        // Initialize the read marker if it does not exist yet, only in case of live timeline.
        if (!self.roomDataSource.room.accountData.readMarkerEventId && self.roomDataSource.isLive && !self.roomDataSource.isPeeking)
        {
            // Move the read marker to the current read receipt position by default.
            [self.roomDataSource.room forgetReadMarker];
        }
    }
}

#pragma mark - ContactsTableViewControllerDelegate

- (void)contactsTableViewController:(ContactsTableViewController *)contactsTableViewController didSelectContact:(MXKContact*)contact
{
    __weak typeof(self) weakSelf = self;
    
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
    
    // Invite ?
    NSString *promptMsg = [VectorL10n roomParticipantsInvitePromptMsg:contact.displayName];
    UIAlertController *invitePrompt = [UIAlertController alertControllerWithTitle:[VectorL10n roomParticipantsInvitePromptTitle]
                                                                         message:promptMsg
                                                                  preferredStyle:UIAlertControllerStyleAlert];
    
    [invitePrompt addAction:[UIAlertAction actionWithTitle:[MatrixKitL10n cancel]
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction * action) {
        
        if (weakSelf)
        {
            typeof(self) self = weakSelf;
            self->currentAlert = nil;
        }
        
    }]];
    
    [invitePrompt addAction:[UIAlertAction actionWithTitle:[VectorL10n invite]
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
        
        // Sanity check
        if (!weakSelf)
        {
            return;
        }
        
        typeof(self) self = weakSelf;
        self->currentAlert = nil;
        
        MXSession* session = self.roomDataSource.mxSession;
        NSString* roomId = self.roomDataSource.roomId;
        MXRoom *room = [session roomWithRoomId:roomId];
        
        NSArray *identifiers = contact.matrixIdentifiers;
        NSString *participantId;
        
        if (identifiers.count)
        {
            participantId = identifiers.firstObject;
            
            // Invite this user if a room is defined
            [room inviteUser:participantId success:^{
                
                // Refresh display by removing the contacts picker
                [contactsTableViewController withdrawViewControllerAnimated:YES completion:nil];
                
            } failure:^(NSError *error) {
                
                MXLogDebug(@"[RoomVC] Invite %@ failed", participantId);
                // Alert user
                [self showError:error];
                
            }];
        }
        else
        {
            if (contact.emailAddresses.count)
            {
                // This is a local contact, consider the first email by default.
                // TODO: Prompt the user to select the right email.
                MXKEmail *email = contact.emailAddresses.firstObject;
                participantId = email.emailAddress;
            }
            else
            {
                // This is the text filled by the user.
                participantId = contact.displayName;
            }
            
            // Is it an email or a Matrix user ID?
            if ([MXTools isEmailAddress:participantId])
            {
                [room inviteUserByEmail:participantId success:^{
                    
                    // Refresh display by removing the contacts picker
                    [contactsTableViewController withdrawViewControllerAnimated:YES completion:nil];
                    
                } failure:^(NSError *error) {
                    
                    MXLogDebug(@"[RoomVC] Invite be email %@ failed", participantId);
                    // Alert user
                    if ([error.domain isEqualToString:kMXRestClientErrorDomain]
                        && error.code == MXRestClientErrorMissingIdentityServer)
                    {
                        [self showAlertWithTitle:[VectorL10n errorInvite3pidWithNoIdentityServer] message:nil];
                    }
                    else
                    {
                        [self showError:error];
                    }
                }];
            }
            else //if ([MXTools isMatrixUserIdentifier:participantId])
            {
                [room inviteUser:participantId success:^{
                    
                    // Refresh display by removing the contacts picker
                    [contactsTableViewController withdrawViewControllerAnimated:YES completion:nil];
                    
                } failure:^(NSError *error) {
                    
                    MXLogDebug(@"[RoomVC] Invite %@ failed", participantId);
                    // Alert user
                    [self showError:error];
                    
                }];
            }
        }
        
    }]];
    
    [invitePrompt mxk_setAccessibilityIdentifier:@"RoomVCInviteAlert"];
    [self presentViewController:invitePrompt animated:YES completion:nil];
    currentAlert = invitePrompt;
}

#pragma mark - Re-request encryption keys

- (void)reRequestKeysAndShowExplanationAlert:(MXEvent*)event
{
    MXWeakify(self);
    __block UIAlertController *alert;
    
    // Force device verification if session has cross-signing activated and device is not yet verified
    if (self.mainSession.crypto.crossSigning && self.mainSession.crypto.crossSigning.state == MXCrossSigningStateCrossSigningExists)
    {
        [self presentReviewUnverifiedSessionsAlert];
        return;
    }
    
    // Make the re-request
    [self.mainSession.crypto reRequestRoomKeyForEvent:event];
    
    // Observe kMXEventDidDecryptNotification to remove automatically the dialog
    // if the user has shared the keys from another device
    mxEventDidDecryptNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXEventDidDecryptNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        MXStrongifyAndReturnIfNil(self);
        
        MXEvent *decryptedEvent = notif.object;
        
        if ([decryptedEvent.eventId isEqualToString:event.eventId])
        {
            [[NSNotificationCenter defaultCenter] removeObserver:self->mxEventDidDecryptNotificationObserver];
            self->mxEventDidDecryptNotificationObserver = nil;
            
            if (self->currentAlert == alert)
            {
                [self->currentAlert dismissViewControllerAnimated:YES completion:nil];
                self->currentAlert = nil;
            }
        }
    }];
    
    // Show the explanation dialog
    alert = [UIAlertController alertControllerWithTitle:VectorL10n.rerequestKeysAlertTitle
                                                message:[VectorL10n e2eRoomKeyRequestMessage:AppInfo.current.displayName]
                                         preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:[MatrixKitL10n ok]
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action)
                      {
        MXStrongifyAndReturnIfNil(self);
        
        [[NSNotificationCenter defaultCenter] removeObserver:self->mxEventDidDecryptNotificationObserver];
        self->mxEventDidDecryptNotificationObserver = nil;
        
        self->currentAlert = nil;
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
    currentAlert = alert;
}

- (void)presentReviewUnverifiedSessionsAlert
{
    MXLogDebug(@"[MasterTabBarController] presentReviewUnverifiedSessionsAlertWithSession");
    
    [currentAlert dismissViewControllerAnimated:NO completion:nil];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[VectorL10n keyVerificationSelfVerifyUnverifiedSessionsAlertTitle]
                                                                   message:[VectorL10n keyVerificationSelfVerifyUnverifiedSessionsAlertMessage]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:[VectorL10n keyVerificationSelfVerifyUnverifiedSessionsAlertValidateAction]
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
        [self showSettingsSecurityScreen];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:[VectorL10n later]
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
    
    currentAlert = alert;
}

- (void)showSettingsSecurityScreen
{
    if (self.delegate)
    {
        [self.delegate roomViewController:self showCompleteSecurityForSession:self.mainSession];
    }
    else
    {
        [[AppDelegate theDelegate] presentCompleteSecurityForSession: self.mainSession];
    }
}

#pragma mark Tombstone event

- (void)listenTombstoneEventNotifications
{
    // Room is already obsolete do not listen to tombstone event
    if (self.roomDataSource.roomState.isObsolete)
    {
        return;
    }
    
    MXWeakify(self);
    
    tombstoneEventNotificationsListener = [self.roomDataSource.room listenToEventsOfTypes:@[kMXEventTypeStringRoomTombStone] onEvent:^(MXEvent *event, MXTimelineDirection direction, MXRoomState *roomState) {
        
        MXStrongifyAndReturnIfNil(self);
        
        // Update activitiesView with room replacement information
        [self refreshActivitiesViewDisplay];
        // Hide inputToolbarView
        [self updateRoomInputToolbarViewClassIfNeeded];
    }];
}

- (void)removeTombstoneEventNotificationsListener
{
    if (self.roomDataSource)
    {
        // Remove the previous live listener
        if (tombstoneEventNotificationsListener)
        {
            [self.roomDataSource.room removeListener:tombstoneEventNotificationsListener];
            tombstoneEventNotificationsListener = nil;
        }
    }
}

#pragma mark MXSession state change

- (void)listenMXSessionStateChangeNotifications
{
    MXWeakify(self);
    
    kMXSessionStateDidChangeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXSessionStateDidChangeNotification object:self.roomDataSource.mxSession queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXStrongifyAndReturnIfNil(self);
        
        if (self.roomDataSource.mxSession.state == MXSessionStateSyncError
            || self.roomDataSource.mxSession.state == MXSessionStateRunning)
        {
            [self refreshActivitiesViewDisplay];
            
            // update inputToolbarView
            [self updateRoomInputToolbarViewClassIfNeeded];
        }
    }];
}

- (void)removeMXSessionStateChangeNotificationsListener
{
    if (kMXSessionStateDidChangeObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kMXSessionStateDidChangeObserver];
        kMXSessionStateDidChangeObserver = nil;
    }
}

#pragma mark - Contextual Menu

- (NSArray<RoomContextualMenuItem*>*)contextualMenuItemsForEvent:(MXEvent*)event andCell:(id<MXKCellRendering>)cell
{
    if (event.sentState == MXEventSentStateFailed)
    {
        return @[
            [self resendMenuItemWithEvent:event],
            [self deleteMenuItemWithEvent:event],
            [self editMenuItemWithEvent:event],
            [self copyMenuItemWithEvent:event andCell:cell]
        ];
    }
    
    BOOL showMoreOption = (event.isState && RiotSettings.shared.roomContextualMenuShowMoreOptionForStates) || (!event.isState && RiotSettings.shared.roomContextualMenuShowMoreOptionForMessages);
    
    if (showMoreOption)
    {
        return @[
            [self copyMenuItemWithEvent:event andCell:cell],
            [self replyMenuItemWithEvent:event],
            [self editMenuItemWithEvent:event],
            [self moreMenuItemWithEvent:event andCell:cell]
        ];
    }
    else
    {
        return @[
            [self copyMenuItemWithEvent:event andCell:cell],
            [self replyMenuItemWithEvent:event],
            [self editMenuItemWithEvent:event]
        ];
    }
}

- (void)showContextualMenuForEvent:(MXEvent*)event fromSingleTapGesture:(BOOL)usedSingleTapGesture cell:(id<MXKCellRendering>)cell animated:(BOOL)animated
{
    if (self.roomContextualMenuPresenter.isPresenting)
    {
        return;
    }
    
    NSString *selectedEventId = event.eventId;
    
    NSArray<RoomContextualMenuItem*>* contextualMenuItems = [self contextualMenuItemsForEvent:event andCell:cell];
    ReactionsMenuViewModel *reactionsMenuViewModel;
    CGRect bubbleComponentFrameInOverlayView = CGRectNull;
    
    if ([cell isKindOfClass:MXKRoomBubbleTableViewCell.class] && [self.roomDataSource canReactToEventWithId:event.eventId])
    {
        MXKRoomBubbleTableViewCell *roomBubbleTableViewCell = (MXKRoomBubbleTableViewCell*)cell;
        MXKRoomBubbleCellData *bubbleCellData = roomBubbleTableViewCell.bubbleData;
        NSArray *bubbleComponents = bubbleCellData.bubbleComponents;
        
        NSInteger foundComponentIndex = [bubbleCellData bubbleComponentIndexForEventId:event.eventId];
        CGRect bubbleComponentFrame;
        
        if (bubbleComponents.count > 0)
        {
            NSInteger selectedComponentIndex = foundComponentIndex != NSNotFound ? foundComponentIndex : 0;
            bubbleComponentFrame = [roomBubbleTableViewCell surroundingFrameInTableViewForComponentIndex:selectedComponentIndex];
        }
        else
        {
            bubbleComponentFrame = roomBubbleTableViewCell.frame;
        }
        
        bubbleComponentFrameInOverlayView = [self.bubblesTableView convertRect:bubbleComponentFrame toView:self.overlayContainerView];
        
        NSString *roomId = self.roomDataSource.roomId;
        MXAggregations *aggregations = self.mainSession.aggregations;
        MXAggregatedReactions *aggregatedReactions = [aggregations aggregatedReactionsOnEvent:selectedEventId inRoom:roomId];
        
        reactionsMenuViewModel = [[ReactionsMenuViewModel alloc] initWithAggregatedReactions:aggregatedReactions eventId:selectedEventId];
        reactionsMenuViewModel.coordinatorDelegate = self;
    }
    
    if (!self.roomContextualMenuViewController)
    {
        self.roomContextualMenuViewController = [RoomContextualMenuViewController instantiate];
        self.roomContextualMenuViewController.delegate = self;
    }
    
    [self.roomContextualMenuViewController updateWithContextualMenuItems:contextualMenuItems reactionsMenuViewModel:reactionsMenuViewModel];
    
    [self enableOverlayContainerUserInteractions:YES];
    
    [self.roomContextualMenuPresenter presentWithRoomContextualMenuViewController:self.roomContextualMenuViewController
                                                                             from:self
                                                                               on:self.overlayContainerView
                                                              contentToReactFrame:bubbleComponentFrameInOverlayView
                                                             fromSingleTapGesture:usedSingleTapGesture
                                                                         animated:animated
                                                                       completion:^{
    }];
    
    preventBubblesTableViewScroll = YES;
    [self selectEventWithId:selectedEventId];
}

- (void)hideContextualMenuAnimated:(BOOL)animated
{
    [self hideContextualMenuAnimated:animated completion:nil];
}

- (void)hideContextualMenuAnimated:(BOOL)animated completion:(void(^)(void))completion
{
    [self hideContextualMenuAnimated:animated cancelEventSelection:YES completion:completion];
}

- (void)hideContextualMenuAnimated:(BOOL)animated cancelEventSelection:(BOOL)cancelEventSelection completion:(void(^)(void))completion
{
    if (!self.roomContextualMenuPresenter.isPresenting)
    {
        return;
    }
    
    if (cancelEventSelection)
    {
        [self cancelEventSelection];
    }
    
    preventBubblesTableViewScroll = NO;
    
    [self.roomContextualMenuPresenter hideContextualMenuWithAnimated:animated completion:^{
        [self enableOverlayContainerUserInteractions:NO];
        
        if (completion)
        {
            completion();
        }
    }];
}

- (void)enableOverlayContainerUserInteractions:(BOOL)enableOverlayContainerUserInteractions
{
    self.inputToolbarView.editable = !enableOverlayContainerUserInteractions;
    self.bubblesTableView.scrollsToTop = !enableOverlayContainerUserInteractions;
    self.overlayContainerView.userInteractionEnabled = enableOverlayContainerUserInteractions;
}

- (RoomContextualMenuItem *)resendMenuItemWithEvent:(MXEvent*)event
{
    MXWeakify(self);
    
    RoomContextualMenuItem *resendMenuItem = [[RoomContextualMenuItem alloc] initWithMenuAction:RoomContextualMenuActionResend];
    resendMenuItem.action = ^{
        MXStrongifyAndReturnIfNil(self);
        [self hideContextualMenuAnimated:YES cancelEventSelection:NO completion:nil];
        [self cancelEventSelection];
        [self.roomDataSource resendEventWithEventId:event.eventId success:nil failure:nil];
    };
    
    return resendMenuItem;
}

- (RoomContextualMenuItem *)deleteMenuItemWithEvent:(MXEvent*)event
{
    MXWeakify(self);
    
    RoomContextualMenuItem *deleteMenuItem = [[RoomContextualMenuItem alloc] initWithMenuAction:RoomContextualMenuActionDelete];
    deleteMenuItem.action = ^{
        MXStrongifyAndReturnIfNil(self);
        
        MXWeakify(self);
        [self hideContextualMenuAnimated:YES cancelEventSelection:YES completion:^{
            MXStrongifyAndReturnIfNil(self);
            
            UIAlertController *deleteConfirmation = [UIAlertController alertControllerWithTitle:[VectorL10n roomEventActionDeleteConfirmationTitle]
                                                                                        message:[VectorL10n roomEventActionDeleteConfirmationMessage]
                                                                                 preferredStyle:UIAlertControllerStyleAlert];
            
            [deleteConfirmation addAction:[UIAlertAction actionWithTitle:[MatrixKitL10n cancel] style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            }]];
            
            [deleteConfirmation addAction:[UIAlertAction actionWithTitle:[MatrixKitL10n delete] style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
                [self.roomDataSource removeEventWithEventId:event.eventId];
            }]];
            
            [self presentViewController:deleteConfirmation animated:YES completion:nil];
            self->currentAlert = deleteConfirmation;
        }];
    };
    
    return deleteMenuItem;
}

- (RoomContextualMenuItem *)editMenuItemWithEvent:(MXEvent*)event
{
    MXWeakify(self);
    
    RoomContextualMenuItem *editMenuItem = [[RoomContextualMenuItem alloc] initWithMenuAction:RoomContextualMenuActionEdit];
    editMenuItem.action = ^{
        MXStrongifyAndReturnIfNil(self);
        [self hideContextualMenuAnimated:YES cancelEventSelection:NO completion:nil];
        [self editEventContentWithId:event.eventId];
        
        // And display the keyboard
        [self.inputToolbarView becomeFirstResponder];
    };
    
    editMenuItem.isEnabled = [self.roomDataSource canEditEventWithId:event.eventId];
    
    return editMenuItem;
}

- (RoomContextualMenuItem *)copyMenuItemWithEvent:(MXEvent*)event andCell:(id<MXKCellRendering>)cell
{
    MXKRoomBubbleTableViewCell *roomBubbleTableViewCell = (MXKRoomBubbleTableViewCell *)cell;
    MXKAttachment *attachment = roomBubbleTableViewCell.bubbleData.attachment;
    
    MXWeakify(self);
    
    BOOL isCopyActionEnabled = (event.eventType != MXEventTypePollStart && (!attachment || attachment.type != MXKAttachmentTypeSticker));
    
    if (attachment && !BuildSettings.messageDetailsAllowCopyMedia)
    {
        isCopyActionEnabled = NO;
    }
    
    if (isCopyActionEnabled)
    {
        switch (event.eventType) {
            case MXEventTypeRoomMessage:
            {
                NSString *messageType = event.content[@"msgtype"];
                
                if ([messageType isEqualToString:kMXMessageTypeKeyVerificationRequest])
                {
                    isCopyActionEnabled = NO;
                }
                break;
            }
            case MXEventTypeKeyVerificationStart:
            case MXEventTypeKeyVerificationAccept:
            case MXEventTypeKeyVerificationKey:
            case MXEventTypeKeyVerificationMac:
            case MXEventTypeKeyVerificationDone:
            case MXEventTypeKeyVerificationCancel:
                isCopyActionEnabled = NO;
                break;
            case MXEventTypeCustom:
                if ([event.type isEqualToString:kWidgetMatrixEventTypeString]
                    || [event.type isEqualToString:kWidgetModularEventTypeString])
                {
                    Widget *widget = [[Widget alloc] initWithWidgetEvent:event inMatrixSession:self.roomDataSource.mxSession];
                    if ([widget.type isEqualToString:kWidgetTypeJitsiV1] ||
                        [widget.type isEqualToString:kWidgetTypeJitsiV2])
                    {
                        isCopyActionEnabled = NO;
                    }
                }
            default:
                break;
        }
    }
    
    RoomContextualMenuItem *copyMenuItem = [[RoomContextualMenuItem alloc] initWithMenuAction:RoomContextualMenuActionCopy];
    copyMenuItem.isEnabled = isCopyActionEnabled;
    copyMenuItem.action = ^{
        MXStrongifyAndReturnIfNil(self);
        
        if (!attachment)
        {
            NSArray *components = roomBubbleTableViewCell.bubbleData.bubbleComponents;
            MXKRoomBubbleComponent *selectedComponent;
            for (selectedComponent in components)
            {
                if ([selectedComponent.event.eventId isEqualToString:event.eventId])
                {
                    break;
                }
                selectedComponent = nil;
            }
            NSString *textMessage = selectedComponent.textMessage;
            
            if (textMessage)
            {
                MXKPasteboardManager.shared.pasteboard.string = textMessage;
            }
            else
            {
                MXLogDebug(@"[RoomViewController] Contextual menu copy failed. Text is nil for room id/event id: %@/%@", selectedComponent.event.roomId, selectedComponent.event.eventId);
            }
            
            [self hideContextualMenuAnimated:YES];
        }
        else if (attachment.type != MXKAttachmentTypeSticker)
        {
            [self hideContextualMenuAnimated:YES completion:^{
                [self startActivityIndicator];
                
                [attachment copy:^{
                    
                    [self stopActivityIndicator];
                    
                } failure:^(NSError *error) {
                    
                    [self stopActivityIndicator];
                    
                    //Alert user
                    [self showError:error];
                }];
                
                // Start animation in case of download during attachment preparing
                [roomBubbleTableViewCell startProgressUI];
            }];
        }
    };
    
    return copyMenuItem;
}

- (RoomContextualMenuItem *)replyMenuItemWithEvent:(MXEvent*)event
{
    MXWeakify(self);
    
    RoomContextualMenuItem *replyMenuItem = [[RoomContextualMenuItem alloc] initWithMenuAction:RoomContextualMenuActionReply];
    replyMenuItem.isEnabled = [self.roomDataSource canReplyToEventWithId:event.eventId] && !self.voiceMessageController.isRecordingAudio;
    replyMenuItem.action = ^{
        MXStrongifyAndReturnIfNil(self);
        
        [self hideContextualMenuAnimated:YES cancelEventSelection:NO completion:nil];
        [self selectEventWithId:event.eventId inputToolBarSendMode:RoomInputToolbarViewSendModeReply showTimestamp:NO];
        
        // And display the keyboard
        [self.inputToolbarView becomeFirstResponder];
    };
    
    return replyMenuItem;
}

- (RoomContextualMenuItem *)moreMenuItemWithEvent:(MXEvent*)event andCell:(id<MXKCellRendering>)cell
{
    MXWeakify(self);
    
    RoomContextualMenuItem *moreMenuItem = [[RoomContextualMenuItem alloc] initWithMenuAction:RoomContextualMenuActionMore];
    moreMenuItem.action = ^{
        MXStrongifyAndReturnIfNil(self);
        [self hideContextualMenuAnimated:YES completion:nil];
        [self showAdditionalActionsMenuForEvent:event inCell:cell animated:YES];
    };
    
    return moreMenuItem;
}

#pragma mark - RoomContextualMenuViewControllerDelegate

- (void)roomContextualMenuViewControllerDidTapBackgroundOverlay:(RoomContextualMenuViewController *)viewController
{
    [self hideContextualMenuAnimated:YES];
}

#pragma mark - ReactionsMenuViewModelCoordinatorDelegate

- (void)reactionsMenuViewModel:(ReactionsMenuViewModel *)viewModel didAddReaction:(NSString *)reaction forEventId:(NSString *)eventId
{
    MXWeakify(self);
    
    [self hideContextualMenuAnimated:YES completion:^{
        
        [self.roomDataSource addReaction:reaction forEventId:eventId success:^{
            
        } failure:^(NSError *error) {
            MXStrongifyAndReturnIfNil(self);
            
            [self.errorPresenter presentErrorFromViewController:self forError:error animated:YES handler:nil];
        }];
    }];
}

- (void)reactionsMenuViewModel:(ReactionsMenuViewModel *)viewModel didRemoveReaction:(NSString *)reaction forEventId:(NSString *)eventId
{
    MXWeakify(self);
    
    [self hideContextualMenuAnimated:YES completion:^{
        
        [self.roomDataSource removeReaction:reaction forEventId:eventId success:^{
            
        } failure:^(NSError *error) {
            MXStrongifyAndReturnIfNil(self);
            
            [self.errorPresenter presentErrorFromViewController:self forError:error animated:YES handler:nil];
        }];
        
    }];
}

- (void)reactionsMenuViewModelDidTapMoreReactions:(ReactionsMenuViewModel *)viewModel forEventId:(NSString *)eventId
{
    [self hideContextualMenuAnimated:YES];
    
    EmojiPickerCoordinatorBridgePresenter *emojiPickerCoordinatorBridgePresenter = [[EmojiPickerCoordinatorBridgePresenter alloc] initWithSession:self.mainSession roomId:self.roomDataSource.roomId eventId:eventId];
    emojiPickerCoordinatorBridgePresenter.delegate = self;
    
    NSInteger cellRow = [self.roomDataSource indexOfCellDataWithEventId:eventId];
    
    UIView *sourceView;
    CGRect sourceRect = CGRectNull;
    
    if (cellRow >= 0)
    {
        NSIndexPath *cellIndexPath = [NSIndexPath indexPathForRow:cellRow inSection:0];
        UITableViewCell *cell = [self.bubblesTableView cellForRowAtIndexPath:cellIndexPath];
        sourceView = cell;
        
        if ([cell isKindOfClass:[MXKRoomBubbleTableViewCell class]])
        {
            MXKRoomBubbleTableViewCell *roomBubbleTableViewCell = (MXKRoomBubbleTableViewCell*)cell;
            NSInteger bubbleComponentIndex = [roomBubbleTableViewCell.bubbleData bubbleComponentIndexForEventId:eventId];
            sourceRect = [roomBubbleTableViewCell componentFrameInContentViewForIndex:bubbleComponentIndex];
        }
        
    }
    
    [emojiPickerCoordinatorBridgePresenter presentFrom:self sourceView:sourceView sourceRect:sourceRect animated:YES];
    self.emojiPickerCoordinatorBridgePresenter = emojiPickerCoordinatorBridgePresenter;
}

#pragma mark -

- (void)showEditHistoryForEventId:(NSString*)eventId animated:(BOOL)animated
{
    MXEvent *event = [self.roomDataSource eventWithEventId:eventId];
    EditHistoryCoordinatorBridgePresenter *presenter = [[EditHistoryCoordinatorBridgePresenter alloc] initWithSession:self.roomDataSource.mxSession event:event];
    
    presenter.delegate = self;
    [presenter presentFrom:self animated:animated];
    
    self.editHistoryPresenter = presenter;
}

#pragma mark - EditHistoryCoordinatorBridgePresenterDelegate

- (void)editHistoryCoordinatorBridgePresenterDelegateDidComplete:(EditHistoryCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    self.editHistoryPresenter = nil;
}

#pragma mark - DocumentPickerPresenterDelegate

- (void)documentPickerPresenterWasCancelled:(MXKDocumentPickerPresenter *)presenter
{
    self.documentPickerPresenter = nil;
}

- (void)documentPickerPresenter:(MXKDocumentPickerPresenter *)presenter didPickDocumentsAt:(NSURL *)url
{
    self.documentPickerPresenter = nil;
    
    MXKUTI *fileUTI = [[MXKUTI alloc] initWithLocalFileURL:url];
    NSString *mimeType = fileUTI.mimeType;
    
    if (fileUTI.isImage)
    {
        NSData *imageData = [[NSData alloc] initWithContentsOfURL:url];
        
        [self.roomDataSource sendImage:imageData mimeType:mimeType success:nil failure:^(NSError *error) {
            // Nothing to do. The image is marked as unsent in the room history by the datasource
            MXLogDebug(@"[MXKRoomViewController] sendImage failed.");
        }];
    }
    else if (fileUTI.isVideo)
    {
        [(RoomDataSource*)self.roomDataSource sendVideo:url success:nil failure:^(NSError *error) {
            // Nothing to do. The video is marked as unsent in the room history by the datasource
            MXLogDebug(@"[MXKRoomViewController] sendVideo failed.");
        }];
    }
    else if (fileUTI.isFile)
    {
        [self.roomDataSource sendFile:url mimeType:mimeType success:nil failure:^(NSError *error) {
            // Nothing to do. The file is marked as unsent in the room history by the datasource
            MXLogDebug(@"[MXKRoomViewController] sendFile failed.");
        }];
    }
    else
    {
        MXLogDebug(@"[MXKRoomViewController] File upload using MIME type %@ is not supported.", mimeType);
        
        [self showAlertWithTitle:[VectorL10n fileUploadErrorTitle]
                         message:[VectorL10n fileUploadErrorUnsupportedFileTypeMessage]];
    }
}

#pragma mark - EmojiPickerCoordinatorBridgePresenterDelegate

- (void)emojiPickerCoordinatorBridgePresenter:(EmojiPickerCoordinatorBridgePresenter *)coordinatorBridgePresenter didAddEmoji:(NSString *)emoji forEventId:(NSString *)eventId
{
    MXWeakify(self);
    
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:^{
        [self.roomDataSource addReaction:emoji forEventId:eventId success:^{
            
        } failure:^(NSError *error) {
            MXStrongifyAndReturnIfNil(self);
            
            [self.errorPresenter presentErrorFromViewController:self forError:error animated:YES handler:nil];
        }];
    }];
    self.emojiPickerCoordinatorBridgePresenter = nil;
}

- (void)emojiPickerCoordinatorBridgePresenter:(EmojiPickerCoordinatorBridgePresenter *)coordinatorBridgePresenter didRemoveEmoji:(NSString *)emoji forEventId:(NSString *)eventId
{
    MXWeakify(self);
    
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:^{
        
        [self.roomDataSource removeReaction:emoji forEventId:eventId success:^{
            
        } failure:^(NSError *error) {
            MXStrongifyAndReturnIfNil(self);
            
            [self.errorPresenter presentErrorFromViewController:self forError:error animated:YES handler:nil];
        }];
    }];
    self.emojiPickerCoordinatorBridgePresenter = nil;
}

- (void)emojiPickerCoordinatorBridgePresenterDidCancel:(EmojiPickerCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    self.emojiPickerCoordinatorBridgePresenter = nil;
}

#pragma mark - ReactionHistoryCoordinatorBridgePresenterDelegate

- (void)reactionHistoryCoordinatorBridgePresenterDelegateDidClose:(ReactionHistoryCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:^{
        self.reactionHistoryCoordinatorBridgePresenter = nil;
    }];
}

#pragma mark - CameraPresenterDelegate

- (void)cameraPresenterDidCancel:(CameraPresenter *)cameraPresenter
{
    [cameraPresenter dismissWithAnimated:YES completion:nil];
    self.cameraPresenter = nil;
}

- (void)cameraPresenter:(CameraPresenter *)cameraPresenter didSelectImageData:(NSData *)imageData withUTI:(MXKUTI *)uti
{
    [cameraPresenter dismissWithAnimated:YES completion:nil];
    self.cameraPresenter = nil;
    
    RoomInputToolbarView *roomInputToolbarView = [self inputToolbarViewAsRoomInputToolbarView];
    if (roomInputToolbarView)
    {
        [roomInputToolbarView sendSelectedImage:imageData
                                   withMimeType:uti.mimeType
                             andCompressionMode:MediaCompressionHelper.defaultCompressionMode
                            isPhotoLibraryAsset:NO];
    }
}

- (void)cameraPresenter:(CameraPresenter *)cameraPresenter didSelectVideoAt:(NSURL *)url
{
    [cameraPresenter dismissWithAnimated:YES completion:nil];
    self.cameraPresenter = nil;
    
    AVURLAsset *selectedVideo = [AVURLAsset assetWithURL:url];
    [self sendVideoAsset:selectedVideo isPhotoLibraryAsset:NO];
}

#pragma mark - MediaPickerCoordinatorBridgePresenterDelegate

- (void)mediaPickerCoordinatorBridgePresenterDidCancel:(MediaPickerCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    self.mediaPickerPresenter = nil;
}

- (void)mediaPickerCoordinatorBridgePresenter:(MediaPickerCoordinatorBridgePresenter *)coordinatorBridgePresenter didSelectImageData:(NSData *)imageData withUTI:(MXKUTI *)uti
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    self.mediaPickerPresenter = nil;
    
    RoomInputToolbarView *roomInputToolbarView = [self inputToolbarViewAsRoomInputToolbarView];
    if (roomInputToolbarView)
    {
        [roomInputToolbarView sendSelectedImage:imageData
                                   withMimeType:uti.mimeType
                             andCompressionMode:MediaCompressionHelper.defaultCompressionMode
                            isPhotoLibraryAsset:YES];
    }
}

- (void)mediaPickerCoordinatorBridgePresenter:(MediaPickerCoordinatorBridgePresenter *)coordinatorBridgePresenter didSelectVideo:(AVAsset *)videoAsset
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    self.mediaPickerPresenter = nil;
    
    [self sendVideoAsset:videoAsset isPhotoLibraryAsset:YES];
}

- (void)mediaPickerCoordinatorBridgePresenter:(MediaPickerCoordinatorBridgePresenter *)coordinatorBridgePresenter didSelectAssets:(NSArray<PHAsset *> *)assets
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    self.mediaPickerPresenter = nil;
    
    RoomInputToolbarView *roomInputToolbarView = [self inputToolbarViewAsRoomInputToolbarView];
    if (roomInputToolbarView)
    {
        // Set a 1080p video conversion preset as compression mode only has an effect on the images.
        [MXSDKOptions sharedInstance].videoConversionPresetName = AVAssetExportPreset1920x1080;
        
        [roomInputToolbarView sendSelectedAssets:assets withCompressionMode:MediaCompressionHelper.defaultCompressionMode];
    }
}

#pragma mark - RoomCreationModalCoordinatorBridgePresenter

- (void)roomCreationModalCoordinatorBridgePresenterDelegateDidComplete:(RoomCreationModalCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    self.roomCreationModalCoordinatorBridgePresenter = nil;
}

#pragma mark - RoomInfoCoordinatorBridgePresenterDelegate

- (void)roomInfoCoordinatorBridgePresenterDelegateDidComplete:(RoomInfoCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    self.roomInfoCoordinatorBridgePresenter = nil;
}

- (void)roomInfoCoordinatorBridgePresenter:(RoomInfoCoordinatorBridgePresenter *)coordinatorBridgePresenter didRequestMentionForMember:(MXRoomMember *)member
{
    [self mention:member];
}

- (void)roomInfoCoordinatorBridgePresenterDelegateDidLeaveRoom:(RoomInfoCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    if (self.delegate)
    {
        [self.delegate roomViewControllerDidLeaveRoom:self];
    }
    else
    {
        [[AppDelegate theDelegate] restoreInitialDisplay:nil];
    }
}

#pragma mark - RemoveJitsiWidgetViewDelegate

- (void)removeJitsiWidgetViewDidCompleteSliding:(RemoveJitsiWidgetView *)view
{
    view.delegate = nil;
    Widget *jitsiWidget = [customizedRoomDataSource jitsiWidget];
    
    [self startActivityIndicator];
    
    //  close the widget
    MXWeakify(self);
    
    [[WidgetManager sharedManager] closeWidget:jitsiWidget.widgetId
                                        inRoom:self.roomDataSource.room
                                       success:^{
        MXStrongifyAndReturnIfNil(self);
        [self stopActivityIndicator];
        //  we can wait for kWidgetManagerDidUpdateWidgetNotification, but we want to be faster
        self.removeJitsiWidgetContainer.hidden = YES;
        self.removeJitsiWidgetView.delegate = nil;
        
        //  end active call if exists
        if ([self isRoomHavingAJitsiCallForWidgetId:jitsiWidget.widgetId])
        {
            [self endActiveJitsiCall];
        }
    } failure:^(NSError *error) {
        MXStrongifyAndReturnIfNil(self);
        [self showJitsiErrorAsAlert:error];
        [self stopActivityIndicator];
    }];
}

#pragma mark - VoiceMessageControllerDelegate

- (void)voiceMessageControllerDidRequestMicrophonePermission:(VoiceMessageController *)voiceMessageController
{
    NSString *message = [MatrixKitL10n microphoneAccessNotGrantedForVoiceMessage:AppInfo.current.displayName];
    
    [MXKTools checkAccessForMediaType:AVMediaTypeAudio
                  manualChangeMessage: message
            showPopUpInViewController:self completionHandler:^(BOOL granted) {
        
    }];
}

- (void)voiceMessageController:(VoiceMessageController *)voiceMessageController
    didRequestSendForFileAtURL:(NSURL *)url
                      duration:(NSUInteger)duration
                       samples:(NSArray<NSNumber *> *)samples
                    completion:(void (^)(BOOL))completion
{
    [self.roomDataSource sendVoiceMessage:url mimeType:nil duration:duration samples:samples success:^(NSString *eventId) {
        MXLogDebug(@"Success with event id %@", eventId);
        completion(YES);
    } failure:^(NSError *error) {
        MXLogError(@"Failed sending voice message");
        completion(NO);
    }];
}

#pragma mark - SpaceDetailPresenterDelegate

- (void)spaceDetailPresenterDidComplete:(SpaceDetailPresenter *)presenter
{
    self.spaceDetailPresenter = nil;
}

- (void)spaceDetailPresenter:(SpaceDetailPresenter *)presenter didOpenSpaceWithId:(NSString *)spaceId
{
    self.spaceDetailPresenter = nil;
    [[LegacyAppDelegate theDelegate] openSpaceWithId:spaceId];
}

- (void)spaceDetailPresenter:(SpaceDetailPresenter *)presenter didJoinSpaceWithId:(NSString *)spaceId
{
    self.spaceDetailPresenter = nil;
    [[LegacyAppDelegate theDelegate] openSpaceWithId:spaceId];
}

#pragma mark - UserSuggestionCoordinatorBridgeDelegate

- (void)userSuggestionCoordinatorBridge:(UserSuggestionCoordinatorBridge *)coordinator
             didRequestMentionForMember:(MXRoomMember *)member
                            textTrigger:(NSString *)textTrigger
{
    if (textTrigger.length) {
        NSString *textMessage = [self.inputToolbarView textMessage];
        textMessage = [textMessage stringByReplacingOccurrencesOfString:textTrigger
                                                             withString:@""
                                                                options:NSBackwardsSearch | NSAnchoredSearch
                                                                  range:NSMakeRange(0, textMessage.length)];
        [self.inputToolbarView setTextMessage:textMessage];
    }
    
    [self mention:member];
}

@end
