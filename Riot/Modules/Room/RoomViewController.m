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
#import "RoomMembershipExpandedBubbleCell.h"
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

#import "RoomTimelineCellProvider.h"

#import "GeneratedInterface-Swift.h"

NSNotificationName const RoomCallTileTappedNotification = @"RoomCallTileTappedNotification";
NSNotificationName const RoomGroupCallTileTappedNotification = @"RoomGroupCallTileTappedNotification";
const NSTimeInterval kResizeComposerAnimationDuration = .05;
static const int kThreadListBarButtonItemTag = 99;
static UIEdgeInsets kThreadListBarButtonItemContentInsetsNoDot;
static UIEdgeInsets kThreadListBarButtonItemContentInsetsDot;
static CGSize kThreadListBarButtonItemImageSize;

@interface RoomViewController () <UISearchBarDelegate, UIGestureRecognizerDelegate, UIScrollViewAccessibilityDelegate, RoomTitleViewTapGestureDelegate, MXKRoomMemberDetailsViewControllerDelegate, ContactsTableViewControllerDelegate, MXServerNoticesDelegate, RoomContextualMenuViewControllerDelegate,
    ReactionsMenuViewModelCoordinatorDelegate, EditHistoryCoordinatorBridgePresenterDelegate, MXKDocumentPickerPresenterDelegate, EmojiPickerCoordinatorBridgePresenterDelegate,
    ReactionHistoryCoordinatorBridgePresenterDelegate, CameraPresenterDelegate, MediaPickerCoordinatorBridgePresenterDelegate,
    RoomDataSourceDelegate, RoomCreationModalCoordinatorBridgePresenterDelegate, RoomInfoCoordinatorBridgePresenterDelegate, DialpadViewControllerDelegate, RemoveJitsiWidgetViewDelegate, VoiceMessageControllerDelegate, SpaceDetailPresenterDelegate, UserSuggestionCoordinatorBridgeDelegate, ThreadsCoordinatorBridgePresenterDelegate, ThreadsBetaCoordinatorBridgePresenterDelegate, MXThreadingServiceDelegate, RoomParticipantsInviteCoordinatorBridgePresenterDelegate, RoomInputToolbarViewDelegate, ComposerCreateActionListBridgePresenterDelegate>
{
    
    // The preview header
    __weak PreviewRoomTitleView *previewHeader;
    
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
    
    // A flag indicating whether a room has been left
    BOOL isRoomLeft;
    
    // The last known frame of the view used to detect whether size-related layout change is needed
    CGRect lastViewBounds;
    
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

@property (nonatomic, strong) RemoveJitsiWidgetView *removeJitsiWidgetView;


@property (nonatomic, strong) RoomContextualMenuViewController *roomContextualMenuViewController;
@property (nonatomic, strong) RoomContextualMenuPresenter *roomContextualMenuPresenter;
@property (nonatomic, strong) MXKErrorAlertPresentation *errorPresenter;
@property (nonatomic, strong) NSAttributedString *textMessageBeforeEditing;
@property (nonatomic, strong) NSString *htmlTextBeforeEditing;
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
@property (nonatomic, strong) RoomParticipantsInviteCoordinatorBridgePresenter *participantsInvitePresenter;
@property (nonatomic, strong) ThreadsCoordinatorBridgePresenter *threadsBridgePresenter;
@property (nonatomic, strong) ThreadsBetaCoordinatorBridgePresenter *threadsBetaBridgePresenter;
@property (nonatomic, strong) SlidingModalPresenter *threadsNoticeModalPresenter;
@property (nonatomic, strong) ComposerCreateActionListBridgePresenter *composerCreateActionListBridgePresenter;
@property (nonatomic, getter=isActivitiesViewExpanded) BOOL activitiesViewExpanded;
@property (nonatomic, getter=isScrollToBottomHidden) BOOL scrollToBottomHidden;
@property (nonatomic, getter=isMissedDiscussionsBadgeHidden) BOOL missedDiscussionsBadgeHidden;

@property (nonatomic, strong) VoiceMessageController *voiceMessageController;
@property (nonatomic, strong) SpaceDetailPresenter *spaceDetailPresenter;

@property (nonatomic, strong) ShareManager *shareManager;
@property (nonatomic, strong) EventMenuBuilder *eventMenuBuilder;

@property (nonatomic, strong) UserSuggestionCoordinatorBridge *userSuggestionCoordinator;
@property (nonatomic, weak) IBOutlet UIView *userSuggestionContainerView;

@property (nonatomic, readwrite) RoomDisplayConfiguration *displayConfiguration;

// The direct chat target user. The room timeline is presented without an actual room until the direct chat is created
@property (nonatomic, nullable, strong) MXUser *directChatTargetUser;

// When layout of the screen changes (e.g. height), we no longer know whether
// to autoscroll to the bottom again or not. Instead we need to capture the
// scroll state just before the layout change, and restore it after the layout.
@property (nonatomic) BOOL wasScrollAtBottomBeforeLayout;

@end

@implementation RoomViewController
@synthesize roomPreviewData;

#pragma mark - Class methods

+ (void)initialize
{
    kThreadListBarButtonItemContentInsetsNoDot = UIEdgeInsetsMake(0, 8, 0, 8);
    kThreadListBarButtonItemContentInsetsDot = UIEdgeInsetsMake(0, 8, 6, 8);
    kThreadListBarButtonItemImageSize = CGSizeMake(21, 21);
}

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass(self.class)
                          bundle:[NSBundle bundleForClass:self.class]];
}

+ (instancetype)roomViewController
{
    RoomViewController *controller = [[[self class] alloc] initWithNibName:NSStringFromClass(self.class)
                                                                    bundle:[NSBundle bundleForClass:self.class]];
    controller.displayConfiguration = [RoomDisplayConfiguration default];
    return controller;
}

+ (instancetype)instantiateWithConfiguration:(RoomDisplayConfiguration *)configuration
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    NSString *storyboardId = [NSString stringWithFormat:@"%@StoryboardId", self.className];
    RoomViewController *controller = [storyboard instantiateViewControllerWithIdentifier:storyboardId];
    controller.displayConfiguration = configuration;
    return controller;
}

+ (NSString *)className
{
    NSString *result = NSStringFromClass(self.class);
    if ([result containsString:@"."])
    {
        result = [result componentsSeparatedByString:@"."].lastObject;
    }
    return result;
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

    [self registerPillAttachmentViewProviderIfNeeded];
    self.resizeComposerAnimationDuration = kResizeComposerAnimationDuration;
    
    // Setup `MXKViewControllerHandling` properties
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
    formattedBodyParser = [FormattedBodyParser new];
    self.eventMenuBuilder = [EventMenuBuilder new];
    
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
    [[RoomTimelineConfiguration shared].currentStyle.cellProvider registerCellsForTableView:self.bubblesTableView];
    
    [self vc_removeBackTitle];
    
    // Display leftBarButtonItems or leftBarButtonItem to the right of the Back button
    self.navigationItem.leftItemsSupplementBackButton = YES;
    
    [self setupRemoveJitsiWidgetRemoveView];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // Replace the default input toolbar view.
        // Note: this operation will force the layout of subviews. That is why cell view classes must be registered before.
        [self updateRoomInputToolbarViewClassIfNeeded];
    });
    
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
    
    [self setupUserSuggestionViewIfNeeded];
    
    [self.topBannersStackView vc_removeAllSubviews];
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
        [self.scrollToBottomButton setImage:AssetImages.scrolldownDark.image forState:UIControlStateNormal];

        self.jumpToLastUnreadBanner.backgroundColor = ThemeService.shared.theme.colors.navigation;
        [self.jumpToLastUnreadBanner vc_removeShadow];
        self.resetReadMarkerButton.tintColor = ThemeService.shared.theme.colors.quarterlyContent;
        if (self.maximisedToolbarDimmingView) {
            self.maximisedToolbarDimmingView.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.29];
        }
    }
    else
    {
        [self.scrollToBottomButton setImage:AssetImages.scrolldown.image forState:UIControlStateNormal];
        
        self.jumpToLastUnreadBanner.backgroundColor = ThemeService.shared.theme.colors.background;
        [self.jumpToLastUnreadBanner vc_addShadowWithColor:ThemeService.shared.theme.shadowColor
                                                    offset:CGSizeMake(0, 4)
                                                    radius:8
                                                   opacity:0.1];
        self.resetReadMarkerButton.tintColor = ThemeService.shared.theme.colors.tertiaryContent;
        if (self.maximisedToolbarDimmingView) {
            self.maximisedToolbarDimmingView.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.12];
        }
    }
    
    self.scrollToBottomBadgeLabel.badgeColor = ThemeService.shared.theme.tintColor;
    
    [self updateThreadListBarButtonBadgeWith:self.mainSession.threadingService];
    
    [self.liveLocationSharingBannerView updateWithTheme:ThemeService.shared.theme];
    
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
        
        notificationTaskProfile = [MXSDKOptions.sharedInstance.profiler startMeasuringTaskWithName:MXTaskProfileNameNotificationsOpenEvent];
    }
    
    [self updateTopBanners];
    
    self.bubblesTableView.clipsToBounds = NO;
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
    
    if (self.customizedRoomDataSource)
    {
        // Cancel potential selected event (to leave edition mode)
        if (self.customizedRoomDataSource.selectedEventId)
        {
            [self cancelEventSelection];
        }
    }
    [self cancelEventHighlight];
    
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
    [VoiceBroadcastRecorderProvider.shared pauseRecording];
    [VoiceBroadcastPlaybackProvider.shared pausePlaying];
    
    // Stop the loading indicator even if the session is still in progress
    [self stopLoadingUserIndicator];
    
    [self setMaximisedToolbarIsHiddenIfNeeded: YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Screen tracking
    MXRoomSummary *summary = [self.mainSession roomWithRoomId:self.roomDataSource.roomId].summary;
    if (!summary || !summary.isJoined)
    {
        [AnalyticsScreenTracker trackScreen: AnalyticsScreenRoomPreview];
    }
    else
    {
        [AnalyticsScreenTracker trackScreen: AnalyticsScreenRoom];
    }

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
    
    self.showSettingsInitially = NO;

    if (!RiotSettings.shared.threadsNoticeDisplayed && RiotSettings.shared.enableThreads)
    {
        [self showThreadsNotice];
    }

    if (self.saveProgressTextInput && self.roomDataSource)
    {
        // Retrieve the potential message partially typed during last room display.
        // Note: We have to wait for viewDidAppear before updating growingTextView (viewWillAppear is too early)
        self.inputToolbarView.attributedTextMessage = self.roomDataSource.partialAttributedTextMessage;
    }
    
    [self setMaximisedToolbarIsHiddenIfNeeded: NO];
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

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.wasScrollAtBottomBeforeLayout = self.isBubblesTableScrollViewAtTheBottom;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    BOOL didViewChangeBounds = !CGRectEqualToRect(lastViewBounds, self.view.bounds);
    lastViewBounds = self.view.bounds;
    
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
    
    // re-scroll to the bottom, if at bottom before the most recent layout
    if (self.wasScrollAtBottomBeforeLayout && didViewChangeBounds)
    {
        self.wasScrollAtBottomBeforeLayout = NO;
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

- (void)addMatrixSession:(MXSession *)mxSession
{
    [super addMatrixSession:mxSession];
    
    [mxSession.threadingService addDelegate:self];
    [self updateThreadListBarButtonBadgeWith:mxSession.threadingService];
}

- (void)removeMatrixSession:(MXSession *)mxSession
{
    [mxSession.threadingService removeDelegate:self];
    
    [super removeMatrixSession:mxSession];
}

- (void)onMatrixSessionChange
{
    [super onMatrixSessionChange];
    
    // Re-enable the read marker display, and disable its update.
    self.roomDataSource.showReadMarker = YES;
    self.updateRoomReadMarker = NO;
}

#pragma mark - Loading indicators

- (BOOL)providesCustomActivityIndicator {
    return YES;
}

// Override of a legacy method to determine whether to use a newer implementation instead.
// Will be removed in the future https://github.com/vector-im/element-ios/issues/5608
- (void)startActivityIndicator {
    [self.delegate roomViewControllerDidStartLoading:self];
}

// Override of a legacy method to determine whether to use a newer implementation instead.
// Will be removed in the future https://github.com/vector-im/element-ios/issues/5608
- (void)stopActivityIndicator
{
    if (notificationTaskProfile)
    {
        // Consider here we have displayed the message corresponding to the notification
        [MXSDKOptions.sharedInstance.profiler stopMeasuringTaskWithProfile:notificationTaskProfile];
        notificationTaskProfile = nil;
    }
    // The legacy super implementation of `stopActivityIndicator` contains a number of checks grouped under `canStopActivityIndicator`
    // to determine whether the indicator can be stopped or not (and the method should thus rather be called `stopActivityIndicatorIfPossible`).
    // Since the newer indicators are not calling super implementation, the check for `canStopActivityIndicator` has to be performed manually.
    if ([self canStopActivityIndicator]) {
        [self stopLoadingUserIndicator];
    }
}

- (void)stopLoadingUserIndicator
{
    [self.delegate roomViewControllerDidStopLoading:self];
}

- (void)displayRoom:(MXKRoomDataSource *)dataSource
{
    // Remove potential preview Data
    if (roomPreviewData)
    {
        roomPreviewData = nil;
        [self removeMatrixSession:self.mainSession];
    }
    
    // Set potential discussion target user to nil, now use the dataSource to populate the view
    self.directChatTargetUser = nil;
    
    // Enable the read marker display, and disable its update.
    dataSource.showReadMarker = YES;
    self.updateRoomReadMarker = NO;
    
    [super displayRoom:dataSource];
    
    self.customizedRoomDataSource = nil;
    
    if (self.roomDataSource)
    {
        [self listenToServerNotices];
        
        self.eventsAcknowledgementEnabled = YES;
        
        // Store ref on customized room data source
        if ([dataSource isKindOfClass:RoomDataSource.class])
        {
            self.customizedRoomDataSource = (RoomDataSource*)dataSource;
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
    
    [self setupUserSuggestionViewIfNeeded];
    
    [self updateTopBanners];
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
    
    [super onRoomDataSourceReady];
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
    else if (self.isNewDirectChat)
    {
        [self refreshRoomInputToolbar];
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
    [self notifyDelegateOnLeaveRoomIfNecessary];
}


+ (Class) mainToolbarClass
{
    if (RiotSettings.shared.enableWysiwygComposer)
    {
        return WysiwygInputToolbarView.class;
    }
    else
    {
        return RoomInputToolbarView.class;
    }
}

// Set the input toolbar according to the current display
- (void)updateRoomInputToolbarViewClassIfNeeded
{
    Class roomInputToolbarViewClass = [RoomViewController mainToolbarClass];
    
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
        if ([self.inputToolbarView.class conformsToProtocol:@protocol(RoomInputToolbarViewProtocol)]) {
            id<RoomInputToolbarViewProtocol> inputToolbar = (id<RoomInputToolbarViewProtocol>)self.inputToolbarView;
            [inputToolbar setVoiceMessageToolbarView:self.voiceMessageController.voiceMessageToolbarView];
        }
        
        [self updateInputToolBarViewHeight];
        [self refreshRoomInputToolbar];
    }
}

// Get the height of the current room input toolbar
- (CGFloat)inputToolbarHeight
{
    CGFloat height = 0;
    
    if ([self.inputToolbarView.class conformsToProtocol:@protocol(RoomInputToolbarViewProtocol)]) {
        id<RoomInputToolbarViewProtocol> inputToolbar = (id<RoomInputToolbarViewProtocol>)self.inputToolbarView;
        height = inputToolbar.toolbarHeight;
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

- (BOOL)sendAsIRCStyleCommandIfPossible:(NSString*)string
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
            Analytics.shared.joinedRoomTrigger = AnalyticsJoinedRoomTriggerSlashCommand;
            
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
    return [super sendAsIRCStyleCommandIfPossible:string];
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
            [self refreshRoomTitle];
            
            [self checkReadMarkerVisibility];
            [self refreshJumpToLastUnreadBannerDisplay];
        }
    }
}

- (void)sendTextMessage:(NSString*)msgTxt
{
    // Create before sending the message in case of a discussion (direct chat)
    MXWeakify(self);
    [self createDiscussionIfNeeded:^(BOOL readyToSend) {
        MXStrongifyAndReturnIfNil(self);
        if (readyToSend)
        {
            // The event modified is always fetch from the actual data source
            MXEvent *eventModified = [self.roomDataSource eventWithEventId:self.customizedRoomDataSource.selectedEventId];
            
            // In the case the event is a reply or and edit, and it's done on a non-live timeline
            // we have to fetch live timeline in order to display the event properly
            [self setupRoomDataSourceToResolveEvent:^(MXKRoomDataSource *roomDataSource) {
                if (self.inputToolBarSendMode == RoomInputToolbarViewSendModeReply && eventModified)
                {
                    [roomDataSource sendReplyToEvent:eventModified withTextMessage:msgTxt success:nil failure:^(NSError *error) {
                        // Just log the error. The message will be displayed in red in the room history
                        MXLogDebug(@"[MXKRoomViewController] sendTextMessage failed.");
                    }];
                }
                else if (self.inputToolBarSendMode == RoomInputToolbarViewSendModeEdit && eventModified)
                {
                    [roomDataSource replaceTextMessageForEvent:eventModified withTextMessage:msgTxt success:nil failure:^(NSError *error) {
                        // Just log the error. The message will be displayed in red
                        MXLogDebug(@"[MXKRoomViewController] sendTextMessage failed.");
                    }];
                }
                else
                {
                    // Let the datasource send it and manage the local echo
                    [roomDataSource sendTextMessage:msgTxt success:nil failure:^(NSError *error)
                     {
                        // Just log the error. The message will be displayed in red in the room history
                        MXLogDebug(@"[MXKRoomViewController] sendTextMessage failed.");
                    }];
                }
                
                if (self.customizedRoomDataSource.selectedEventId)
                {
                    [self cancelEventSelection];
                }
            }];
        }
        // Errors are handled at the request level. This should be improved in case of code rewriting.
    }];
}

- (void)setupRoomDataSourceToResolveEvent: (void (^)(MXKRoomDataSource *roomDataSource))onComplete
{
    // If the event occur on timeline not live, use the live data source to resolve event
    BOOL isLive = self.roomDataSource.isLive;
    if (!isLive)
    {
        if (self.roomDataSourceLive == nil)
        {
            MXKRoomDataSourceManager *roomDataSourceManager = [MXKRoomDataSourceManager sharedManagerForMatrixSession:self.mainSession];

            [roomDataSourceManager roomDataSourceForRoom:self.roomDataSource.roomId
                                                  create:YES
                                              onComplete:^(MXKRoomDataSource *roomDataSource) {
                self.roomDataSourceLive = roomDataSource;
                [self.roomDataSourceLive finalizeInitialization];
                onComplete(self.roomDataSourceLive);
            }];
        }
        else
        {
            onComplete(self.roomDataSourceLive);
        }
    }
    else
    {
        onComplete(self.roomDataSource);
    }
}

- (void)setRoomTitleViewClass:(Class)roomTitleViewClass
{
    if ([self.titleView.class isEqual:roomTitleViewClass]) {
        return;
    }
    
    // Sanity check: accept only MXKRoomTitleView classes or sub-classes
    NSParameterAssert([roomTitleViewClass isSubclassOfClass:MXKRoomTitleView.class]);
    
    MXKRoomTitleView *titleView = [roomTitleViewClass roomTitleView];
    [self setValue:titleView forKey:@"titleView"];
    titleView.delegate = self;
    titleView.mxRoom = self.roomDataSource.room;
    titleView.mxUser = self.directChatTargetUser;
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
    
    if (self.customizedRoomDataSource)
    {
        self.customizedRoomDataSource.selectedEventId = nil;
        self.customizedRoomDataSource = nil;
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

#pragma mark - Start DM

/**
 Create a direct chat with given user.
 */
- (void)createDiscussionWithUser:(MXUser*)user completion:(void (^)(BOOL success))onComplete
{
    [self startActivityIndicator];
    
    [[AppDelegate theDelegate] createDirectChatWithUserId:user.userId completion:^(NSString *roomId) {
        if (roomId)
        {
            MXKRoomDataSourceManager *roomDataSourceManager = [MXKRoomDataSourceManager sharedManagerForMatrixSession:self.mainSession];
            [roomDataSourceManager roomDataSourceForRoom:roomId create:YES onComplete:^(MXKRoomDataSource *roomDataSource) {
                [self stopActivityIndicator];
                [self setRoomInputToolbarViewClass:nil];
                [self displayRoom:roomDataSource];
                
                onComplete(YES);
            }];
        }
        else
        {
            [self stopActivityIndicator];
            onComplete(NO);
        }
    }];
}

/**
 Create the discussion if needed
 */
- (void)createDiscussionIfNeeded:(void (^)(BOOL readyToSend))onComplete
{
    void(^completion)(BOOL) = ^(BOOL readyToSend) {
        self.inputToolbarView.userInteractionEnabled = true;
        if (onComplete) {
            onComplete(readyToSend);
        }
    };
    
    if (self.directChatTargetUser)
    {
        // Disable the input tool bar during this operation. This prevents us from creating several discussions, or
        // trying to send several invites.
        self.inputToolbarView.userInteractionEnabled = false;
        
        [self createDiscussionWithUser:self.directChatTargetUser completion:completion];
    }
    else
    {
        completion(YES);
    }
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

- (BOOL)shouldShowLiveLocationSharingBannerView
{
    return self.customizedRoomDataSource.isCurrentUserSharingActiveLocation;
}

#pragma mark - Internals

- (UIBarButtonItem *)videoCallBarButtonItem
{
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:AssetImages.videoCall.image
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(onVideoCallPressed:)];
    item.accessibilityLabel = [VectorL10n roomAccessibilityVideoCall];
    
    return item;
}

- (UIBarButtonItem *)joinJitsiBarButtonItem
{
    CallTileActionButton *button = [CallTileActionButton new];
    [button setImage:AssetImages.callVideoIcon.image
            forState:UIControlStateNormal];
    [button setTitle:[VectorL10n roomJoinGroupCall]
            forState:UIControlStateNormal];
    [button addTarget:self
               action:@selector(onVideoCallPressed:)
     forControlEvents:UIControlEventTouchUpInside];
    button.contentEdgeInsets = UIEdgeInsetsMake(4, 12, 4, 12);
    
    UIBarButtonItem *item;
    
    if (RiotSettings.shared.enableThreads)
    {
        // Add some spacing when there is a threads button
        UIView *buttonContainer = [[UIView alloc] initWithFrame:CGRectZero];
        [buttonContainer vc_addSubViewMatchingParent:button withInsets:UIEdgeInsetsMake(0, 0, 0, -12)];
        
        item = [[UIBarButtonItem alloc] initWithCustomView:buttonContainer];
    }
    else
    {
        item = [[UIBarButtonItem alloc] initWithCustomView:button];
    }
    
    item.accessibilityLabel = [VectorL10n roomAccessibilityVideoCall];
    
    return item;
}

- (UIBarButtonItem *)threadMoreBarButtonItem
{
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:AssetImages.roomContextMenuMore.image
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(onButtonPressed:)];
    item.accessibilityLabel = [VectorL10n roomAccessibilityThreadMore];
    
    return item;
}

- (UIBarButtonItem *)threadListBarButtonItem
{
    UIButton *button = [UIButton new];
    button.contentEdgeInsets = kThreadListBarButtonItemContentInsetsNoDot;
    button.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [button setImage:[AssetImages.threadsIcon.image vc_resizedWith:kThreadListBarButtonItemImageSize]
            forState:UIControlStateNormal];
    [button addTarget:self
               action:@selector(onThreadListTapped:)
     forControlEvents:UIControlEventTouchUpInside];
    button.accessibilityLabel = [VectorL10n roomAccessibilityThreads];

    UIBarButtonItem *result = [[UIBarButtonItem alloc] initWithCustomView:button];
    result.tag = kThreadListBarButtonItemTag;
    return result;
}

- (void)setupRemoveJitsiWidgetRemoveView
{
    if (!self.displayConfiguration.jitsiWidgetRemoverEnabled)
    {
        return;
    }
    
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
    if (self.isContextPreview)
    {
        return YES;
    }
    
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

// Indicates if a new direct chat with a target user (without associated room) is occuring.
- (BOOL)isNewDirectChat
{
    return self.directChatTargetUser != nil;
}

- (BOOL)isEncryptionEnabled
{
    return self.roomDataSource.room.summary.isEncrypted && self.mainSession.crypto != nil;
}

- (BOOL)supportCallOption
{
    if (!self.displayConfiguration.callsEnabled)
    {
        return NO;
    }
    BOOL callOptionAllowed = (self.roomDataSource.room.isDirect && RiotSettings.shared.roomScreenAllowVoIPForDirectRoom) || (!self.roomDataSource.room.isDirect && RiotSettings.shared.roomScreenAllowVoIPForNonDirectRoom);
    return callOptionAllowed && BuildSettings.allowVoIPUsage && self.roomDataSource.mxSession.callManager && self.roomDataSource.room.summary.membersCount.joined >= 2;
}

- (BOOL)isCallActive
{
    MXCall *callInRoom = [self.roomDataSource.mxSession.callManager callInRoom:self.roomDataSource.roomId];
    
    return (callInRoom && callInRoom.state != MXCallStateEnded)
    || self.customizedRoomDataSource.jitsiWidget;
}

- (BOOL)canSendStateEventWithType:(MXEventTypeString)eventTypeString
{
    MXRoomPowerLevels *powerLevels = [self.roomDataSource.roomState powerLevels];
    NSInteger requiredPower = [powerLevels minimumPowerLevelForSendingEventAsStateEvent:eventTypeString];
    NSInteger myPower = [powerLevels powerLevelOfUserWithUserID:self.roomDataSource.mxSession.myUserId];
    return myPower >= requiredPower;
}

/**
 Returns a flag for the current user whether it's privileged to add/remove Jitsi widgets to this room.
 */
- (BOOL)canEditJitsiWidget
{
    return [self canSendStateEventWithType:kWidgetModularEventTypeString];
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
                    UIBarButtonItem *itemVoice = [[UIBarButtonItem alloc] initWithImage:AssetImages.voiceCallHangonIcon.image
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
                            UIBarButtonItem *item = [self joinJitsiBarButtonItem];
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
                            item.image = [AssetImages.videoCall.image vc_withAlpha:0.3];
                        }
                        [rightBarButtonItems addObject:item];
                    }
                }
            }
            
            if ([self widgetsCount:NO])
            {
                UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:AssetImages.integrationsIcon.image
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
        }
        
        // Do not change title view class here if the expanded header is visible.
        [self setRoomTitleViewClass:RoomTitleView.class];
        ((RoomTitleView*)self.titleView).tapGestureDelegate = self;
        
        MXKImageView *userPictureView = ((RoomTitleView*)self.titleView).pictureView;
        
        // Set user picture in input toolbar
        if (userPictureView)
        {
            [self.roomDataSource.room.summary setRoomAvatarImageIn:userPictureView];
        }
        
        [self refreshMissedDiscussionsCount:YES];
        
        if (RiotSettings.shared.enableThreads)
        {
            if (self.roomDataSource.threadId)
            {
                //  in a thread
                if (rightBarButtonItems == nil)
                {
                    rightBarButtonItems = [NSMutableArray new];
                }
                UIBarButtonItem *itemThreadMore = [self threadMoreBarButtonItem];
                [rightBarButtonItems insertObject:itemThreadMore atIndex:0];
            }
            else
            {
                //  in a regular timeline
                UIBarButtonItem *itemThreadList = [self threadListBarButtonItem];
                [self updateThreadListBarButtonItem:itemThreadList
                                               with:self.mainSession.threadingService];
                [rightBarButtonItems insertObject:itemThreadList atIndex:0];
            }
        }
    }
    else if (self.isNewDirectChat)
    {
        [self showPreviewHeader:NO];
        
        [self setRoomTitleViewClass:RoomTitleView.class];
        MXKImageView *userPictureView = ((RoomTitleView*)self.titleView).pictureView;
        
        // Set user picture in input toolbar
        if (userPictureView)
        {
            [userPictureView vc_setRoomAvatarImageWith:self.directChatTargetUser.avatarUrl
                                                roomId:self.directChatTargetUser.userId
                                           displayName:self.directChatTargetUser.displayname
                                          mediaManager:self.mainSession.mediaManager];
        }
    }
    
    self.navigationItem.rightBarButtonItems = rightBarButtonItems;
}

- (void)updateInputToolBarVisibility
{
    BOOL hideInputToolBar = NO;
    
    if (self.roomDataSource)
    {
        hideInputToolBar = (self.roomDataSource.state != MXKDataSourceStateReady);
    }
    
    self.inputToolbarView.hidden = hideInputToolBar;
}

- (void)refreshRoomInputToolbar
{
    MXKImageView *userPictureView;
    
    // Show or hide input tool bar
    [self updateInputToolBarVisibility];
    
    // Check whether the input toolbar is ready before updating it.
    if (self.inputToolbarView && [self inputToolbarConformsToToolbarViewProtocol])
    {
        id<RoomInputToolbarViewProtocol> roomInputToolbarView = (id<RoomInputToolbarViewProtocol>) self.inputToolbarView;
        
        // Update encryption decoration if needed
        [self updateEncryptionDecorationForRoomInputToolbar:roomInputToolbarView];

        // Update actions when the input toolbar refreshed
        [self setupActions];
        
        // Update placeholder and hide voice message view
        if (self.isNewDirectChat)
        {
            [self setInputToolBarSendMode:RoomInputToolbarViewSendModeCreateDM forEventWithId:nil];
            [roomInputToolbarView setVoiceMessageToolbarView:nil];
        }
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
    if (self.inputToolbarView && [self inputToolbarConformsToToolbarViewProtocol])
    {
        MXKRoomInputToolbarView <RoomInputToolbarViewProtocol> *roomInputToolbarView = (MXKRoomInputToolbarView <RoomInputToolbarViewProtocol> *) self.inputToolbarView;
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
    if (self.inputToolbarView && [self inputToolbarConformsToToolbarViewProtocol])
    {
        id<RoomInputToolbarViewProtocol> roomInputToolbarView = (id<RoomInputToolbarViewProtocol>)self.inputToolbarView;
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

- (void)updateEncryptionDecorationForRoomInputToolbar:(id<RoomInputToolbarViewProtocol>)roomInputToolbarView
{
    roomInputToolbarView.isEncryptionEnabled = self.isEncryptionEnabled;
}

- (void)handleLongPressFromCell:(id<MXKCellRendering>)cell withTappedEvent:(MXEvent*)event
{
    if (event && !self.customizedRoomDataSource.selectedEventId)
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
    
    if ([self.inputToolbarView isKindOfClass:RoomInputToolbarView.class])
    {
        sourceView = ((RoomInputToolbarView*)self.inputToolbarView).attachMediaButton;
    }
    else
    {
        sourceView = self.inputToolbarView;
    }
    
    [mediaPickerPresenter presentFrom:self sourceView:sourceView sourceRect:sourceView.bounds animated:YES];
    
    self.mediaPickerPresenter = mediaPickerPresenter;
}

- (void)showRoomCreationModal
{
    [self.roomCreationModalCoordinatorBridgePresenter dismissWithAnimated:NO completion:nil];
    
    self.roomCreationModalCoordinatorBridgePresenter = [[RoomCreationModalCoordinatorBridgePresenter alloc] initWithSession:self.mainSession roomState:self.roomDataSource.roomState];
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
    [self showRoomInfoWithInitialSection:RoomInfoSectionChangeAvatar animated:YES];
}

- (void)showAddParticipants
{
    self.participantsInvitePresenter = [[RoomParticipantsInviteCoordinatorBridgePresenter alloc] initWithSession:self.roomDataSource.mxSession room:self.roomDataSource.room parentSpaceId:self.parentSpaceId];
    self.participantsInvitePresenter.delegate = self;
    [self.participantsInvitePresenter presentFrom:self animated:YES];
}

- (void)showRoomTopicChange
{
    [self showRoomInfoWithInitialSection:RoomInfoSectionChangeTopic animated:YES];
}

- (void)showRoomInfo
{
    [self showRoomInfoWithInitialSection:RoomInfoSectionNone animated:YES];
}

- (void)showRoomInfoWithInitialSection:(RoomInfoSection)roomInfoSection animated:(BOOL)animated
{
    RoomInfoCoordinatorParameters *parameters = [[RoomInfoCoordinatorParameters alloc] initWithSession:self.roomDataSource.mxSession room:self.roomDataSource.room parentSpaceId:self.parentSpaceId initialSection:roomInfoSection];
    
    self.roomInfoCoordinatorBridgePresenter = [[RoomInfoCoordinatorBridgePresenter alloc] initWithParameters:parameters];
    
    self.roomInfoCoordinatorBridgePresenter.delegate = self;
    [self.roomInfoCoordinatorBridgePresenter pushFrom:self.navigationController animated:animated];
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
        [actionItems addObject:[[RoomActionItem alloc] initWithImage:AssetImages.actionMediaLibrary.image andAction:^{
            MXStrongifyAndReturnIfNil(self);
            if ([self.inputToolbarView isKindOfClass:RoomInputToolbarView.class]) {
                ((RoomInputToolbarView *) self.inputToolbarView).actionMenuOpened = NO;
            }
            [self showMediaPickerAnimated:YES];
        }]];
    }
    if (RiotSettings.shared.roomScreenAllowStickerAction && !self.isNewDirectChat)
    {
        [actionItems addObject:[[RoomActionItem alloc] initWithImage:AssetImages.actionSticker.image andAction:^{
            MXStrongifyAndReturnIfNil(self);
            if ([self.inputToolbarView isKindOfClass:RoomInputToolbarView.class]) {
                ((RoomInputToolbarView *) self.inputToolbarView).actionMenuOpened = NO;
            }
            [self roomInputToolbarViewPresentStickerPicker];
        }]];
    }
    if (RiotSettings.shared.roomScreenAllowFilesAction)
    {
        [actionItems addObject:[[RoomActionItem alloc] initWithImage:AssetImages.actionFile.image andAction:^{
            MXStrongifyAndReturnIfNil(self);
            if ([self.inputToolbarView isKindOfClass:RoomInputToolbarView.class]) {
                ((RoomInputToolbarView *) self.inputToolbarView).actionMenuOpened = NO;
            }
            [self roomInputToolbarViewDidTapFileUpload];
        }]];
    }
    if (RiotSettings.shared.enableVoiceBroadcast && !self.isNewDirectChat)
    {
        [actionItems addObject:[[RoomActionItem alloc] initWithImage:AssetImages.actionLive.image andAction:^{
            MXStrongifyAndReturnIfNil(self);
            if ([self.inputToolbarView isKindOfClass:RoomInputToolbarView.class]) {
                ((RoomInputToolbarView *) self.inputToolbarView).actionMenuOpened = NO;
            }
            [self roomInputToolbarViewDidTapVoiceBroadcast];
        }]];
    }
    if (BuildSettings.pollsEnabled && self.displayConfiguration.sendingPollsEnabled && !self.isNewDirectChat)
    {
        [actionItems addObject:[[RoomActionItem alloc] initWithImage:AssetImages.actionPoll.image andAction:^{
            MXStrongifyAndReturnIfNil(self);
            if ([self.inputToolbarView isKindOfClass:RoomInputToolbarView.class]) {
                ((RoomInputToolbarView *) self.inputToolbarView).actionMenuOpened = NO;
            }
            [self.delegate roomViewControllerDidRequestPollCreationFormPresentation:self];
        }]];
    }
    if (BuildSettings.locationSharingEnabled && !self.isNewDirectChat)
    {
        [actionItems addObject:[[RoomActionItem alloc] initWithImage:AssetImages.actionLocation.image andAction:^{
            MXStrongifyAndReturnIfNil(self);
            if ([self.inputToolbarView isKindOfClass:RoomInputToolbarView.class]) {
                ((RoomInputToolbarView *) self.inputToolbarView).actionMenuOpened = NO;
            }
            [self.delegate roomViewControllerDidRequestLocationSharingFormPresentation:self];
        }]];
    }
    if (RiotSettings.shared.roomScreenAllowCameraAction)
    {
        [actionItems addObject:[[RoomActionItem alloc] initWithImage:AssetImages.actionCamera.image andAction:^{
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
        
        [installPrompt addAction:[UIAlertAction actionWithTitle:[VectorL10n no]
                                                          style:UIAlertActionStyleCancel
                                                        handler:^(UIAlertAction * action)
                                 {
            MXStrongifyAndReturnIfNil(self);
            self->currentAlert = nil;
            
        }]];
        
        [installPrompt addAction:[UIAlertAction actionWithTitle:[VectorL10n yes]
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

- (void)roomInputToolbarViewDidTapVoiceBroadcast
{
    // Check first the room permission
    if (![self canSendStateEventWithType:VoiceBroadcastSettings.voiceBroadcastInfoContentKeyType])
    {
        [self showAlertWithTitle:[VectorL10n voiceBroadcastUnauthorizedTitle] message:[VectorL10n voiceBroadcastPermissionDeniedMessage]];
        return;
    }
    
    MXSession* session = self.roomDataSource.mxSession;
    // Check whether the user is not already broadcasting here or in another room
    if (session.voiceBroadcastService)
    {
        [self showAlertWithTitle:[VectorL10n voiceBroadcastUnauthorizedTitle] message:[VectorL10n voiceBroadcastAlreadyInProgressMessage]];
        return;
    }
    
    // Request the voice broadcast service to start recording - No service is returned if someone else is already broadcasting in the room
    [session getOrCreateVoiceBroadcastServiceFor:self.roomDataSource.room completion:^(VoiceBroadcastService *voiceBroadcastService) {
        if (voiceBroadcastService) {
            [voiceBroadcastService startVoiceBroadcastWithSuccess:^(NSString * _Nullable success) {
            
            } failure:^(NSError * _Nonnull error) {
                
            }];
        }
        else
        {
            [self showAlertWithTitle:[VectorL10n voiceBroadcastUnauthorizedTitle] message:[VectorL10n voiceBroadcastBlockedBySomeoneElseMessage]];
        }
    }];
}

/**
 Send a video asset via the room input toolbar prompting the user for the conversion preset to use
 if the `showMediaCompressionPrompt` setting has been enabled.
 @param videoAsset The video asset to send
 @param isPhotoLibraryAsset Whether the asset was picked from the user's photo library.
 */
- (void)sendVideoAsset:(AVAsset *)videoAsset isPhotoLibraryAsset:(BOOL)isPhotoLibraryAsset
{
    if (![self inputToolbarConformsToToolbarViewProtocol])
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
            
            // Create before sending the message in case of a discussion (direct chat)
            [self createDiscussionIfNeeded:^(BOOL readyToSend) {
                if (readyToSend && [self inputToolbarConformsToToolbarViewProtocol])
                {
                    [self.inputToolbarView sendSelectedVideoAsset:videoAsset isPhotoLibraryAsset:isPhotoLibraryAsset];
                }
                // Errors are handled at the request level. This should be improved in case of code rewriting.
            }];
        }];
        
        UIView *sourceView;
        
        if ([self.inputToolbarView isKindOfClass:RoomInputToolbarView.class])
        {
            sourceView = ((RoomInputToolbarView*)self.inputToolbarView).attachMediaButton;
        }
        else
        {
            sourceView = self.inputToolbarView;
        }
        
        compressionPrompt.popoverPresentationController.sourceView = sourceView;
        compressionPrompt.popoverPresentationController.sourceRect = sourceView.bounds;
        
        [self presentViewController:compressionPrompt animated:YES completion:nil];
    }
    else
    {
        // Otherwise default to 1080p and send the video.
        [MXSDKOptions sharedInstance].videoConversionPresetName = AVAssetExportPreset1920x1080;
        
        // Create before sending the message in case of a discussion (direct chat)
        [self createDiscussionIfNeeded:^(BOOL readyToSend) {
            if (readyToSend && [self inputToolbarConformsToToolbarViewProtocol])
            {
                [self.inputToolbarView sendSelectedVideoAsset:videoAsset isPhotoLibraryAsset:isPhotoLibraryAsset];
            }
            // Errors are handled at the request level. This should be improved in case of code rewriting.
        }];
    }
}

- (void)showRoomWithId:(NSString*)roomId
{
    if (self.delegate)
    {
        [self.delegate roomViewController:self showRoomWithId:roomId eventId:nil];
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
        [self notifyDelegateOnLeaveRoomIfNecessary];
        
    } failure:^(NSError *error) {
        
        [self stopActivityIndicator];
        MXLogDebug(@"[RoomVC] Failed to reject an invited room (%@) failed", self.roomDataSource.room.roomId);
        
    }];
}

- (void)notifyDelegateOnLeaveRoomIfNecessary {
    if (isRoomLeft) {
        return;
    }
    isRoomLeft = YES;
    
    if (self.delegate)
    {
        [self.delegate roomViewControllerDidLeaveRoom:self];
    }
    else
    {
        [[AppDelegate theDelegate] restoreInitialDisplay:^{}];
    }
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
        [[AppDelegate theDelegate] showNewDirectChat:userId withMatrixSession:self.mainSession completion:completion];
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

- (BOOL)handleUniversalLinkURL:(NSURL*)url
{
    ScreenPresentationParameters *screenParameters = [self buildUniversalLinkPresentationParameters];
    UniversalLinkParameters *parameters = [[UniversalLinkParameters alloc] initWithUrl:url
                                                                presentationParameters:screenParameters];
    return [self handleUniversalLinkWithParameters:parameters];
}

- (BOOL)handleUniversalLinkFragment:(NSString*)fragment fromURL:(NSURL*)url
{
    ScreenPresentationParameters *screenParameters = [self buildUniversalLinkPresentationParameters];
    UniversalLink *universalLink = [[UniversalLink alloc] initWithUrl:url];
    UniversalLinkParameters *parameters = [[UniversalLinkParameters alloc] initWithFragment:fragment
                                                                              universalLink:universalLink
                                                                     presentationParameters:screenParameters];
    return [self handleUniversalLinkWithParameters:parameters];
}

- (BOOL)handleUniversalLinkWithParameters:(UniversalLinkParameters*)parameters
{
    Analytics.shared.joinedRoomTrigger = AnalyticsJoinedRoomTriggerTimeline;
    
    if (self.delegate)
    {
        return [self.delegate roomViewController:self handleUniversalLinkWithParameters:parameters];
    }
    else
    {
        return [[AppDelegate theDelegate] handleUniversalLinkWithParameters:parameters];
    }
}

- (void)setupUserSuggestionViewIfNeeded
{
    if(!self.isViewLoaded) {
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

- (void)updateTopBanners
{
    [self.view bringSubviewToFront:self.topBannersStackView];
    
    [self updateLiveLocationBannerViewVisibility];
}

- (void)showEmojiPickerForEventId:(NSString *)eventId
{
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
                previewHeader.roomAvatarPlaceholder = [MXKTools paintImage:AssetImages.placeholder.image
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
            
            self->previewHeader.roomAvatar.alpha = 1;
            
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

#pragma mark - New discussion

- (void)displayNewDirectChatWithTargetUser:(nonnull MXUser*)directChatTargetUser session:(nonnull MXSession*)session
{
    // Release existing room data source or preview
    [self displayRoom:nil];
    
    self.directChatTargetUser = directChatTargetUser;
    
    self.eventsAcknowledgementEnabled = NO;
    
    [self addMatrixSession:session];
    
    [self refreshRoomTitle];
    [self refreshRoomInputToolbar];
}

#pragma mark - MXKDataSourceDelegate

- (Class<MXKCellRendering>)cellViewClassForCellData:(MXKCellData*)cellData
{
    RoomTimelineCellIdentifier cellIdentifier = [self cellIdentifierForCellData:cellData andRoomDataSource:self.customizedRoomDataSource];
    
    RoomTimelineConfiguration *timelineConfiguration = [RoomTimelineConfiguration shared];
            
    return [timelineConfiguration.currentStyle.cellProvider cellViewClassForCellIdentifier:cellIdentifier];;
}

- (RoomTimelineCellIdentifier)cellIdentifierForCellData:(MXKCellData*)cellData andRoomDataSource:(RoomDataSource *)customizedRoomDataSource;
{
    // Sanity check
    if (![cellData conformsToProtocol:@protocol(MXKRoomBubbleCellDataStoring)])
    {
        return RoomTimelineCellIdentifierUnknown;
    }
    
    BOOL showEncryptionBadge = NO;
    RoomTimelineCellIdentifier cellIdentifier;
        
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
        cellIdentifier = RoomTimelineCellIdentifierEmpty;
    }
    else if (bubbleData.tag == RoomBubbleCellDataTagRoomCreationIntro)
    {
        cellIdentifier = RoomTimelineCellIdentifierRoomCreationIntro;
    }
    else if (bubbleData.tag == RoomBubbleCellDataTagRoomCreateWithPredecessor)
    {
        cellIdentifier = RoomTimelineCellIdentifierRoomPredecessor;
    }
    else if (bubbleData.tag == RoomBubbleCellDataTagKeyVerificationRequestIncomingApproval)
    {
        cellIdentifier = bubbleData.isPaginationFirstBubble ? RoomTimelineCellIdentifierKeyVerificationIncomingRequestApprovalWithPaginationTitle : RoomTimelineCellIdentifierKeyVerificationIncomingRequestApproval;
    }
    else if (bubbleData.tag == RoomBubbleCellDataTagKeyVerificationRequest)
    {
        cellIdentifier = bubbleData.isPaginationFirstBubble ? RoomTimelineCellIdentifierKeyVerificationRequestStatusWithPaginationTitle : RoomTimelineCellIdentifierKeyVerificationRequestStatus;
    }
    else if (bubbleData.tag == RoomBubbleCellDataTagKeyVerificationConclusion)
    {
        cellIdentifier = bubbleData.isPaginationFirstBubble ? RoomTimelineCellIdentifierKeyVerificationConclusionWithPaginationTitle : RoomTimelineCellIdentifierKeyVerificationConclusion;
    }
    else if (bubbleData.tag == RoomBubbleCellDataTagMembership)
    {
        if (bubbleData.collapsed)
        {
            if (bubbleData.nextCollapsableCellData)
            {
                cellIdentifier = bubbleData.isPaginationFirstBubble ? RoomTimelineCellIdentifierMembershipCollapsedWithPaginationTitle : RoomTimelineCellIdentifierMembershipCollapsed;
            }
            else
            {
                // Use a normal membership cell for a single membership event
                cellIdentifier = bubbleData.isPaginationFirstBubble ? RoomTimelineCellIdentifierMembershipWithPaginationTitle : RoomTimelineCellIdentifierMembership;
            }
        }
        else if (bubbleData.collapsedAttributedTextMessage)
        {
            // The cell (and its series) is not collapsed but this cell is the first
            // of the series. So, use the cell with the "collapse" button.
            cellIdentifier = bubbleData.isPaginationFirstBubble ? RoomTimelineCellIdentifierMembershipExpandedWithPaginationTitle : RoomTimelineCellIdentifierMembershipExpanded;
        }
        else
        {
            cellIdentifier = bubbleData.isPaginationFirstBubble ? RoomTimelineCellIdentifierMembershipWithPaginationTitle : RoomTimelineCellIdentifierMembership;
        }
    }
    else if (bubbleData.tag == RoomBubbleCellDataTagRoomCreateConfiguration)
    {
        cellIdentifier = bubbleData.isPaginationFirstBubble ? RoomTimelineCellIdentifierRoomCreationCollapsedWithPaginationTitle : RoomTimelineCellIdentifierRoomCreationCollapsed;
    }
    else if (bubbleData.tag == RoomBubbleCellDataTagCall)
    {
        cellIdentifier = RoomTimelineCellIdentifierDirectCallStatus;
    }
    else if (bubbleData.tag == RoomBubbleCellDataTagGroupCall)
    {
        cellIdentifier = RoomTimelineCellIdentifierGroupCallStatus;
    }
    else if (bubbleData.attachment.type == MXKAttachmentTypeVoiceMessage || bubbleData.attachment.type == MXKAttachmentTypeAudio)
    {
        if (bubbleData.isIncoming)
        {
            if (bubbleData.isPaginationFirstBubble)
            {
                cellIdentifier = RoomTimelineCellIdentifierIncomingVoiceMessageWithPaginationTitle;
            }
            else if (bubbleData.shouldHideSenderInformation)
            {
                cellIdentifier = RoomTimelineCellIdentifierIncomingVoiceMessageWithoutSenderInfo;
            }
            else
            {
                cellIdentifier = RoomTimelineCellIdentifierIncomingVoiceMessage;
            }
        }
        else
        {
            if (bubbleData.isPaginationFirstBubble)
            {
                cellIdentifier = RoomTimelineCellIdentifierOutgoingVoiceMessageWithPaginationTitle;
            }
            else if (bubbleData.shouldHideSenderInformation)
            {
                cellIdentifier = RoomTimelineCellIdentifierOutgoingVoiceMessageWithoutSenderInfo;
            }
            else
            {
                cellIdentifier = RoomTimelineCellIdentifierOutgoingVoiceMessage;
            }
        }
    }
    else if (bubbleData.tag == RoomBubbleCellDataTagPoll)
    {
        if (bubbleData.isIncoming)
        {
            if (bubbleData.isPaginationFirstBubble)
            {
                cellIdentifier = RoomTimelineCellIdentifierIncomingPollWithPaginationTitle;
            }
            else if (bubbleData.shouldHideSenderInformation)
            {
                cellIdentifier = RoomTimelineCellIdentifierIncomingPollWithoutSenderInfo;
            }
            else
            {
                cellIdentifier = RoomTimelineCellIdentifierIncomingPoll;
            }
        }
        else
        {
            if (bubbleData.isPaginationFirstBubble)
            {
                cellIdentifier = RoomTimelineCellIdentifierOutgoingPollWithPaginationTitle;
            }
            else if (bubbleData.shouldHideSenderInformation)
            {
                cellIdentifier = RoomTimelineCellIdentifierOutgoingPollWithoutSenderInfo;
            }
            else
            {
                cellIdentifier = RoomTimelineCellIdentifierOutgoingPoll;
            }
        }
    }
    else if (bubbleData.tag == RoomBubbleCellDataTagLocation || bubbleData.tag == RoomBubbleCellDataTagLiveLocation)
    {
        if (bubbleData.isIncoming)
        {
            if (bubbleData.isPaginationFirstBubble)
            {
                cellIdentifier = RoomTimelineCellIdentifierIncomingLocationWithPaginationTitle;
            }
            else if (bubbleData.shouldHideSenderInformation)
            {
                cellIdentifier = RoomTimelineCellIdentifierIncomingLocationWithoutSenderInfo;
            }
            else
            {
                cellIdentifier = RoomTimelineCellIdentifierIncomingLocation;
            }
        }
        else
        {
            if (bubbleData.isPaginationFirstBubble)
            {
                cellIdentifier = RoomTimelineCellIdentifierOutgoingLocationWithPaginationTitle;
            }
            else if (bubbleData.shouldHideSenderInformation)
            {
                cellIdentifier = RoomTimelineCellIdentifierOutgoingLocationWithoutSenderInfo;
            }
            else
            {
                cellIdentifier = RoomTimelineCellIdentifierOutgoingLocation;
            }
        }
    }
    else if (bubbleData.tag == RoomBubbleCellDataTagVoiceBroadcastPlayback)
    {
        if (bubbleData.isIncoming)
        {
            if (bubbleData.isPaginationFirstBubble)
            {
                cellIdentifier = RoomTimelineCellIdentifierIncomingVoiceBroadcastPlaybackWithPaginationTitle;
            }
            else if (bubbleData.shouldHideSenderInformation)
            {
                cellIdentifier = RoomTimelineCellIdentifierIncomingVoiceBroadcastPlaybackWithoutSenderInfo;
            }
            else
            {
                cellIdentifier = RoomTimelineCellIdentifierIncomingVoiceBroadcastPlayback;
            }
        }
        else
        {
            if (bubbleData.isPaginationFirstBubble)
            {
                cellIdentifier = RoomTimelineCellIdentifierOutgoingVoiceBroadcastPlaybackWithPaginationTitle;
            }
            else if (bubbleData.shouldHideSenderInformation)
            {
                cellIdentifier = RoomTimelineCellIdentifierOutgoingVoiceBroadcastPlaybackWithoutSenderInfo;
            }
            else
            {
                cellIdentifier = RoomTimelineCellIdentifierOutgoingVoiceBroadcastPlayback;
            }
        }
    }
    else if (bubbleData.tag == RoomBubbleCellDataTagVoiceBroadcastRecord)
    {
        if (bubbleData.isPaginationFirstBubble)
        {
            cellIdentifier = RoomTimelineCellIdentifierOutgoingVoiceBroadcastRecorderWithPaginationTitle;
        }
        else if (bubbleData.shouldHideSenderInformation)
        {
            cellIdentifier = RoomTimelineCellIdentifierOutgoingVoiceBroadcastRecorderWithoutSenderInfo;
        }
        else
        {
            cellIdentifier = RoomTimelineCellIdentifierOutgoingVoiceBroadcastRecorder;
        }
    }
    
    else if (roomBubbleCellData.getFirstBubbleComponentWithDisplay.event.isEmote)
    {
        if (bubbleData.isIncoming)
        {
            if (bubbleData.isPaginationFirstBubble)
            {
                if (bubbleData.shouldHideSenderName)
                {
                    cellIdentifier = showEncryptionBadge ? RoomTimelineCellIdentifierIncomingEmoteEncryptedWithPaginationTitleWithoutSenderName : RoomTimelineCellIdentifierIncomingEmoteWithPaginationTitleWithoutSenderName;
                }
                else
                {
                    cellIdentifier = showEncryptionBadge ? RoomTimelineCellIdentifierIncomingEmoteEncryptedWithPaginationTitle : RoomTimelineCellIdentifierIncomingEmoteWithPaginationTitle;
                }
            }
            else if (bubbleData.shouldHideSenderInformation)
            {
                cellIdentifier = showEncryptionBadge ? RoomTimelineCellIdentifierIncomingEmoteEncryptedWithoutSenderInfo : RoomTimelineCellIdentifierIncomingEmoteWithoutSenderInfo;
            }
            else if (bubbleData.shouldHideSenderName)
            {
                cellIdentifier = showEncryptionBadge ? RoomTimelineCellIdentifierIncomingEmoteEncryptedWithoutSenderName : RoomTimelineCellIdentifierIncomingEmoteWithoutSenderName;
            }
            else
            {
                cellIdentifier = showEncryptionBadge ? RoomTimelineCellIdentifierIncomingEmoteEncrypted : RoomTimelineCellIdentifierIncomingEmote;
            }
        }
        else
        {
            if (bubbleData.isPaginationFirstBubble)
            {
                if (bubbleData.shouldHideSenderName)
                {
                    cellIdentifier = showEncryptionBadge ? RoomTimelineCellIdentifierOutgoingEmoteEncryptedWithPaginationTitleWithoutSenderName : RoomTimelineCellIdentifierOutgoingEmoteWithPaginationTitleWithoutSenderName;
                }
                else
                {
                    cellIdentifier = showEncryptionBadge ? RoomTimelineCellIdentifierOutgoingEmoteEncryptedWithPaginationTitle : RoomTimelineCellIdentifierOutgoingEmoteWithPaginationTitle;
                }
            }
            else if (bubbleData.shouldHideSenderInformation)
            {
                cellIdentifier = showEncryptionBadge ? RoomTimelineCellIdentifierOutgoingEmoteEncryptedWithoutSenderInfo : RoomTimelineCellIdentifierOutgoingEmoteWithoutSenderInfo;
            }
            else if (bubbleData.shouldHideSenderName)
            {
                cellIdentifier = showEncryptionBadge ? RoomTimelineCellIdentifierOutgoingEmoteEncryptedWithoutSenderName : RoomTimelineCellIdentifierOutgoingEmoteWithoutSenderName;
            }
            else
            {
                cellIdentifier = showEncryptionBadge ? RoomTimelineCellIdentifierOutgoingEmoteEncrypted : RoomTimelineCellIdentifierOutgoingEmote;
            }
        }
    }
    else if (bubbleData.isIncoming)
    {
        if (bubbleData.isAttachmentWithThumbnail)
        {
            // Check whether the provided celldata corresponds to a selected sticker
            if (customizedRoomDataSource.selectedEventId && (bubbleData.attachment.type == MXKAttachmentTypeSticker) && [bubbleData.attachment.eventId isEqualToString:customizedRoomDataSource.selectedEventId])
            {
                cellIdentifier = RoomTimelineCellIdentifierSelectedSticker;
            }
            else if (bubbleData.isPaginationFirstBubble)
            {
                cellIdentifier = showEncryptionBadge ? RoomTimelineCellIdentifierIncomingAttachmentEncryptedWithPaginationTitle : RoomTimelineCellIdentifierIncomingAttachmentWithPaginationTitle;
            }
            else if (bubbleData.shouldHideSenderInformation)
            {
                cellIdentifier = showEncryptionBadge ? RoomTimelineCellIdentifierIncomingAttachmentEncryptedWithoutSenderInfo : RoomTimelineCellIdentifierIncomingAttachmentWithoutSenderInfo;
            }
            else
            {
                cellIdentifier = showEncryptionBadge ? RoomTimelineCellIdentifierIncomingAttachmentEncrypted : RoomTimelineCellIdentifierIncomingAttachment;
            }
        }
        else if (bubbleData.isAttachment)
        {
            if (bubbleData.isPaginationFirstBubble)
            {
                cellIdentifier = showEncryptionBadge ? RoomTimelineCellIdentifierIncomingAttachmentWithoutThumbnailEncryptedWithPaginationTitle : RoomTimelineCellIdentifierIncomingAttachmentWithoutThumbnailWithPaginationTitle;
            }
            else if (bubbleData.shouldHideSenderInformation)
            {
                cellIdentifier = showEncryptionBadge ? RoomTimelineCellIdentifierIncomingAttachmentWithoutThumbnailEncryptedWithoutSenderInfo : RoomTimelineCellIdentifierIncomingAttachmentWithoutThumbnailWithoutSenderInfo;
            }
            else
            {
                cellIdentifier = showEncryptionBadge ? RoomTimelineCellIdentifierIncomingAttachmentWithoutThumbnailEncrypted : RoomTimelineCellIdentifierIncomingAttachmentWithoutThumbnail;
            }
        }
        else
        {
            if (bubbleData.isPaginationFirstBubble)
            {
                if (bubbleData.shouldHideSenderName)
                {
                    cellIdentifier = showEncryptionBadge ? RoomTimelineCellIdentifierIncomingTextMessageEncryptedWithPaginationTitleWithoutSenderName : RoomTimelineCellIdentifierIncomingTextMessageWithPaginationTitleWithoutSenderName;
                }
                else
                {
                    cellIdentifier = showEncryptionBadge ? RoomTimelineCellIdentifierIncomingTextMessageEncryptedWithPaginationTitle : RoomTimelineCellIdentifierIncomingTextMessageWithPaginationTitle;
                }
            }
            else if (bubbleData.shouldHideSenderInformation)
            {
                cellIdentifier = showEncryptionBadge ? RoomTimelineCellIdentifierIncomingTextMessageEncryptedWithoutSenderInfo : RoomTimelineCellIdentifierIncomingTextMessageWithoutSenderInfo;
            }
            else if (bubbleData.shouldHideSenderName)
            {
                cellIdentifier = showEncryptionBadge ? RoomTimelineCellIdentifierIncomingTextMessageEncryptedWithoutSenderName : RoomTimelineCellIdentifierIncomingTextMessageWithoutSenderName;
            }
            else
            {
                cellIdentifier = showEncryptionBadge ? RoomTimelineCellIdentifierIncomingTextMessageEncrypted : RoomTimelineCellIdentifierIncomingTextMessage;
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
                cellIdentifier = RoomTimelineCellIdentifierSelectedSticker;
            }
            else if (bubbleData.isPaginationFirstBubble)
            {
                cellIdentifier = showEncryptionBadge ? RoomTimelineCellIdentifierOutgoingAttachmentEncryptedWithPaginationTitle : RoomTimelineCellIdentifierOutgoingAttachmentWithPaginationTitle;
            }
            else if (bubbleData.shouldHideSenderInformation)
            {
                cellIdentifier = showEncryptionBadge ? RoomTimelineCellIdentifierOutgoingAttachmentEncryptedWithoutSenderInfo : RoomTimelineCellIdentifierOutgoingAttachmentWithoutSenderInfo;
            }
            else
            {
                cellIdentifier = showEncryptionBadge ? RoomTimelineCellIdentifierOutgoingAttachmentEncrypted : RoomTimelineCellIdentifierOutgoingAttachment;
            }
        }
        else if (bubbleData.isAttachment)
        {
            if (bubbleData.isPaginationFirstBubble)
            {
                cellIdentifier = showEncryptionBadge ? RoomTimelineCellIdentifierOutgoingAttachmentWithoutThumbnailEncryptedWithPaginationTitle : RoomTimelineCellIdentifierOutgoingAttachmentWithoutThumbnailWithPaginationTitle;
            }
            else if (bubbleData.shouldHideSenderInformation)
            {
                cellIdentifier = showEncryptionBadge ? RoomTimelineCellIdentifierOutgoingAttachmentWithoutThumbnailEncryptedWithoutSenderInfo : RoomTimelineCellIdentifierOutgoingAttachmentWithoutThumbnailWithoutSenderInfo;
            }
            else
            {
                cellIdentifier = showEncryptionBadge ? RoomTimelineCellIdentifierOutgoingAttachmentWithoutThumbnailEncrypted : RoomTimelineCellIdentifierOutgoingAttachmentWithoutThumbnail;
            }
        }
        else
        {
            if (bubbleData.isPaginationFirstBubble)
            {
                if (bubbleData.shouldHideSenderName)
                {
                    cellIdentifier = showEncryptionBadge ? RoomTimelineCellIdentifierOutgoingTextMessageEncryptedWithPaginationTitleWithoutSenderName : RoomTimelineCellIdentifierOutgoingTextMessageWithPaginationTitleWithoutSenderName;
                }
                else
                {
                    cellIdentifier = showEncryptionBadge ? RoomTimelineCellIdentifierOutgoingTextMessageEncryptedWithPaginationTitle : RoomTimelineCellIdentifierOutgoingTextMessageWithPaginationTitle;
                }
            }
            else if (bubbleData.shouldHideSenderInformation)
            {
                cellIdentifier = showEncryptionBadge ? RoomTimelineCellIdentifierOutgoingTextMessageEncryptedWithoutSenderInfo : RoomTimelineCellIdentifierOutgoingTextMessageWithoutSenderInfo;
            }
            else if (bubbleData.shouldHideSenderName)
            {
                cellIdentifier = showEncryptionBadge ? RoomTimelineCellIdentifierOutgoingTextMessageEncryptedWithoutSenderName : RoomTimelineCellIdentifierOutgoingTextMessageWithoutSenderName;
            }
            else
            {
                cellIdentifier = showEncryptionBadge ? RoomTimelineCellIdentifierOutgoingTextMessageEncrypted : RoomTimelineCellIdentifierOutgoingTextMessage;
            }
        }
    }
    
    return cellIdentifier;
}

#pragma mark - MXKDataSource delegate

- (void)dataSource:(MXKDataSource *)dataSource didRecognizeAction:(NSString *)actionIdentifier inCell:(id<MXKCellRendering>)cell userInfo:(NSDictionary *)userInfo
{
    // Handle here user actions on bubbles for Vector app
    if (self.customizedRoomDataSource)
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
        else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellStopShareButtonPressed])
        {
            NSString *beaconInfoEventId;
            
            if ([bubbleData isKindOfClass:[RoomBubbleCellData class]])
            {
                RoomBubbleCellData *roomBubbleCellData = (RoomBubbleCellData*)bubbleData;
                beaconInfoEventId = roomBubbleCellData.beaconInfoSummary.id;
            }
            
            [self.delegate roomViewControllerDidStopLiveLocationSharing:self beaconInfoEventId:beaconInfoEventId];
        }
        else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellRetryShareButtonPressed])
        {
            MXEvent *selectedEvent = userInfo[kMXKRoomBubbleCellEventKey];
            if (selectedEvent)
            {
                // TODO: - Implement retry live location action
            }
        }
        else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellTapOnMessageTextView] || [actionIdentifier isEqualToString:kMXKRoomBubbleCellTapOnContentView])
        {
            // Retrieve the tapped event
            MXEvent *tappedEvent = userInfo[kMXKRoomBubbleCellEventKey];
            
            // Check whether a selection already exist or not
            if (self.customizedRoomDataSource.selectedEventId)
            {
                [self cancelEventSelection];
            }
            else if (bubbleData.tag == RoomBubbleCellDataTagLiveLocation)
            {
                [self.delegate roomViewController:self didRequestLiveLocationPresentationForBubbleData:bubbleData];
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
                        Analytics.shared.viewRoomTrigger = AnalyticsViewRoomTriggerTombstone;
                        [self showRoomWithId:predecessorRoomId];
                    }
                    else
                    {
                        // Show contextual menu on single tap if bubble is not collapsed
                        if (bubbleData.collapsed)
                        {
                            // Do nothing here as we display room creation modal only if the user taps on the room name
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
                        if (tappedEvent.location) {
                            [_delegate roomViewController:self didRequestLocationPresentationForEvent:tappedEvent bubbleData:bubbleData];
                        } else {
                            [self showContextualMenuForEvent:tappedEvent fromSingleTapGesture:YES cell:cell animated:YES];
                        }
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
                if (self.customizedRoomDataSource.selectedEventId)
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
            self.customizedRoomDataSource.selectedEventId = nil;
            
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
        else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellTapOnAddReaction])
        {
            NSString *tappedEventId = userInfo[kMXKRoomBubbleCellEventIdKey];
            if (tappedEventId)
            {
                [self showEmojiPickerForEventId:tappedEventId];
            }
        }
        else if ([actionIdentifier isEqualToString:RoomDirectCallStatusCell.callBackAction])
        {
            MXEvent *callInviteEvent = userInfo[kMXKRoomBubbleCellEventKey];
            MXCallInviteEventContent *eventContent = [MXCallInviteEventContent modelFromJSON:callInviteEvent.content];
            
            [self placeCallWithVideo2:eventContent.isVideoCall];
        }
        else if ([actionIdentifier isEqualToString:RoomDirectCallStatusCell.declineAction])
        {
            MXEvent *callInviteEvent = userInfo[kMXKRoomBubbleCellEventKey];
            MXCallInviteEventContent *eventContent = [MXCallInviteEventContent modelFromJSON:callInviteEvent.content];
            
            MXCall *call = [self.mainSession.callManager callWithCallId:eventContent.callId];
            [call hangup];
        }
        else if ([actionIdentifier isEqualToString:RoomDirectCallStatusCell.answerAction])
        {
            MXEvent *callInviteEvent = userInfo[kMXKRoomBubbleCellEventKey];
            MXCallInviteEventContent *eventContent = [MXCallInviteEventContent modelFromJSON:callInviteEvent.content];
            
            MXCall *call = [self.mainSession.callManager callWithCallId:eventContent.callId];
            [call answer];
        }
        else if ([actionIdentifier isEqualToString:RoomDirectCallStatusCell.endCallAction])
        {
            MXEvent *callInviteEvent = userInfo[kMXKRoomBubbleCellEventKey];
            MXCallInviteEventContent *eventContent = [MXCallInviteEventContent modelFromJSON:callInviteEvent.content];
            
            MXCall *call = [self.mainSession.callManager callWithCallId:eventContent.callId];
            [call hangup];
        }
        else if ([actionIdentifier isEqualToString:RoomGroupCallStatusCell.joinAction] ||
                 [actionIdentifier isEqualToString:RoomGroupCallStatusCell.answerAction])
        {
            MXWeakify(self);

            // Check app permissions first
            [MXKTools checkAccessForCall:YES
             manualChangeMessageForAudio:[VectorL10n microphoneAccessNotGrantedForCall:AppInfo.current.displayName]
             manualChangeMessageForVideo:[VectorL10n cameraAccessNotGrantedForCall:AppInfo.current.displayName]
               showPopUpInViewController:self completionHandler:^(BOOL granted) {
                
                MXStrongifyAndReturnIfNil(self);
                if (granted)
                {
                    // Present the Jitsi view controller
                    Widget *jitsiWidget = [self.customizedRoomDataSource jitsiWidget];
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
                                                 inMatrixSession:self.customizedRoomDataSource.mxSession];
            [[JitsiService shared] resetDeclineForWidgetWithId:widget.widgetId];
        }
        else if ([actionIdentifier isEqualToString:RoomGroupCallStatusCell.leaveAction])
        {
            [self endActiveJitsiCall];
            [self reloadBubblesTable:YES];
        }
        else if ([actionIdentifier isEqualToString:RoomGroupCallStatusCell.declineAction])
        {
            MXEvent *widgetEvent = userInfo[kMXKRoomBubbleCellEventKey];
            Widget *widget = [[Widget alloc] initWithWidgetEvent:widgetEvent
                                                 inMatrixSession:self.customizedRoomDataSource.mxSession];
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
        else if ([actionIdentifier isEqualToString:RoomCreationIntroCell.tapOnRoomName])
        {
            [self showRoomCreationModal];
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
    
    [self.eventMenuBuilder reset];
    
    MXWeakify(self);
    
    BOOL showThreadOption = [self showThreadOptionForEvent:selectedEvent];
    if (showThreadOption && [self canCopyEvent:selectedEvent andCell:cell])
    {
        MXKRoomBubbleTableViewCell *roomBubbleTableViewCell = (MXKRoomBubbleTableViewCell *)cell;
        MXKRoomBubbleCellData *cellData = roomBubbleTableViewCell.bubbleData;
        [self.eventMenuBuilder addItemWithType:EventMenuItemTypeCopy
                                        action:[UIAlertAction actionWithTitle:[VectorL10n roomEventActionCopy]
                                                                        style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction * action) {
            MXStrongifyAndReturnIfNil(self);
            
            [self cancelEventSelection];
            
            [self copyEvent:selectedEvent inCell:cell withCellData:cellData];
        }]];
    }
    
    // Add actions for a failed event
    if (selectedEvent.sentState == MXEventSentStateFailed)
    {
        [self.eventMenuBuilder addItemWithType:EventMenuItemTypeRetrySending
                                        action:[UIAlertAction actionWithTitle:[VectorL10n retry]
                                                                        style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction * action) {
            MXStrongifyAndReturnIfNil(self);
            
            [self cancelEventSelection];
            
            // Let the datasource resend. It will manage local echo, etc.
            [self.roomDataSource resendEventWithEventId:selectedEvent.eventId success:nil failure:nil];
        }]];
        
        [self.eventMenuBuilder addItemWithType:EventMenuItemTypeRemove
                                        action:[UIAlertAction actionWithTitle:[VectorL10n roomEventActionDelete]
                                                                        style:UIAlertActionStyleDestructive
                                                                      handler:^(UIAlertAction * action) {
            MXStrongifyAndReturnIfNil(self);
            
            [self cancelEventSelection];
            
            [self.roomDataSource removeEventWithEventId:selectedEvent.eventId];
        }]];
    }
    
    // View in room action
    if (self.roomDataSource.threadId && [selectedEvent.eventId isEqualToString:self.roomDataSource.threadId])
    {
        //  if in the thread and selected event is the root event
        //  add "View in room" action
        [self.eventMenuBuilder addItemWithType:EventMenuItemTypeViewInRoom
                                        action:[UIAlertAction actionWithTitle:[VectorL10n roomEventActionViewInRoom]
                                                                        style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction * action) {
            MXStrongifyAndReturnIfNil(self);
            [self.delegate roomViewController:self
                               showRoomWithId:self.roomDataSource.roomId
                                      eventId:selectedEvent.eventId];
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
            [self.eventMenuBuilder addItemWithType:EventMenuItemTypeCancelSending
                                            action:[UIAlertAction actionWithTitle:[VectorL10n roomEventActionCancelSend]
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

        if (!isJitsiCallEvent && selectedEvent.eventType != MXEventTypePollStart &&
            selectedEvent.eventType != MXEventTypeBeaconInfo)
        {
            [self.eventMenuBuilder addItemWithType:EventMenuItemTypeQuote
                                            action:[UIAlertAction actionWithTitle:[VectorL10n roomEventActionQuote]
                                                                            style:UIAlertActionStyleDefault
                                                                          handler:^(UIAlertAction * action) {
                MXStrongifyAndReturnIfNil(self);
                
                [self cancelEventSelection];

                // Quote the message a la Markdown into the input toolbar composer
                NSString *prefix = [self.inputToolbarView.textMessage length] ? [NSString stringWithFormat:@"%@\n", self.inputToolbarView.textMessage] : @"";
                self.inputToolbarView.textMessage = [NSString stringWithFormat:@"%@>%@\n\n", prefix, selectedComponent.textMessage];
                
                // And display the keyboard
                [self.inputToolbarView becomeFirstResponder];
            }]];
        }
        
        if (selectedEvent.sentState == MXEventSentStateSent &&
            selectedEvent.eventType != MXEventTypePollStart &&
            // Forwarding of live-location shares still to be implemented
            selectedEvent.eventType != MXEventTypeBeaconInfo)
        {
            [self.eventMenuBuilder addItemWithType:EventMenuItemTypeForward
                                            action:[UIAlertAction actionWithTitle:[VectorL10n roomEventActionForward]
                                                                            style:UIAlertActionStyleDefault
                                                                          handler:^(UIAlertAction * action) {
                MXStrongifyAndReturnIfNil(self);

                [self cancelEventSelection];

                [self presentEventForwardingDialogForSelectedEvent:selectedEvent];
            }]];
        }
        
        if (!isJitsiCallEvent && BuildSettings.messageDetailsAllowShare && selectedEvent.eventType != MXEventTypePollStart &&
            selectedEvent.eventType != MXEventTypeBeaconInfo)
        {
            [self.eventMenuBuilder addItemWithType:EventMenuItemTypeShare
                                            action:[UIAlertAction actionWithTitle:[VectorL10n roomEventActionShare]
                                                                            style:UIAlertActionStyleDefault
                                                                          handler:^(UIAlertAction * action) {
                MXStrongifyAndReturnIfNil(self);
                
                [self cancelEventSelection];
                
                UIActivityViewController *activityViewController = nil;
                if (selectedEvent.location) {
                    activityViewController = [self.delegate roomViewController:self locationShareActivityViewControllerForEvent:selectedEvent];
                }
                
                if (activityViewController == nil && selectedComponent.textMessage) {
                    NSArray *activityItems = @[selectedComponent.textMessage];
                    activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
                }
                
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
            [self.eventMenuBuilder addItemWithType:EventMenuItemTypeForward
                                            action:[UIAlertAction actionWithTitle:[VectorL10n roomEventActionForward]
                                                                            style:UIAlertActionStyleDefault
                                                                          handler:^(UIAlertAction * action) {
                MXStrongifyAndReturnIfNil(self);

                [self cancelEventSelection];
                
                [self presentEventForwardingDialogForSelectedEvent:selectedEvent];
            }]];
        }
        
        if (BuildSettings.messageDetailsAllowSave)
        {
            if (attachment.type == MXKAttachmentTypeImage || attachment.type == MXKAttachmentTypeVideo)
            {
                [self.eventMenuBuilder addItemWithType:EventMenuItemTypeSaveMedia
                                                action:[UIAlertAction actionWithTitle:[VectorL10n roomEventActionSave]
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
                [self.eventMenuBuilder addItemWithType:EventMenuItemTypeCancelSending
                                                action:[UIAlertAction actionWithTitle:[VectorL10n roomEventActionCancelSend]
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
                [self.eventMenuBuilder addItemWithType:EventMenuItemTypeShare
                                                action:[UIAlertAction actionWithTitle:[VectorL10n roomEventActionShare]
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
                [self.eventMenuBuilder addItemWithType:EventMenuItemTypeCancelDownloading
                                                action:[UIAlertAction actionWithTitle:[VectorL10n roomEventActionCancelDownload]
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
        
        if (BuildSettings.messageDetailsAllowPermalink)
        {
            [self.eventMenuBuilder addItemWithType:EventMenuItemTypePermalink
                                            action:[UIAlertAction actionWithTitle:[VectorL10n roomEventActionPermalink]
                                                                            style:UIAlertActionStyleDefault
                                                                          handler:^(UIAlertAction * action) {
                MXStrongifyAndReturnIfNil(self);
                
                [self cancelEventSelection];
                
                // Create a matrix.to permalink that is common to all matrix clients
                NSString *permalink = [MXTools permalinkToEvent:selectedEvent.eventId inRoom:selectedEvent.roomId];
                NSURL *url = [NSURL URLWithString:permalink];
                
                if (url)
                {
                    MXKPasteboardManager.shared.pasteboard.URL = url;
                    [self.view vc_toastWithMessage:VectorL10n.roomEventCopyLinkInfo
                                             image:AssetImages.linkIcon.image
                                          duration:2.0
                                          position:ToastPositionBottom
                                  additionalMargin:self.roomInputToolbarContainerHeightConstraint.constant];
                }
                else
                {
                    MXLogDebug(@"[RoomViewController] Contextual menu permalink action failed. Permalink is nil room id/event id: %@/%@", selectedEvent.roomId, selectedEvent.eventId);
                }
            }]];
        }
        
        if (BuildSettings.messageDetailsAllowViewSource)
        {
            [self.eventMenuBuilder addItemWithType:EventMenuItemTypeViewSource
                                            action:[UIAlertAction actionWithTitle:[VectorL10n roomEventActionViewSource]
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
                [self.eventMenuBuilder addItemWithType:EventMenuItemTypeViewDecryptedSource
                                                action:[UIAlertAction actionWithTitle:[VectorL10n roomEventActionViewDecryptedSource]
                                                                                style:UIAlertActionStyleDefault
                                                                              handler:^(UIAlertAction * action) {
                    MXStrongifyAndReturnIfNil(self);
                    
                    [self cancelEventSelection];
                    
                    // Display clear event details
                    [self showEventDetails:selectedEvent.clearEvent];
                }]];
            }
        }
        
        // Do not allow to redact the event that enabled encryption (m.room.encryption)
        // because it breaks everything
        if (selectedEvent.eventType != MXEventTypeRoomEncryption)
        {
            NSString *title;
            EventMenuItemType itemType;
            if (selectedEvent.eventType == MXEventTypePollStart)
            {
                title = [VectorL10n roomEventActionRemovePoll];
                itemType = EventMenuItemTypeRemovePoll;
            }
            else
            {
                title = [VectorL10n roomEventActionRedact];
                itemType = EventMenuItemTypeRemove;
            }
            
            [self.eventMenuBuilder addItemWithType:itemType
                                            action:[UIAlertAction actionWithTitle:title
                                                                            style:UIAlertActionStyleDestructive
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
        
        if (selectedEvent.eventType == MXEventTypePollStart && [selectedEvent.sender isEqualToString:self.mainSession.myUserId])
        {
            if ([self.delegate roomViewController:self canEndPollWithEventIdentifier:selectedEvent.eventId])
            {
                [self.eventMenuBuilder addItemWithType:EventMenuItemTypeEndPoll
                                                action:[UIAlertAction actionWithTitle:[VectorL10n roomEventActionEndPoll]
                                                                                style:UIAlertActionStyleDefault
                                                                              handler:^(UIAlertAction * action) {
                    MXStrongifyAndReturnIfNil(self);
                    
                    [self.delegate roomViewController:self endPollWithEventIdentifier:selectedEvent.eventId];
                    
                    [self hideContextualMenuAnimated:YES];
                }]];
            }
        }
        
        // Add reaction history if event contains reactions
        if (roomBubbleTableViewCell.bubbleData.reactions[selectedEvent.eventId].aggregatedReactionsWithNonZeroCount)
        {
            [self.eventMenuBuilder addItemWithType:EventMenuItemTypeReactionHistory
                                            action:[UIAlertAction actionWithTitle:[VectorL10n roomEventActionReactionHistory]
                                                                            style:UIAlertActionStyleDefault
                                                                          handler:^(UIAlertAction * action) {
                MXStrongifyAndReturnIfNil(self);
                
                [self cancelEventSelection];
                
                // Show reaction history
                [self showReactionHistoryForEventId:selectedEvent.eventId animated:YES];
            }]];
        }
        
        if (![selectedEvent.sender isEqualToString:self.mainSession.myUserId] && RiotSettings.shared.roomContextualMenuShowReportContentOption)
        {
            [self.eventMenuBuilder addItemWithType:EventMenuItemTypeReport
                                            action:[UIAlertAction actionWithTitle:[VectorL10n roomEventActionReport]
                                                                            style:UIAlertActionStyleDestructive
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
                [reportReasonAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n ok] style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
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
                        [ignoreUserAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n yes] style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                            
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
                        
                        [ignoreUserAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n no] style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
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
                
                [reportReasonAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel] style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
                    MXStrongifyAndReturnIfNil(self);
                    self->currentAlert = nil;
                }]];
                
                [self presentViewController:reportReasonAlert animated:YES completion:nil];
                self->currentAlert = reportReasonAlert;
            }]];
        }
        
        if (!isJitsiCallEvent && self.roomDataSource.room.summary.isEncrypted)
        {
            [self.eventMenuBuilder addItemWithType:EventMenuItemTypeViewEncryption
                                            action:[UIAlertAction actionWithTitle:[VectorL10n roomEventActionViewEncryption]
                                                                            style:UIAlertActionStyleDefault
                                                                          handler:^(UIAlertAction * action) {
                MXStrongifyAndReturnIfNil(self);
                
                [self cancelEventSelection];
                
                // Display encryption details
                [self showEncryptionInformation:selectedEvent];
            }]];
        }
    }

    [self.eventMenuBuilder addItemWithType:EventMenuItemTypeCancel
                                    action:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                                    style:UIAlertActionStyleCancel
                                                                  handler:^(UIAlertAction * action) {
        MXStrongifyAndReturnIfNil(self);

        [self hideContextualMenuAnimated:YES];
    }]];
    
    // Do not display empty action sheet
    if (!self.eventMenuBuilder.isEmpty)
    {
        UIAlertController *actionsMenu = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        //  build actions and add them to the alert
        NSArray<UIAlertAction*> *actions = [self.eventMenuBuilder build];
        for (UIAlertAction *action in actions)
        {
            [actionsMenu addAction:action];
        }
        
        NSInteger bubbleComponentIndex = [roomBubbleTableViewCell.bubbleData bubbleComponentIndexForEventId:selectedEvent.eventId];
        
        CGRect sourceRect = [roomBubbleTableViewCell componentFrameInContentViewForIndex:bubbleComponentIndex];
        
        [actionsMenu mxk_setAccessibilityIdentifier:@"RoomVCEventMenuAlert"];
        [actionsMenu popoverPresentationController].sourceView = roomBubbleTableViewCell;
        [actionsMenu popoverPresentationController].sourceRect = sourceRect;
        [self dismissKeyboard];
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
            
            // Create a permalink to open or preview the room.
            NSString *permalink = [MXTools permalinkToRoom:roomIdOrAlias];
            NSURL *permalinkURL = [NSURL URLWithString:permalink];
            
            [self handleUniversalLinkURL:permalinkURL];
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
                        case RoomMessageURLTypeHttp:
                            shouldDoAction = YES;
                            break;
                        default:
                        {
                            MXEvent *tappedEvent = userInfo[kMXKRoomBubbleCellEventKey];
                            URLValidationResult *result = [URLValidator validateTappedURL:url in:tappedEvent];
                            if (result.shouldShowConfirmationAlert)
                            {
                                [self showDifferentURLsAlertFor:url
                                                  visibleURLString:result.visibleURLString];
                                return NO;
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
                    if (roomMessageURLType == RoomMessageURLTypeHttp) {
                        shouldDoAction = YES;
                    } else {
                        // Retrieve the tapped event
                        MXEvent *tappedEvent = userInfo[kMXKRoomBubbleCellEventKey];
                        
                        if (tappedEvent)
                        {
                            // Long press on link, present room contextual menu.
                            [self showContextualMenuForEvent:tappedEvent fromSingleTapGesture:NO cell:cell animated:YES];
                        }
                        
                        shouldDoAction = NO;
                    }
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
    
    self.customizedRoomDataSource.showBubbleDateTimeOnSelection = showTimestamp;
    self.customizedRoomDataSource.selectedEventId = eventId;
    
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
    
    self.customizedRoomDataSource.showBubbleDateTimeOnSelection = YES;
    self.customizedRoomDataSource.selectedEventId = nil;
    self.customizedRoomDataSource.highlightedEventId = nil;
    
    [self restoreTextMessageBeforeEditing];
    
    // Force table refresh
    [self dataSource:self.roomDataSource didCellChange:nil];
}

- (void)showUnableToOpenLinkErrorAlert
{
    [self showAlertWithTitle:[VectorL10n error]
                     message:[VectorL10n roomMessageUnableOpenLinkErrorMessage]];
}

- (void)editEventContentWithId:(NSString*)eventId
{
    MXEvent *event = [self.roomDataSource eventWithEventId:eventId];
    
    if ([self inputToolbarConformsToHtmlToolbarViewProtocol])
    {
        MXKRoomInputToolbarView <HtmlRoomInputToolbarViewProtocol> *htmlInputToolBarView = (MXKRoomInputToolbarView <HtmlRoomInputToolbarViewProtocol> *) self.inputToolbarView;
        self.htmlTextBeforeEditing = htmlInputToolBarView.htmlContent;
        htmlInputToolBarView.htmlContent = [self.customizedRoomDataSource editableHtmlTextMessageFor:event];
    }
    else if ([self inputToolbarConformsToToolbarViewProtocol])
    {
        self.textMessageBeforeEditing = self.inputToolbarView.attributedTextMessage;
        self.inputToolbarView.attributedTextMessage = [self.customizedRoomDataSource editableAttributedTextMessageFor:event];
    }
    
    [self selectEventWithId:eventId inputToolBarSendMode:RoomInputToolbarViewSendModeEdit showTimestamp:YES];
}

- (void)restoreTextMessageBeforeEditing
{
    
   
    if (self.htmlTextBeforeEditing && [self inputToolbarConformsToHtmlToolbarViewProtocol])
    {
        MXKRoomInputToolbarView <HtmlRoomInputToolbarViewProtocol> *htmlInputToolBarView = (MXKRoomInputToolbarView <HtmlRoomInputToolbarViewProtocol> *) self.inputToolbarView;
        htmlInputToolBarView.htmlContent = self.htmlTextBeforeEditing;
    }
    else if (self.textMessageBeforeEditing && [self inputToolbarConformsToToolbarViewProtocol])
    {
        self.inputToolbarView.attributedTextMessage = self.textMessageBeforeEditing;
    }
    
    self.textMessageBeforeEditing = nil;
    self.htmlTextBeforeEditing = nil;
}

- (BOOL)inputToolbarConformsToHtmlToolbarViewProtocol
{
    return [self.inputToolbarView conformsToProtocol:@protocol(HtmlRoomInputToolbarViewProtocol)];
}

- (BOOL)inputToolbarConformsToToolbarViewProtocol
{
    return [self.inputToolbarView conformsToProtocol:@protocol(RoomInputToolbarViewProtocol)];
}

- (void)showDifferentURLsAlertFor:(NSURL *)url visibleURLString:(NSString *)visibleURLString
{
    //  urls are different, show confirmation alert
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[VectorL10n externalLinkConfirmationTitle] message:[VectorL10n externalLinkConfirmationMessage:visibleURLString :url.absoluteString] preferredStyle:UIAlertControllerStyleAlert];

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
}

#pragma mark - RoomDataSourceDelegate

- (void)roomDataSourceDidUpdateEncryptionTrustLevel:(RoomDataSource *)roomDataSource
{
    [self updateInputToolbarEncryptionDecoration];
    [self updateTitleViewEncryptionDecoration];
}

- (void)roomDataSource:(RoomDataSource *)roomDataSource didTapThread:(id<MXThreadProtocol>)thread
{
    [self openThreadWithId:thread.id];

    [Analytics.shared trackInteraction:AnalyticsUIElementRoomThreadSummaryItem];
}

- (void)roomDataSourceDidUpdateCurrentUserSharingLocationStatus:(RoomDataSource *)roomDataSource
{
    [self updateLiveLocationBannerViewVisibility];
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
}

#pragma mark - VoIP

- (void)placeCallWithVideo:(BOOL)video
{
    __weak __typeof(self) weakSelf = self;
    
    // Check app permissions first
    [MXKTools checkAccessForCall:video
     manualChangeMessageForAudio:[VectorL10n microphoneAccessNotGrantedForCall:AppInfo.current.displayName]
     manualChangeMessageForVideo:[VectorL10n cameraAccessNotGrantedForCall:AppInfo.current.displayName]
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
    
    [callActionSheet addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
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
    Widget *jitsiWidget = [self.customizedRoomDataSource jitsiWidget];
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
                
                [unprivilegedAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n ok]
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

    // TODO: Improve so we don't save partial message twice.
    RoomInputToolbarView *inputToolbar = (RoomInputToolbarView *)toolbarView;

    if (self.saveProgressTextInput && self.roomDataSource && inputToolbar)
    {
        // Store the potential message partially typed in text input
        self.roomDataSource.partialAttributedTextMessage = inputToolbar.attributedTextMessage;
    }

    // Cancel potential selected event (to leave edition mode)
    NSString *selectedEventId = self.customizedRoomDataSource.selectedEventId;
    if (typing && selectedEventId && ![self.roomDataSource canReplyToEventWithId:selectedEventId])
    {
        [self cancelEventSelection];
    }
}

- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView heightDidChanged:(CGFloat)height completion:(void (^)(BOOL finished))completion
{
    if (self.roomInputToolbarContainerHeightConstraint.constant != height)
    {
        [super roomInputToolbarView:toolbarView heightDidChanged:height completion:^(BOOL finished) {
            
            if (completion)
            {
                completion (finished);
            }
        }];
    }
}

- (void)roomInputToolbarViewDidTapCancel:(MXKRoomInputToolbarView<RoomInputToolbarViewProtocol>*)toolbarView
{
    [self cancelEventSelection];
}
 
- (void)roomInputToolbarViewDidChangeTextMessage:(RoomInputToolbarView *)toolbarView
{
    [self.userSuggestionCoordinator processTextMessage:toolbarView.textMessage];
}

- (void)roomInputToolbarViewDidOpenActionMenu:(RoomInputToolbarView*)toolbarView
{
    // Consider opening the action menu as beginning to type and share encryption keys if requested.
    if ([MXKAppSettings standardAppSettings].outboundGroupSessionKeyPreSharingStrategy == MXKKeyPreSharingWhenTyping)
    {
        [self shareEncryptionKeys];
    }
}

- (void)roomInputToolbarView:(RoomInputToolbarView *)toolbarView sendFormattedTextMessage:(NSString *)formattedTextMessage withRawText:(NSString *)rawText
{
    // Create before sending the message in case of a discussion (direct chat)
    MXWeakify(self);
    [self createDiscussionIfNeeded:^(BOOL readyToSend) {
        MXStrongifyAndReturnIfNil(self);
        
        if (readyToSend) {
            [self sendFormattedTextMessage:rawText htmlMsg:formattedTextMessage];
        }
        // Errors are handled at the request level. This should be improved in case of code rewriting.
    }];
}

- (void)roomInputToolbarViewShowSendMediaActions:(MXKRoomInputToolbarView *)toolbarView
{
    NSMutableArray *actionItems = [NSMutableArray new];
    if (RiotSettings.shared.roomScreenAllowMediaLibraryAction)
    {
        [actionItems addObject:@(ComposerCreateActionPhotoLibrary)];
    }
    if (RiotSettings.shared.roomScreenAllowStickerAction && !self.isNewDirectChat)
    {
        [actionItems addObject:@(ComposerCreateActionStickers)];
    }
    if (RiotSettings.shared.roomScreenAllowFilesAction)
    {
        [actionItems addObject:@(ComposerCreateActionAttachments)];
    }
    if (RiotSettings.shared.enableVoiceBroadcast && !self.isNewDirectChat)
    {
        [actionItems addObject:@(ComposerCreateActionVoiceBroadcast)];
    }
    if (BuildSettings.pollsEnabled && self.displayConfiguration.sendingPollsEnabled && !self.isNewDirectChat)
    {
        [actionItems addObject:@(ComposerCreateActionPolls)];
    }
    if (BuildSettings.locationSharingEnabled && !self.isNewDirectChat)
    {
        [actionItems addObject:@(ComposerCreateActionLocation)];
    }
    if (RiotSettings.shared.roomScreenAllowCameraAction)
    {
        [actionItems addObject:@(ComposerCreateActionCamera)];
    }
    
    self.composerCreateActionListBridgePresenter = [[ComposerCreateActionListBridgePresenter alloc] initWithActions:actionItems
                                                                                                     wysiwygEnabled:RiotSettings.shared.enableWysiwygComposer
                                                                                              textFormattingEnabled:RiotSettings.shared.enableWysiwygTextFormatting];
    self.composerCreateActionListBridgePresenter.delegate = self;
    [self.composerCreateActionListBridgePresenter presentFrom:self animated:YES];
}

- (void)roomInputToolbarView:(RoomInputToolbarView *)toolbarView sendAttributedTextMessage:(NSAttributedString *)attributedTextMessage
{
    // Create before sending the message in case of a discussion (direct chat)
    MXWeakify(self);
    [self createDiscussionIfNeeded:^(BOOL readyToSend) {
        MXStrongifyAndReturnIfNil(self);
        
        if (readyToSend) {
            BOOL isMessageAHandledCommand = NO;
            // "/me" command is supported with Pills in RoomDataSource.
            if (![attributedTextMessage.string hasPrefix:kMXKSlashCmdEmote])
            {
                // Other commands currently work with identifiers (e.g. ban, invite, op, etc).
                NSString *message;
                if (@available(iOS 15.0, *))
                {
                    message = [PillsFormatter stringByReplacingPillsIn:attributedTextMessage mode:PillsReplacementTextModeIdentifier];
                }
                else
                {
                    message = attributedTextMessage.string;
                }
                // Try to send the slash command
                isMessageAHandledCommand = [self sendAsIRCStyleCommandIfPossible:message];
            }
            
            if (!isMessageAHandledCommand)
            {
                [self sendAttributedTextMessage:attributedTextMessage];
            }
        }
        // Errors are handled at the request level. This should be improved in case of code rewriting.
    }];
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

- (IBAction)onThreadListTapped:(id)sender
{
    self.threadsBridgePresenter = [self.delegate threadsCoordinatorForRoomViewController:self threadId:nil];
    self.threadsBridgePresenter.delegate = self;
    [self.threadsBridgePresenter pushFrom:self.navigationController animated:YES];

    [Analytics.shared trackInteraction:AnalyticsUIElementRoomThreadListButton];
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
        [RoomDataSource loadRoomDataSourceWithRoomId:self.roomDataSource.roomId
                                      initialEventId:self.roomDataSource.room.accountData.readMarkerEventId
                                            threadId:self.roomDataSource.threadId
                                    andMatrixSession:self.mainSession
                                          onComplete:^(id roomDataSource) {
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
    
    if ([cell isKindOfClass:MXKRoomBubbleTableViewCell.class] && ![cell isKindOfClass:MXKRoomEmptyBubbleTableViewCell.class])
    {
        MXKRoomBubbleTableViewCell *roomBubbleTableViewCell = (MXKRoomBubbleTableViewCell*)cell;
        if (roomBubbleTableViewCell.readMarkerView)
        {
            readMarkerTableViewCell = roomBubbleTableViewCell;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self checkReadMarkerVisibility];
            });
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
    if (!self.roomDataSource.isLive && ![self isRoomPreview] && !self.isNewDirectChat)
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
    
    [self cancelEventHighlight];
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
                        [RoomDataSource loadRoomDataSourceWithRoomId:self.roomDataSource.roomId
                                                      initialEventId:eventId
                                                            threadId:self.roomDataSource.threadId
                                                    andMatrixSession:self.mainSession
                                                          onComplete:^(id roomDataSource) {
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
                        [self setRoomInputToolbarViewClass:[RoomViewController mainToolbarClass]];
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
        [self presentDeclineOptionsFromView:tappedView];
    }
}

- (void)presentDeclineOptionsFromView:(UIView *)view
{
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:[VectorL10n roomPreviewDeclineInvitationOptions]
                                                                         message:nil
                                                                  preferredStyle:UIAlertControllerStyleActionSheet];
    [actionSheet addAction:[UIAlertAction actionWithTitle:[VectorL10n decline]
                                                    style:UIAlertActionStyleDefault
                                                  handler:^(UIAlertAction * _Nonnull action) {
        [self declineRoomInvitation];
    }]];
    [actionSheet addAction:[UIAlertAction actionWithTitle:[VectorL10n ignoreUser]
                                                    style:UIAlertActionStyleDestructive
                                                  handler:^(UIAlertAction * _Nonnull action) {
        [self ignoreInviteSender];
    }]];
    [actionSheet addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                    style:UIAlertActionStyleCancel
                                                  handler:nil]];
    actionSheet.popoverPresentationController.sourceView = view;
    [self presentViewController:actionSheet animated:YES completion:nil];
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
        MXWeakify(self);
        [self.roomDataSource.room leave:^{
            MXStrongifyAndReturnIfNil(self);
            
            [self stopActivityIndicator];
            [self popToHomeViewController];
            
        } failure:^(NSError *error) {
            MXStrongifyAndReturnIfNil(self);
            
            [self stopActivityIndicator];
            MXLogDebug(@"[RoomVC] Failed to reject an invited room (%@) failed", self.roomDataSource.room.roomId);
            
        }];
    }
}

- (void)ignoreInviteSender
{
    [self startActivityIndicator];
    MXWeakify(self);
    [self.roomDataSource.room ignoreInviteSender:^{
        MXStrongifyAndReturnIfNil(self);
        
        [self stopActivityIndicator];
        [self popToHomeViewController];

    } failure:^(NSError *error) {
        MXStrongifyAndReturnIfNil(self);
        
        [self stopActivityIndicator];
        MXLogDebug(@"[RoomVC] Failed to ignore inviter in room (%@)", self.roomDataSource.room.roomId);
    }];
}

- (void)popToHomeViewController
{
    // We remove the current view controller.
    // Pop to homes view controller
    [[AppDelegate theDelegate] restoreInitialDisplay:^{}];
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
            [self.roomDataSource.room liveTimeline:^(id<MXEventTimeline> liveTimeline) {
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
        if ([call.room.roomId isEqualToString:self.customizedRoomDataSource.roomId])
        {
            [self refreshActivitiesViewDisplay];
            [self refreshRoomInputToolbar];
        }
    }];
    kMXCallManagerConferenceStartedObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXCallManagerConferenceStarted object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXStrongifyAndReturnIfNil(self);
        
        NSString *roomId = notif.object;
        if ([roomId isEqualToString:self.customizedRoomDataSource.roomId])
        {
            [self refreshActivitiesViewDisplay];
        }
    }];
    kMXCallManagerConferenceFinishedObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXCallManagerConferenceFinished object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXStrongifyAndReturnIfNil(self);
        
        NSString *roomId = notif.object;
        if ([roomId isEqualToString:self.customizedRoomDataSource.roomId])
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
    if (!self.displayConfiguration.jitsiWidgetRemoverEnabled)
    {
        return;
    }
    
    MXWeakify(self);
    
    kMXKWidgetManagerDidUpdateWidgetObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kWidgetManagerDidUpdateWidgetNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXStrongifyAndReturnIfNil(self);
        
        Widget *widget = notif.object;
        if (widget.mxSession == self.roomDataSource.mxSession
            && [widget.roomId isEqualToString:self.customizedRoomDataSource.roomId])
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
    if (!self.displayConfiguration.integrationsEnabled)
    {
        return 0;
    }
    
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
            // Doing nothing here as the offline notification is now handled by the AppCoordinator
        }
        else if (self.customizedRoomDataSource.roomState.isObsolete)
        {
            self.activitiesViewExpanded = YES;
            MXWeakify(self);
            [roomActivitiesView displayRoomReplacementWithRoomLinkTappedHandler:^{
                MXStrongifyAndReturnIfNil(self);
                
                MXEvent *stoneTombEvent = [self.customizedRoomDataSource.roomState stateEventsWithType:kMXEventTypeStringRoomTombStone].lastObject;
                
                NSString *replacementRoomId = self.customizedRoomDataSource.roomState.tombStoneContent.replacementRoomId;
                if ([self.roomDataSource.mxSession roomWithRoomId:replacementRoomId])
                {
                    // Open the room if it is already joined
                    [self showRoomWithId:replacementRoomId];
                }
                else
                {
                    // Else auto join it via the server that sent the event
                    MXLogDebug(@"[RoomVC] Auto join an upgraded room: %@ -> %@. Sender: %@",                              self.customizedRoomDataSource.roomState.roomId,
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
                    // Retrieve the unread messages count on the current thread
                    NSUInteger unreadCount = [self.mainSession.store
                                              localUnreadEventCount:self.roomDataSource.room.roomId
                                              threadId:self.roomDataSource.threadId ?: kMXEventTimelineMain
                                              withTypeIn:self.mainSession.unreadEventTypes];
                    
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

        [self cancelEventHighlight];
    }
    else
    {
        MXWeakify(self);

        void(^continueBlock)(MXKRoomDataSource *, BOOL) = ^(MXKRoomDataSource *roomDataSource, BOOL hasRoomDataSourceOwnership){
            MXStrongifyAndReturnIfNil(self);

            [roomDataSource finalizeInitialization];

            // Scroll to bottom the bubble history on the display refresh.
            self->shouldScrollToBottomOnTableRefresh = YES;

            [self displayRoom:roomDataSource];

            // Set the room view controller has the data source ownership here.
            self.hasRoomDataSourceOwnership = hasRoomDataSourceOwnership;

            [self refreshActivitiesViewDisplay];
            [self refreshJumpToLastUnreadBannerDisplay];

            if (self.saveProgressTextInput)
            {
                // Restore the potential message partially typed before jump to last unread messages.
                self.inputToolbarView.attributedTextMessage = roomDataSource.partialAttributedTextMessage;
            }
        };

        if (self.roomDataSource.threadId)
        {
            [ThreadDataSource loadRoomDataSourceWithRoomId:self.roomDataSource.roomId
                                            initialEventId:nil
                                                  threadId:self.roomDataSource.threadId
                                          andMatrixSession:self.mainSession
                                                onComplete:^(ThreadDataSource *threadDataSource)
             {
                continueBlock(threadDataSource, YES);
            }];
        }
        else if (self.roomDataSource.roomId)
        {
            if (self.isContextPreview)
            {
                [RoomPreviewDataSource loadRoomDataSourceWithRoomId:self.roomDataSource.roomId
                                                           threadId:nil
                                                   andMatrixSession:self.mainSession
                                                         onComplete:^(RoomPreviewDataSource *roomDataSource)
                 {
                    continueBlock(roomDataSource, YES);
                }];
            }
            else
            {
                // Switch back to the room live timeline managed by MXKRoomDataSourceManager
                MXKRoomDataSourceManager *roomDataSourceManager = [MXKRoomDataSourceManager sharedManagerForMatrixSession:self.mainSession];

                [roomDataSourceManager roomDataSourceForRoom:self.roomDataSource.roomId
                                                      create:YES
                                                  onComplete:^(MXKRoomDataSource *roomDataSource) {
                    continueBlock(roomDataSource, NO);
                }];
            }
        }
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
                
                if (![self.mainSession.crypto isKindOfClass:[MXLegacyCrypto class]])
                {
                    MXLogFailure(@"[RoomVC] eventDidChangeSentState: Only legacy crypto supports manual setting of known devices");
                    return;
                }
                [(MXLegacyCrypto *)self.mainSession.crypto setDevicesKnown:self->unknownDevices complete:^{
                    
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
    
    if ([self.customizedRoomDataSource.selectedEventId isEqualToString:previousId])
    {
        MXLogDebug(@"[RoomVC] eventDidChangeIdentifier: Update selectedEventId");
        self.customizedRoomDataSource.selectedEventId = event.eventId;
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
    [cancelAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel] style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
        MXStrongifyAndReturnIfNil(self);
        self->currentAlert = nil;
    }]];
    
    [cancelAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n delete] style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
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
    
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated"
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
    #pragma clang diagnostic pop
    
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
    
    if (!readMarkerTableViewCell || readMarkerTableViewCell.readMarkerView.isHidden == NO)
    {
        return;
    }
        
    RoomBubbleCellData *cellData = (RoomBubbleCellData*)readMarkerTableViewCell.bubbleData;
    
    id<RoomTimelineCellDecorator> cellDecorator = [RoomTimelineConfiguration shared].currentStyle.cellDecorator;
    
    [cellDecorator dissmissReadMarkerViewForCell:readMarkerTableViewCell
                                        cellData:cellData
                                        animated:YES
                                      completion:^{
       
        self->readMarkerTableViewCell = nil;
    }];
}

- (void)refreshRemoveJitsiWidgetView
{
    if (!self.displayConfiguration.jitsiWidgetRemoverEnabled)
    {
        return;
    }
    
    if (self.roomDataSource.isLive && !self.roomDataSource.isPeeking)
    {
        Widget *jitsiWidget = [self.customizedRoomDataSource jitsiWidget];
        
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
        if ([cell isKindOfClass:MXKRoomBubbleTableViewCell.class] && ![cell isKindOfClass:MXKRoomEmptyBubbleTableViewCell.class])
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
    
    [invitePrompt addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
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
    
    [alert addAction:[UIAlertAction actionWithTitle:[VectorL10n ok]
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
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[VectorL10n keyVerificationAlertTitle]
                                                                   message:[VectorL10n keyVerificationAlertBody]
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
    
    BOOL showMoreOption = (event.isState && RiotSettings.shared.roomContextualMenuShowMoreOptionForStates)
        || (!event.isState && RiotSettings.shared.roomContextualMenuShowMoreOptionForMessages);
    BOOL showThreadOption = [self showThreadOptionForEvent:event];
    
    NSMutableArray<RoomContextualMenuItem*> *items = [NSMutableArray arrayWithCapacity:5];
    
    [items addObject:[self replyMenuItemWithEvent:event]];
    if (showThreadOption)
    {
        //  add "Thread" option only if not already in a thread
        [items addObject:[self replyInThreadMenuItemWithEvent:event]];
    }
    [items addObject:[self editMenuItemWithEvent:event]];
    if (!showThreadOption)
    {
        [items addObject:[self copyMenuItemWithEvent:event andCell:cell]];
    }
    if (showMoreOption)
    {
        [items addObject:[self moreMenuItemWithEvent:event andCell:cell]];
    }
    
    return items;
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
            
            [deleteConfirmation addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel] style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            }]];
            
            [deleteConfirmation addAction:[UIAlertAction actionWithTitle:[VectorL10n delete] style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
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
    
    switch (event.eventType) {
        case MXEventTypePollStart: {
            editMenuItem.action = ^{
                MXStrongifyAndReturnIfNil(self);
                [self hideContextualMenuAnimated:YES cancelEventSelection:YES completion:nil];
                [self.delegate roomViewController:self didRequestEditForPollWithStartEvent:event];
            };
            
            editMenuItem.isEnabled = [self.delegate roomViewController:self canEditPollWithEventIdentifier:event.eventId];
            
            break;
        }
        default: {
            editMenuItem.action = ^{
                MXStrongifyAndReturnIfNil(self);
                [self hideContextualMenuAnimated:YES cancelEventSelection:NO completion:nil];
                [self editEventContentWithId:event.eventId];
                
                // And display the keyboard
                [self.inputToolbarView becomeFirstResponder];
            };
            
            editMenuItem.isEnabled = [self.roomDataSource canEditEventWithId:event.eventId];
            
            break;
        }
    }
    
    return editMenuItem;
}

- (RoomContextualMenuItem *)copyMenuItemWithEvent:(MXEvent*)event andCell:(id<MXKCellRendering>)cell
{
    MXWeakify(self);
    
    RoomContextualMenuItem *copyMenuItem = [[RoomContextualMenuItem alloc] initWithMenuAction:RoomContextualMenuActionCopy];
    copyMenuItem.isEnabled = [self canCopyEvent:event andCell:cell];
    MXKRoomBubbleTableViewCell *roomBubbleTableViewCell = (MXKRoomBubbleTableViewCell *)cell;
    MXKRoomBubbleCellData *cellData = roomBubbleTableViewCell.bubbleData;
    copyMenuItem.action = ^{
        MXStrongifyAndReturnIfNil(self);
        
        [self copyEvent:event inCell:cell withCellData:cellData];
    };
    
    return copyMenuItem;
}

- (BOOL)canCopyEvent:(MXEvent*)event andCell:(id<MXKCellRendering>)cell
{
    MXKRoomBubbleTableViewCell *roomBubbleTableViewCell = (MXKRoomBubbleTableViewCell *)cell;
    MXKAttachment *attachment = roomBubbleTableViewCell.bubbleData.attachment;
    
    BOOL result = !attachment || attachment.type != MXKAttachmentTypeSticker;
    
    if (attachment && !BuildSettings.messageDetailsAllowCopyMedia)
    {
        result = NO;
    }
    
    if (result)
    {
        switch (event.eventType) {
            case MXEventTypeRoomMessage:
            {
                NSString *messageType = event.content[kMXMessageTypeKey];
                
                if ([messageType isEqualToString:kMXMessageTypeKeyVerificationRequest])
                {
                    result = NO;
                }
                break;
            }
            case MXEventTypeKeyVerificationStart:
            case MXEventTypeKeyVerificationAccept:
            case MXEventTypeKeyVerificationKey:
            case MXEventTypeKeyVerificationMac:
            case MXEventTypeKeyVerificationDone:
            case MXEventTypeKeyVerificationCancel:
            case MXEventTypePollStart:
            case MXEventTypeBeaconInfo:
                result = NO;
                break;
            case MXEventTypeCustom:
                if ([event.type isEqualToString:kWidgetMatrixEventTypeString]
                    || [event.type isEqualToString:kWidgetModularEventTypeString])
                {
                    Widget *widget = [[Widget alloc] initWithWidgetEvent:event inMatrixSession:self.roomDataSource.mxSession];
                    if ([widget.type isEqualToString:kWidgetTypeJitsiV1] ||
                        [widget.type isEqualToString:kWidgetTypeJitsiV2])
                    {
                        result = NO;
                    }
                }
            default:
                break;
        }
    }
    
    return result;
}

- (void)copyEvent:(MXEvent*)event inCell:(id<MXKCellRendering>)cell withCellData:(MXKRoomBubbleCellData *)cellData
{
    MXKRoomBubbleTableViewCell *roomBubbleTableViewCell = (MXKRoomBubbleTableViewCell *)cell;
    MXKAttachment *attachment = cellData.attachment;
    
    if (!attachment)
    {
        NSArray *components = cellData.bubbleComponents;
        MXKRoomBubbleComponent *selectedComponent;
        for (selectedComponent in components)
        {
            if ([selectedComponent.event.eventId isEqualToString:event.eventId])
            {
                break;
            }
            selectedComponent = nil;
        }

        NSAttributedString *attributedTextMessage = selectedComponent.attributedTextMessage;
        
        if (attributedTextMessage)
        {
            if (@available(iOS 15.0, *))
            {
                MXKPasteboardManager.shared.pasteboard.string = [PillsFormatter stringByReplacingPillsIn:attributedTextMessage
                                                                                                    mode:PillsReplacementTextModeMarkdown];
            }
            else
            {
                MXKPasteboardManager.shared.pasteboard.string = attributedTextMessage.string;
            }
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

- (RoomContextualMenuItem *)replyInThreadMenuItemWithEvent:(MXEvent*)event
{
    MXWeakify(self);
    
    RoomContextualMenuItem *item = [[RoomContextualMenuItem alloc] initWithMenuAction:RoomContextualMenuActionReplyInThread];
    item.isEnabled = [self.roomDataSource canReplyToEventWithId:event.eventId] && !self.voiceMessageController.isRecordingAudio;
    item.action = ^{
        MXStrongifyAndReturnIfNil(self);
        
        [self hideContextualMenuAnimated:YES cancelEventSelection:NO completion:nil];

        if (RiotSettings.shared.enableThreads)
        {
            [self openThreadWithId:event.eventId];
        }
        else
        {
            [self showThreadsBetaForEvent:event];
        }
    };
    
    return item;
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

#pragma mark - Threads

- (BOOL)showThreadOptionForEvent:(MXEvent*)event
{
    return !self.roomDataSource.threadId
        && !event.threadId
        && (RiotSettings.shared.enableThreads || self.mainSession.store.supportedMatrixVersions.supportsThreads);
}

- (void)showThreadsNotice
{
    if (!self.threadsNoticeModalPresenter)
    {
        self.threadsNoticeModalPresenter = [SlidingModalPresenter new];
    }

    [self.threadsNoticeModalPresenter dismissWithAnimated:NO completion:nil];

    ThreadsNoticeViewController *threadsNoticeVC = [ThreadsNoticeViewController instantiate];

    MXWeakify(self);

    threadsNoticeVC.didTapDoneButton = ^{

        MXStrongifyAndReturnIfNil(self);

        [self.threadsNoticeModalPresenter dismissWithAnimated:YES completion:^{
            RiotSettings.shared.threadsNoticeDisplayed = YES;
        }];
    };

    [self.threadsNoticeModalPresenter present:threadsNoticeVC
                                         from:self.presentedViewController?:self
                                     animated:YES
                                      options:SlidingModalPresenter.SpanningOption
                                   completion:nil];
}

- (void)showThreadsBetaForEvent:(MXEvent *)event
{
    if (self.threadsBetaBridgePresenter)
    {
        [self.threadsBetaBridgePresenter dismissWithAnimated:YES completion:nil];
        self.threadsBetaBridgePresenter = nil;
    }

    self.threadsBetaBridgePresenter = [[ThreadsBetaCoordinatorBridgePresenter alloc] initWithThreadId:event.eventId
                                                                                             infoText:VectorL10n.threadsBetaInformation
                                                                                       additionalText:nil];
    self.threadsBetaBridgePresenter.delegate = self;

    [self.threadsBetaBridgePresenter presentFrom:self.presentedViewController?:self animated:YES];
}

- (void)openThreadWithId:(NSString *)threadId
{
    if (self.threadsBridgePresenter)
    {
        [self.threadsBridgePresenter dismissWithAnimated:YES completion:nil];
        self.threadsBridgePresenter = nil;
    }

    self.threadsBridgePresenter = [self.delegate threadsCoordinatorForRoomViewController:self threadId:threadId];
    self.threadsBridgePresenter.delegate = self;
    [self.threadsBridgePresenter pushFrom:self.navigationController animated:YES];
}

- (void)highlightAndDisplayEvent:(NSString *)eventId completion:(void (^)(void))completion
{
    NSInteger row = [self.roomDataSource indexOfCellDataWithEventId:eventId];
    if (row == NSNotFound)
    {
        //  event with eventId is not loaded into data source yet, load another data source and display it
        [self startActivityIndicator];
        MXWeakify(self);
        [RoomDataSource loadRoomDataSourceWithRoomId:self.roomDataSource.roomId
                                      initialEventId:eventId
                                            threadId:nil
                                    andMatrixSession:self.roomDataSource.mxSession
                                          onComplete:^(RoomDataSource *roomDataSource) {
            MXStrongifyAndReturnIfNil(self);
            [roomDataSource finalizeInitialization];
            [self stopActivityIndicator];
            roomDataSource.markTimelineInitialEvent = YES;
            [self displayRoom:roomDataSource];
            // Give the data source ownership to the room view controller.
            self.hasRoomDataSourceOwnership = YES;
            if (completion)
            {
                completion();
            }
        }];
        return;
    }
    
    self.customizedRoomDataSource.highlightedEventId = eventId;
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    if ([[self.bubblesTableView indexPathsForVisibleRows] containsObject:indexPath])
    {
        [self.bubblesTableView reloadRowsAtIndexPaths:@[indexPath]
                                     withRowAnimation:UITableViewRowAnimationNone];
        [self.bubblesTableView scrollToRowAtIndexPath:indexPath
                                     atScrollPosition:UITableViewScrollPositionMiddle
                                             animated:YES];
    }
    else if ([self.bubblesTableView vc_hasIndexPath:indexPath])
    {
        [self.bubblesTableView scrollToRowAtIndexPath:indexPath
                                     atScrollPosition:UITableViewScrollPositionMiddle
                                             animated:YES];
    }
    if (completion)
    {
        completion();
    }
}

- (void)cancelEventHighlight
{
    //  if data source is highlighting an event, dismiss the highlight when user dragges the table view
    if (self.customizedRoomDataSource.highlightedEventId)
    {
        NSInteger row = [self.roomDataSource indexOfCellDataWithEventId:self.customizedRoomDataSource.highlightedEventId];
        if (row == NSNotFound)
        {
            self.customizedRoomDataSource.highlightedEventId = nil;
            return;
        }
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        if ([[self.bubblesTableView indexPathsForVisibleRows] containsObject:indexPath])
        {
            self.customizedRoomDataSource.highlightedEventId = nil;
            [self.bubblesTableView reloadRowsAtIndexPaths:@[indexPath]
                                         withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}

- (void)updateThreadListBarButtonBadgeWith:(MXThreadingService *)service
{
    [self updateThreadListBarButtonItem:nil with:service];
}

- (void)updateThreadListBarButtonItem:(UIBarButtonItem *)barButtonItem with:(MXThreadingService *)service
{
    if (!service)
    {
        return;
    }

    __block NSInteger replaceIndex = NSNotFound;
    [self.navigationItem.rightBarButtonItems enumerateObjectsUsingBlock:^(UIBarButtonItem * _Nonnull item, NSUInteger index, BOOL * _Nonnull stop)
     {
        if (item.tag == kThreadListBarButtonItemTag)
        {
            replaceIndex = index;
            *stop = YES;
        }
    }];

    if (!barButtonItem && replaceIndex == NSNotFound)
    {
        //  there is no thread list bar button item, and not provided another to update
        //  ignore
        return;
    }

    UIBarButtonItem *threadListBarButtonItem = barButtonItem ?: [self threadListBarButtonItem];
    UIButton *button = (UIButton *)threadListBarButtonItem.customView;
    
    MXThreadNotificationsCount *notificationsCount = [service notificationsCountForRoom:self.roomDataSource.roomId];
    
    UIImage *buttonIcon = [AssetImages.threadsIcon.image vc_resizedWith:kThreadListBarButtonItemImageSize];
    [button setImage:buttonIcon forState:UIControlStateNormal];
    button.contentEdgeInsets = kThreadListBarButtonItemContentInsetsNoDot;

    if (notificationsCount.notificationsNumber > 0)
    {
        BadgeLabel *badgeLabel = [[BadgeLabel alloc] init];
        badgeLabel.text = notificationsCount.notificationsNumber > 99 ? @"99+" : [NSString stringWithFormat:@"%lu", notificationsCount.notificationsNumber];
        id<Theme> theme = ThemeService.shared.theme;
        badgeLabel.font = theme.fonts.caption1SB;
        badgeLabel.textColor = theme.colors.navigation;
        badgeLabel.badgeColor = notificationsCount.numberOfHighlightedThreads ? theme.colors.alert : theme.colors.secondaryContent;
        [button addSubview:badgeLabel];
        
        [badgeLabel layoutIfNeeded];
        
        badgeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [badgeLabel.centerYAnchor constraintEqualToAnchor:button.centerYAnchor
                                                constant:badgeLabel.bounds.size.height - buttonIcon.size.height / 2].active = YES;
        [badgeLabel.centerXAnchor constraintEqualToAnchor:button.centerXAnchor
                                                 constant:badgeLabel.bounds.size.width + buttonIcon.size.width / 2].active = YES;
    }

    if (replaceIndex == NSNotFound)
    {
        // there is no thread list bar button item, this was only an update
        return;
    }

    UIBarButtonItem *originalItem = self.navigationItem.rightBarButtonItems[replaceIndex];
    UIButton *originalButton = (UIButton *)originalItem.customView;
    if ([originalButton imageForState:UIControlStateNormal] == [button imageForState:UIControlStateNormal]
        && UIEdgeInsetsEqualToEdgeInsets(originalButton.contentEdgeInsets, button.contentEdgeInsets))
    {
        //  no need to replace, it's the same
        return;
    }
    NSMutableArray<UIBarButtonItem*> *items = [self.navigationItem.rightBarButtonItems mutableCopy];
    items[replaceIndex] = threadListBarButtonItem;
    self.navigationItem.rightBarButtonItems = items;
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

    [self showEmojiPickerForEventId:eventId];
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
        
        [self sendImage:imageData mimeType:mimeType];
    }
    else if (fileUTI.isVideo)
    {
        [self sendVideo:url];
    }
    else if (fileUTI.isFile)
    {
        [self sendFile:url mimeType:mimeType];
    }
    else
    {
        MXLogDebug(@"[MXKRoomViewController] File upload using MIME type %@ is not supported.", mimeType);
        
        [self showAlertWithTitle:[VectorL10n fileUploadErrorTitle]
                         message:[VectorL10n fileUploadErrorUnsupportedFileTypeMessage]];
    }
}

- (void)sendImage:(NSData *)imageData mimeType:(NSString *)mimeType {
    // Create before sending the message in case of a discussion (direct chat)
    MXWeakify(self);
    [self createDiscussionIfNeeded:^(BOOL readyToSend) {
        MXStrongifyAndReturnIfNil(self);
        if (readyToSend)
        {
            // Let the datasource send it and manage the local echo
            [self.roomDataSource sendImage:imageData mimeType:mimeType success:nil failure:^(NSError *error) {
                // Nothing to do. The image is marked as unsent in the room history by the datasource
                MXLogDebug(@"[MXKRoomViewController] sendImage failed.");
            }];
        }
        // Errors are handled at the request level. This should be improved in case of code rewriting.
    }];
}

- (void)sendVideo:(NSURL * _Nonnull)url {
    // Create before sending the message in case of a discussion (direct chat)
    MXWeakify(self);
    [self createDiscussionIfNeeded:^(BOOL readyToSend) {
        MXStrongifyAndReturnIfNil(self);
        if (readyToSend)
        {
            // Let the datasource send it and manage the local echo
            [(RoomDataSource*)self.roomDataSource sendVideo:url success:nil failure:^(NSError *error) {
                // Nothing to do. The video is marked as unsent in the room history by the datasource
                MXLogDebug(@"[MXKRoomViewController] sendVideo failed.");
            }];
        }
        // Errors are handled at the request level. This should be improved in case of code rewriting.
    }];
}

- (void)sendFile:(NSURL * _Nonnull)url mimeType:(NSString *)mimeType {
    // Create before sending the message in case of a discussion (direct chat)
    MXWeakify(self);
    [self createDiscussionIfNeeded:^(BOOL readyToSend) {
        MXStrongifyAndReturnIfNil(self);
        if (readyToSend)
        {
            // Let the datasource send it and manage the local echo
            [self.roomDataSource sendFile:url mimeType:mimeType success:nil failure:^(NSError *error) {
                // Nothing to do. The file is marked as unsent in the room history by the datasource
                MXLogDebug(@"[MXKRoomViewController] sendFile failed.");
            }];
        }
        // Errors are handled at the request level. This should be improved in case of code rewriting.
    }];
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

- (void)cameraPresenter:(CameraPresenter *)cameraPresenter didSelectImage:(UIImage *)image
{
    [cameraPresenter dismissWithAnimated:YES completion:nil];
    self.cameraPresenter = nil;
    
    NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
    
    // Create before sending the message in case of a discussion (direct chat)
    [self createDiscussionIfNeeded:^(BOOL readyToSend) {
        if (readyToSend && [self inputToolbarConformsToToolbarViewProtocol])
        {
            [self.inputToolbarView sendSelectedImage:imageData
                                       withMimeType:MXKUTI.jpeg.mimeType
                                 andCompressionMode:MediaCompressionHelper.defaultCompressionMode
                                isPhotoLibraryAsset:NO];
        }
        // Errors are handled at the request level. This should be improved in case of code rewriting.
    }];
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
    
    // Create before sending the message in case of a discussion (direct chat)
    [self createDiscussionIfNeeded:^(BOOL readyToSend) {
        if (readyToSend && [self inputToolbarConformsToToolbarViewProtocol])
        {
            [self.inputToolbarView sendSelectedImage:imageData
                                       withMimeType:uti.mimeType
                                 andCompressionMode:MediaCompressionHelper.defaultCompressionMode
                                isPhotoLibraryAsset:YES];
        }
        // Errors are handled at the request level. This should be improved in case of code rewriting.
    }];
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
    
    // Set a 1080p video conversion preset as compression mode only has an effect on the images.
    [MXSDKOptions sharedInstance].videoConversionPresetName = AVAssetExportPreset1920x1080;
    
    // Create before sending the message in case of a discussion (direct chat)
    [self createDiscussionIfNeeded:^(BOOL readyToSend) {
        if (readyToSend && [self inputToolbarConformsToToolbarViewProtocol])
        {
            [self.inputToolbarView sendSelectedAssets:assets withCompressionMode:MediaCompressionHelper.defaultCompressionMode];
        }
        // Errors are handled at the request level. This should be improved in case of code rewriting.
    }];
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
    [self notifyDelegateOnLeaveRoomIfNecessary];
}

- (void)roomInfoCoordinatorBridgePresenter:(RoomInfoCoordinatorBridgePresenter *)coordinatorBridgePresenter didReplaceRoomWithReplacementId:(NSString *)roomId
{
    if (self.delegate)
    {
        [self.delegate roomViewController:self didReplaceRoomWithReplacementId:roomId];
    }
    else
    {
        ScreenPresentationParameters *presentationParameters = [[ScreenPresentationParameters alloc] initWithRestoreInitialDisplay:YES stackAboveVisibleViews:NO];
        RoomNavigationParameters *parameters = [[RoomNavigationParameters alloc] initWithRoomId:roomId eventId:nil mxSession:self.mainSession presentationParameters:presentationParameters showSettingsInitially:YES];
        [[AppDelegate theDelegate] showRoomWithParameters:parameters];
    }
}

#pragma mark - RemoveJitsiWidgetViewDelegate

- (void)removeJitsiWidgetViewDidCompleteSliding:(RemoveJitsiWidgetView *)view
{
    view.delegate = nil;
    Widget *jitsiWidget = [self.customizedRoomDataSource jitsiWidget];
    
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
    NSString *message = [VectorL10n microphoneAccessNotGrantedForVoiceMessage:AppInfo.current.displayName];
    
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
    RoomInputToolbarView *toolbar = (RoomInputToolbarView *)self.inputToolbarView;
    if (toolbar && textTrigger.length) {
        NSMutableAttributedString *attributedTextMessage = [[NSMutableAttributedString alloc] initWithAttributedString:toolbar.attributedTextMessage];
        [[attributedTextMessage mutableString] replaceOccurrencesOfString:textTrigger
                                                               withString:@""
                                                                  options:NSBackwardsSearch | NSAnchoredSearch
                                                                    range:NSMakeRange(0, attributedTextMessage.length)];
        [toolbar setAttributedTextMessage:attributedTextMessage];
    }
    
    [self mention:member];
}

- (void)userSuggestionCoordinatorBridge:(UserSuggestionCoordinatorBridge *)coordinator didUpdateViewHeight:(CGFloat)height
{
    if (self.userSuggestionContainerHeightConstraint.constant != height)
    {
        self.userSuggestionContainerHeightConstraint.constant = height;

        [self.view layoutIfNeeded];
    }
}

#pragma mark - ThreadsCoordinatorBridgePresenterDelegate

- (void)threadsCoordinatorBridgePresenterDelegateDidComplete:(ThreadsCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    self.threadsBridgePresenter = nil;
}

- (void)threadsCoordinatorBridgePresenterDelegateDidSelect:(ThreadsCoordinatorBridgePresenter *)coordinatorBridgePresenter roomId:(NSString *)roomId eventId:(NSString *)eventId
{
    MXWeakify(self);
    [self.threadsBridgePresenter dismissWithAnimated:YES completion:^{
        MXStrongifyAndReturnIfNil(self);
        
        if (eventId)
        {
            [self highlightAndDisplayEvent:eventId completion:nil];
        }
    }];
}

- (void)threadsCoordinatorBridgePresenterDidDismissInteractively:(ThreadsCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    self.threadsBridgePresenter = nil;
}

#pragma mark - ThreadsBetaCoordinatorBridgePresenterDelegate

- (void)threadsBetaCoordinatorBridgePresenterDelegateDidTapEnable:(ThreadsBetaCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    MXWeakify(self);
    [self.threadsBetaBridgePresenter dismissWithAnimated:YES completion:^{
        MXStrongifyAndReturnIfNil(self);
        [self cancelEventSelection];
        [self.roomDataSource reload];
        [self openThreadWithId:coordinatorBridgePresenter.threadId];
    }];
}

- (void)threadsBetaCoordinatorBridgePresenterDelegateDidTapCancel:(ThreadsBetaCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    MXWeakify(self);
    [self.threadsBetaBridgePresenter dismissWithAnimated:YES completion:^{
        MXStrongifyAndReturnIfNil(self);
        [self cancelEventSelection];
    }];
}

#pragma mark - MXThreadingServiceDelegate

- (void)threadingServiceDidUpdateThreads:(MXThreadingService *)service
{
    [self updateThreadListBarButtonBadgeWith:service];
}

#pragma mark - RoomParticipantsInviteCoordinatorBridgePresenterDelegate

- (void)roomParticipantsInviteCoordinatorBridgePresenterDidComplete:(RoomParticipantsInviteCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    self.participantsInvitePresenter = nil;
}

- (void)roomParticipantsInviteCoordinatorBridgePresenterDidStartLoading:(RoomParticipantsInviteCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    [self startActivityIndicator];
}

- (void)roomParticipantsInviteCoordinatorBridgePresenterDidEndLoading:(RoomParticipantsInviteCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    [self stopActivityIndicator];
}

#pragma mark - Pills
/// Register provider for Pills.
- (void)registerPillAttachmentViewProviderIfNeeded
{
    if (@available(iOS 15.0, *))
    {
        if (![NSTextAttachment textAttachmentViewProviderClassForFileType:PillsFormatter.pillUTType])
        {
            [NSTextAttachment registerTextAttachmentViewProviderClass:PillAttachmentViewProvider.class forFileType:PillsFormatter.pillUTType];
        }
    }
}

#pragma mark - ComposerCreateActionListBridgePresenter

- (void)composerCreateActionListBridgePresenterDelegateDidComplete:(ComposerCreateActionListBridgePresenter *)coordinatorBridgePresenter action:(enum ComposerCreateAction)action
{
    
    [coordinatorBridgePresenter dismissWithAnimated:true completion:^{
        switch (action) {
            case ComposerCreateActionPhotoLibrary:
                [self showMediaPickerAnimated:YES];
                break;
            case ComposerCreateActionStickers:
                [self roomInputToolbarViewPresentStickerPicker];
                break;
            case ComposerCreateActionAttachments:
                [self roomInputToolbarViewDidTapFileUpload];
                break;
            case ComposerCreateActionVoiceBroadcast:
                [self roomInputToolbarViewDidTapVoiceBroadcast];
                break;
            case ComposerCreateActionPolls:
                [self.delegate roomViewControllerDidRequestPollCreationFormPresentation:self];
                break;
            case ComposerCreateActionLocation:
                [self.delegate roomViewControllerDidRequestLocationSharingFormPresentation:self];
                break;
            case ComposerCreateActionCamera:
                [self showCameraControllerAnimated:YES];
                break;
        }
        self.composerCreateActionListBridgePresenter = nil;
    }];
}

- (void)composerCreateActionListBridgePresenterDelegateDidToggleTextFormatting:(ComposerCreateActionListBridgePresenter *)coordinatorBridgePresenter enabled:(BOOL)enabled
{
    [self togglePlainTextMode];
}

- (void)composerCreateActionListBridgePresenterDidDismissInteractively:(ComposerCreateActionListBridgePresenter *)coordinatorBridgePresenter
{
    self.composerCreateActionListBridgePresenter = nil;
}

@end
