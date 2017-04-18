/*
 Copyright 2014 OpenMarket Ltd
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

#import "RoomViewController.h"

#import "RoomDataSource.h"

#import "AppDelegate.h"

#import "RoomInputToolbarView.h"

#import "RoomActivitiesView.h"

#import "AttachmentsViewController.h"

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

#import "MXKRoomBubbleTableViewCell+Riot.h"

#import "AvatarGenerator.h"
#import "Tools.h"

#import "GBDeviceInfo_iOS.h"

#import "RoomEncryptedDataBubbleCell.h"
#import "EncryptionInfoView.h"

#import "MXRoom+Riot.h"

@interface RoomViewController ()
{
    // The expanded header
    ExpandedRoomTitleView *expandedHeader;
    
    // The preview header
    PreviewRoomTitleView *previewHeader;
    
    // The customized room data source for Vector
    RoomDataSource *customizedRoomDataSource;
    
    // The user taps on a member thumbnail
    MXRoomMember *selectedRoomMember;

    // The user taps on a user id contained in a message
    MXKContact *selectedContact;

    // List of members who are typing in the room.
    NSArray *currentTypingUsers;
    
    // Typing notifications listener.
    id typingNotifListener;
    
    // The first tab is selected by default in room details screen in case of 'showRoomDetails' segue.
    // Use this flag to select a specific tab (0: people, 1: files, 2: settings).
    NSUInteger selectedRoomDetailsIndex;
    
    // No field is selected by default in room details screen in case of 'showRoomDetails' segue.
    // Use this value to select a specific field in room settings.
    RoomSettingsViewControllerField selectedRoomSettingsField;

    // The position of the first touch down event stored in case of scrolling when the expanded header is visible.
    CGPoint startScrollingPoint;
    
    // Missed discussions badge
    NSUInteger missedDiscussionsCount;
    NSUInteger missedHighlightCount;
    UIBarButtonItem *missedDiscussionsButton;
    UILabel *missedDiscussionsBadgeLabel;
    UIView  *missedDiscussionsBadgeLabelBgView;
    UIView  *missedDiscussionsBarButtonCustomView;
    
    // Potential encryption details view.
    EncryptionInfoView *encryptionInfoView;

    // The list of unknown devices that prevent outgoing messages from being sent
    MXUsersDevicesMap<MXDeviceInfo*> *unknownDevices;
    
    // Observe kAppDelegateDidTapStatusBarNotification to handle tap on clock status bar.
    id kAppDelegateDidTapStatusBarNotificationObserver;
    
    // Observe kAppDelegateNetworkStatusDidChangeNotification to handle network status change.
    id kAppDelegateNetworkStatusDidChangeNotificationObserver;

    // Observers to manage ongoing conference call banner
    id kMXCallStateDidChangeObserver;
    id kMXCallManagerConferenceStartedObserver;
    id kMXCallManagerConferenceFinishedObserver;
    
    // Observer kMXRoomSummaryDidChangeNotification to keep updated the missed discussion count
    id mxRoomSummaryDidChangeObserver;
}

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
    
    // Setup `MXKViewControllerHandling` properties
    self.defaultBarTintColor = kRiotNavBarTintColor;
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];

    // Listen to the event sent state changes
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eventDidChangeSentState:) name:kMXEventDidChangeSentStateNotification object:nil];
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
    
    // Prepare expanded header
    self.expandedHeaderContainer.backgroundColor = kRiotColorLightGrey;
    
    expandedHeader = [ExpandedRoomTitleView roomTitleView];
    expandedHeader.delegate = self;
    expandedHeader.tapGestureDelegate = self;
    expandedHeader.translatesAutoresizingMaskIntoConstraints = NO;
    [self.expandedHeaderContainer addSubview:expandedHeader];
    // Force expanded header in full width
    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:expandedHeader
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.expandedHeaderContainer
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:0];
    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:expandedHeader
                                                                      attribute:NSLayoutAttributeLeading
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.expandedHeaderContainer
                                                                      attribute:NSLayoutAttributeLeading
                                                                     multiplier:1.0
                                                                       constant:0];
    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:expandedHeader
                                                                       attribute:NSLayoutAttributeTrailing
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self.expandedHeaderContainer
                                                                       attribute:NSLayoutAttributeTrailing
                                                                      multiplier:1.0
                                                                        constant:0];
    
    [NSLayoutConstraint activateConstraints:@[leftConstraint, rightConstraint, topConstraint]];
    
    
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(onSwipeGesture:)];
    [swipe setNumberOfTouchesRequired:1];
    [swipe setDirection:UISwipeGestureRecognizerDirectionUp];
    [self.expandedHeaderContainer addGestureRecognizer:swipe];
    
    // Prepare preview header container
    self.previewHeaderContainer.backgroundColor = kRiotColorLightGrey;
    
    // Replace the default input toolbar view.
    // Note: this operation will force the layout of subviews. That is why cell view classes must be registered before.
    [self setRoomInputToolbarViewClass:RoomInputToolbarView.class];
    
    // Update the inputToolBar height.
    CGFloat height = (self.inputToolbarView ? ((RoomInputToolbarView*)self.inputToolbarView).mainToolbarMinHeightConstraint.constant : 0);
    // Disable animation during the update
    [UIView setAnimationsEnabled:NO];
    [self roomInputToolbarView:self.inputToolbarView heightDidChanged:height completion:nil];
    [UIView setAnimationsEnabled:YES];
    
    // set extra area
    [self setRoomActivitiesViewClass:RoomActivitiesView.class];
    
    // Custom the attachmnet viewer
    [self setAttachmentsViewerClass:AttachmentsViewController.class];
    
    // Update navigation bar items
    self.navigationItem.rightBarButtonItem.target = self;
    self.navigationItem.rightBarButtonItem.action = @selector(onButtonPressed:);
    
    // Prepare missed dicussion badge
    missedDiscussionsBarButtonCustomView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 21)];
    missedDiscussionsBarButtonCustomView.backgroundColor = [UIColor clearColor];
    missedDiscussionsBarButtonCustomView.clipsToBounds = NO;
    
    missedDiscussionsBadgeLabelBgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 21, 21)];
    [missedDiscussionsBadgeLabelBgView.layer setCornerRadius:10];
    
    [missedDiscussionsBarButtonCustomView addSubview:missedDiscussionsBadgeLabelBgView];
    missedDiscussionsBarButtonCustomView.accessibilityIdentifier = @"RoomVCMissedDiscussionsBarButton";
    
    missedDiscussionsBadgeLabel = [[UILabel alloc]initWithFrame:CGRectMake(2, 2, 17, 17)];
    missedDiscussionsBadgeLabel.textColor = [UIColor whiteColor];
    missedDiscussionsBadgeLabel.font = [UIFont boldSystemFontOfSize:14];
    missedDiscussionsBadgeLabel.backgroundColor = [UIColor clearColor];
    
    missedDiscussionsBadgeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [missedDiscussionsBadgeLabelBgView addSubview:missedDiscussionsBadgeLabel];
    
    NSLayoutConstraint *centerXConstraint = [NSLayoutConstraint constraintWithItem:missedDiscussionsBadgeLabel
                                                                         attribute:NSLayoutAttributeCenterX
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:missedDiscussionsBadgeLabelBgView
                                                                         attribute:NSLayoutAttributeCenterX
                                                                        multiplier:1.0
                                                                          constant:0];
    NSLayoutConstraint *centerYConstraint = [NSLayoutConstraint constraintWithItem:missedDiscussionsBadgeLabel
                                                                         attribute:NSLayoutAttributeCenterY
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:missedDiscussionsBadgeLabelBgView
                                                                         attribute:NSLayoutAttributeCenterY
                                                                        multiplier:1.0
                                                                          constant:0];
    
    [NSLayoutConstraint activateConstraints:@[centerXConstraint, centerYConstraint]];
    
    // Set up the room title view according to the data source (if any)
    [self refreshRoomTitle];
    
    // Refresh tool bar if the room data source is set.
    if (self.roomDataSource)
    {
        [self refreshRoomInputToolbar];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Screen tracking (via Google Analytics)
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    if (tracker)
    {
        [tracker set:kGAIScreenName value:@"ChatRoom"];
        [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    }
    
    // Refresh the room title view
    [self refreshRoomTitle];
    
    // Refresh tool bar if the room data source is set.
    if (self.roomDataSource)
    {
        [self refreshRoomInputToolbar];
    }
    
    [self listenTypingNotifications];
    [self listenCallNotifications];
    
    if (self.showExpandedHeader)
    {
        [self showExpandedHeader:YES];
    }
    
    // Observe kAppDelegateDidTapStatusBarNotification.
    kAppDelegateDidTapStatusBarNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kAppDelegateDidTapStatusBarNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self.bubblesTableView setContentOffset:CGPointMake(-self.bubblesTableView.contentInset.left, -self.bubblesTableView.contentInset.top) animated:YES];
        
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // hide action
    if (currentAlert)
    {
        [currentAlert dismiss:NO];
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
    
    // Hide expanded/preview header to restore navigation bar settings
    [self showExpandedHeader:NO];
    [self showPreviewHeader:NO];
    
    if (kAppDelegateDidTapStatusBarNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kAppDelegateDidTapStatusBarNotificationObserver];
        kAppDelegateDidTapStatusBarNotificationObserver = nil;
    }

    [self removeCallNotificationsListeners];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.roomDataSource)
    {
        // Set visible room id
        [AppDelegate theDelegate].visibleRoomId = self.roomDataSource.roomId;
    }
    
    // Observe network reachability
    kAppDelegateNetworkStatusDidChangeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kAppDelegateNetworkStatusDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self refreshActivitiesViewDisplay];
        
    }];
    [self refreshActivitiesViewDisplay];
    
    // Observe missed notifications
    mxRoomSummaryDidChangeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXRoomSummaryDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self refreshMissedDiscussionsCount:NO];
        
    }];
    [self refreshMissedDiscussionsCount:YES];

    // Warn about the beta state of e2e encryption when entering the first time in an encrypted room
    MXKAccount *account = [[MXKAccountManager sharedManager] accountForUserId:self.roomDataSource.mxSession.myUser.userId];
    if (account && !account.isWarnedAboutEncryption && self.roomDataSource.room.state.isEncrypted)
    {
        [currentAlert dismiss:NO];

        __weak __typeof(self) weakSelf = self;
        currentAlert = [[MXKAlert alloc] initWithTitle:NSLocalizedStringFromTable(@"warning", @"Vector", nil)
                                               message:NSLocalizedStringFromTable(@"room_warning_about_encryption", @"Vector", nil)
                                                 style:MXKAlertStyleAlert];

        currentAlert.cancelButtonIndex = [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {

            if (weakSelf)
            {
                __strong __typeof(weakSelf)self = weakSelf;
                self->currentAlert = nil;

                account.warnedAboutEncryption = YES;
            }

        }];

        currentAlert.mxkAccessibilityIdentifier = @"RoomVCEncryptionAlert";
        [currentAlert showInViewController:self];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
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
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    UIEdgeInsets contentInset = self.bubblesTableView.contentInset;
    contentInset.bottom = self.bottomLayoutGuide.length;
    self.bubblesTableView.contentInset = contentInset;
    
    // Check here whether a subview has been added or removed
    if (encryptionInfoView)
    {
        if (encryptionInfoView.superview)
        {
            // Hide the potential expanded header when a subview is added.
            self.showExpandedHeader = NO;
        }
        else
        {
            // Reset
            encryptionInfoView = nil;
            
            // Reload the full table to take into account a potential change on a device status.
            [self.bubblesTableView reloadData];
        }
    }
    
    if (eventDetailsView)
    {
        if (eventDetailsView.superview)
        {
            // Hide the potential expanded header when a subview is added.
            self.showExpandedHeader = NO;
        }
        else
        {
            // Reset
            eventDetailsView = nil;
        }
    }
    
    // Check whether the expanded header is visible
    if (self.expandedHeaderContainer.isHidden == NO)
    {
        // Adjust the expanded header height by taking into account the actual position of the room avatar
        // This position depends automaticcaly on the screen orientation.
        if ([self.titleView isKindOfClass:[RoomAvatarTitleView class]])
        {
            RoomAvatarTitleView *avatarTitleView = (RoomAvatarTitleView*)self.titleView;
            CGRect roomAvatarFrame = avatarTitleView.roomAvatar.frame;
            CGPoint roomAvatarActualPosition = [avatarTitleView convertPoint:roomAvatarFrame.origin toView:self.view];
            
            CGFloat avatarHeaderHeight = roomAvatarActualPosition.y + roomAvatarFrame.size.height;
            if (expandedHeader.roomAvatarHeaderBackgroundHeightConstraint.constant != avatarHeaderHeight)
            {
                expandedHeader.roomAvatarHeaderBackgroundHeightConstraint.constant = avatarHeaderHeight;
                
                // Force the layout of expandedHeader to update the position of 'bottomBorderView' which
                // is used to define the actual height of the expanded header container.
                [expandedHeader layoutIfNeeded];
            }
        }
        
        // Adjust the top constraint of the bubbles table
        CGRect frame = expandedHeader.bottomBorderView.frame;
        self.expandedHeaderContainerHeightConstraint.constant = frame.origin.y + frame.size.height;
        
        self.bubblesTableViewTopConstraint.constant = self.expandedHeaderContainerHeightConstraint.constant - self.bubblesTableView.contentInset.top;
    }
    // Check whether the preview header is visible
    else if (previewHeader)
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
        
        // Adjust the top constraint of the bubbles table
        CGRect frame = previewHeader.bottomBorderView.frame;
        self.previewHeaderContainerHeightConstraint.constant = frame.origin.y + frame.size.height;
        
        self.bubblesTableViewTopConstraint.constant = self.previewHeaderContainerHeightConstraint.constant - self.bubblesTableView.contentInset.top;
    }
    
    [self refreshMissedDiscussionsCount:YES];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    // Hide the expanded header or the preview in case of iPad and iPhone 6 plus.
    // On these devices, the display mode of the splitviewcontroller may change during screen rotation.
    // It may correspond to an overlay mode in portrait and a side-by-side mode in landscape.
    // This display mode change involves a change at the navigation bar level.
    // If we don't hide the header, the navigation bar is in a wrong state after rotation. FIXME: Find a way to keep visible the header on rotation.
    if ([GBDeviceInfo deviceInfo].family == GBDeviceFamilyiPad || [GBDeviceInfo deviceInfo].displayInfo.display >= GBDeviceDisplay5p5Inch)
    {
        // Hide the expanded header (if any) on device rotation
        [self showExpandedHeader:NO];
        
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
        // This transform is the identity transform when no rotation is applied;
        // otherwise, it is a transform that applies a 90 degree, -90 degree, or 180 degree rotation.
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

#pragma mark - Override MXKRoomViewController

- (void)displayRoom:(MXKRoomDataSource *)dataSource
{
    // Remove potential preview Data
    if (roomPreviewData)
    {
        roomPreviewData = nil;
        [self removeMatrixSession:self.mainSession];
    }
    
    [super displayRoom:dataSource];
    
    customizedRoomDataSource = nil;
    
    if (self.roomDataSource)
    {
        // Set room title view
        [self refreshRoomTitle];
        
        // Store ref on customized room data source
        if ([dataSource isKindOfClass:RoomDataSource.class])
        {
            customizedRoomDataSource = (RoomDataSource*)dataSource;
        }
    }
    else
    {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    
    [self refreshRoomInputToolbar];
}

- (void)onRoomDataSourceReady
{
    // Handle here invitation
    if (self.roomDataSource.room.state.membership == MXMembershipInvite)
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
            // Force expanded header refresh if it is visible
            if (self.expandedHeaderContainer.isHidden == NO)
            {
                expandedHeader.mxRoom = self.roomDataSource.room;
                
                // Force the layout of subviews (some constraints may have been updated)
                [self forceLayoutRefresh];
            }
            
            // Restore tool bar view and room activities view if none
            if (!self.inputToolbarView)
            {
                [self setRoomInputToolbarViewClass:RoomInputToolbarView.class];
                
                // Update the inputToolBar height.
                CGFloat height = (self.inputToolbarView ? ((RoomInputToolbarView*)self.inputToolbarView).mainToolbarMinHeightConstraint.constant : 0);
                // Disable animation during the update
                [UIView setAnimationsEnabled:NO];
                [self roomInputToolbarView:self.inputToolbarView heightDidChanged:height completion:nil];
                [UIView setAnimationsEnabled:YES];
                
                [self refreshRoomInputToolbar];
                
                self.inputToolbarView.hidden = (self.roomDataSource.state != MXKDataSourceStateReady);
            }
            
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
    [self showExpandedHeader:NO];
    
    [super leaveRoomOnEvent:event];
}

- (void)setRoomInputToolbarViewClass:(Class)roomInputToolbarViewClass
{
    // Do not show toolbar in case of preview
    if (self.isRoomPreview)
    {
        roomInputToolbarViewClass = nil;
    }
    
    [super setRoomInputToolbarViewClass:roomInputToolbarViewClass];
}

- (void)setRoomActivitiesViewClass:(Class)roomActivitiesViewClass
{
    // Do not show room activities in case of preview (FIXME: show it when live events will be supported during peeking)
    if (self.isRoomPreview)
    {
        roomActivitiesViewClass = nil;
    }
    
    [super setRoomActivitiesViewClass:roomActivitiesViewClass];
}

- (BOOL)isIRCStyleCommand:(NSString*)string
{
    // Override the default behavior for `/join` command in order to open automatically the joined room
    
    if ([string hasPrefix:kCmdJoinRoom])
    {
        // Join a room
        NSString *roomAlias;
        
        // Sanity check
        if (string.length > kCmdJoinRoom.length)
        {
            roomAlias = [string substringFromIndex:kCmdJoinRoom.length + 1];
            
            // Remove white space from both ends
            roomAlias = [roomAlias stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        }
        
        // Check
        if (roomAlias.length)
        {
            [self.mainSession joinRoom:roomAlias success:^(MXRoom *room) {
                
                // Show the room
                [[AppDelegate theDelegate] showRoom:room.state.roomId andEventId:nil withMatrixSession:self.mainSession];
                
            } failure:^(NSError *error) {
                
                NSLog(@"[Vector RoomVC] Join roomAlias (%@) failed", roomAlias);
                //Alert user
                [[AppDelegate theDelegate] showErrorAsAlert:error];
                
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
    
    if (keyboardHeight)
    {
        // Hide the potential expanded header when keyboard appears.
        // Dispatch this operation to prevent flickering in navigation bar.
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self showExpandedHeader:NO];
            
        });
    }
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

- (void)destroy
{
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    if (currentAlert)
    {
        [currentAlert dismiss:NO];
        currentAlert = nil;
    }
    
    if (customizedRoomDataSource)
    {
        customizedRoomDataSource.selectedEventId = nil;
        customizedRoomDataSource = nil;
    }
    
    [self removeTypingNotificationsListener];
    
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

    [self removeCallNotificationsListeners];

    if (previewHeader || (self.expandedHeaderContainer.isHidden == NO))
    {
        // Here [destroy] is called before [viewWillDisappear:]
        NSLog(@"[Vector RoomVC] destroyed whereas it is still visible");
        
        [previewHeader removeFromSuperview];
        previewHeader = nil;
        
        // Hide preview header container to ignore [self showPreviewHeader:NO] call (if any).
        self.previewHeaderContainer.hidden = YES;
    }
    
    [expandedHeader removeFromSuperview];
    expandedHeader = nil;
    
    roomPreviewData = nil;
    
    missedDiscussionsBarButtonCustomView = nil;
    missedDiscussionsBadgeLabelBgView = nil;
    missedDiscussionsBadgeLabel = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXEventDidChangeSentStateNotification object:nil];

    [super destroy];
}

#pragma mark -

- (void)setShowExpandedHeader:(BOOL)showExpandedHeader
{
    _showExpandedHeader = showExpandedHeader;
    [self showExpandedHeader:showExpandedHeader];
}

#pragma mark - Internals

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
    
    if (self.roomDataSource && self.roomDataSource.state == MXKDataSourceStateReady && self.roomDataSource.room.state.membership == MXMembershipInvite)
    {
        return YES;
    }
    
    return NO;
}

- (void)refreshRoomTitle
{
    // Set the right room title view
    if (self.isRoomPreview)
    {
        // Disable the search button
        self.navigationItem.rightBarButtonItem.enabled = NO;
        
        [self showPreviewHeader:YES];
    }
    else if (self.roomDataSource)
    {
        [self showPreviewHeader:NO];
        
        if (self.roomDataSource.isLive)
        {
            // Enable the search button
            self.navigationItem.rightBarButtonItem.enabled = YES;
            
            // Do not change title view class here if the expanded header is visible.
            if (self.expandedHeaderContainer.hidden)
            {
                [self setRoomTitleViewClass:RoomTitleView.class];
                ((RoomTitleView*)self.titleView).tapGestureDelegate = self;
            }
            else
            {
                // Force expanded header refresh
                expandedHeader.mxRoom = self.roomDataSource.room;
                
                // Force the layout of subviews (some constraints may have been updated)
                [self forceLayoutRefresh];
            }
        }
        else
        {
            // Hide the search button
            self.navigationItem.rightBarButtonItem = nil;
            
            [self setRoomTitleViewClass:SimpleRoomTitleView.class];
            self.titleView.editable = NO;
        }
    }
    else
    {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
}

- (void)refreshRoomInputToolbar
{
    // Check whether the input toolbar is ready before updating it.
    if (self.inputToolbarView && [self.inputToolbarView isKindOfClass:RoomInputToolbarView.class])
    {
        RoomInputToolbarView *roomInputToolbarView = (RoomInputToolbarView*)self.inputToolbarView;
        
        // Check whether the call option is supported
        roomInputToolbarView.supportCallOption = self.roomDataSource.mxSession.callManager && self.roomDataSource.room.state.joinedMembers.count >= 2;

        // Set user picture in input toolbar
        MXKImageView *userPictureView = roomInputToolbarView.pictureView;
        if (userPictureView)
        {
            UIImage *preview = [AvatarGenerator generateAvatarForMatrixItem:self.mainSession.myUser.userId withDisplayName:self.mainSession.myUser.displayname];
            NSString *avatarThumbURL = nil;
            if (self.mainSession.myUser.avatarUrl)
            {
                // Suppose this url is a matrix content uri, we use SDK to get the well adapted thumbnail from server
                avatarThumbURL = [self.mainSession.matrixRestClient urlOfContentThumbnail:self.mainSession.myUser.avatarUrl toFitViewSize:userPictureView.frame.size withMethod:MXThumbnailingMethodCrop];
            }
            userPictureView.enableInMemoryCache = YES;
            [userPictureView setImageURL:avatarThumbURL withType:nil andImageOrientation:UIImageOrientationUp previewImage:preview];
            [userPictureView.layer setCornerRadius:userPictureView.frame.size.width / 2];
            userPictureView.clipsToBounds = YES;
        }

        // Show the hangup button if there is an active call in the current room
        MXCall *callInRoom = [self.roomDataSource.mxSession.callManager callInRoom:self.roomDataSource.roomId];
        if (callInRoom && callInRoom.state != MXCallStateEnded)
        {
            roomInputToolbarView.activeCall = YES;
        }
        else
        {
            roomInputToolbarView.activeCall = NO;
            
            // Hide the call button if there is an active call in another room
            roomInputToolbarView.supportCallOption &= ([[AppDelegate theDelegate] callStatusBarWindow] == nil);
        }
        
        // Check whether the encryption is enabled in the room
        if (self.roomDataSource.room.state.isEncrypted)
        {
            // Encrypt the user's messages as soon as the user supports the encryption?
            roomInputToolbarView.isEncryptionEnabled = (self.mainSession.crypto != nil);
        }
    }
}

- (void)onSwipeGesture:(UISwipeGestureRecognizer*)swipeGestureRecognizer
{
    UIView *view = swipeGestureRecognizer.view;
    
    if (view == self.expandedHeaderContainer)
    {
        // Hide the expanded header when user swipes upward on expanded header.
        // We reset here the property 'showExpandedHeader'. Then the header is not expanded automatically on viewWillAppear.
        self.showExpandedHeader = NO;
    }
    else if (view == self.activitiesView)
    {
        // Dismiss the keyboard when user swipes down on activities view.
        [self.inputToolbarView dismissKeyboard];
    }
}

#pragma mark - Hide/Show expanded header

- (void)showExpandedHeader:(BOOL)isVisible
{
    if (self.expandedHeaderContainer.isHidden == isVisible)
    {
        // Check conditions before making the expanded room header visible.
        // This operation is ignored:
        // - if a screen rotation is in progress.
        // - if the room data source has been removed.
        // - if the room data source does not manage a live timeline.
        // - if the user's membership is not 'join'.
        // - if the view controller is not embedded inside a split view controller yet.
        // - if the encryption view is displayed
        // - if the event details view is displayed
        if (isVisible && (isSizeTransitionInProgress == YES || !self.roomDataSource || !self.roomDataSource.isLive || (self.roomDataSource.room.state.membership != MXMembershipJoin) || !self.splitViewController || encryptionInfoView.superview || eventDetailsView.superview))
        {
            NSLog(@"[Vector RoomVC] Show expanded header ignored");
            return;
        }
        
        self.expandedHeaderContainer.hidden = !isVisible;
        
        // Consider the main navigation controller if the current view controller is embedded inside a split view controller.
        UINavigationController *mainNavigationController = self.navigationController;
        if (self.splitViewController.isCollapsed && self.splitViewController.viewControllers.count)
        {
            mainNavigationController = self.splitViewController.viewControllers.firstObject;
        }
        
        // When the expanded header is displayed, we hide the bottom border of the navigation bar (the shadow image).
        // The default shadow image is nil. When non-nil, this property represents a custom shadow image to show instead
        // of the default. For a custom shadow image to be shown, a custom background image must also be set with the
        // setBackgroundImage:forBarMetrics: method. If the default background image is used, then the default shadow
        // image will be used regardless of the value of this property.
        UIImage *shadowImage = nil;
        MXKImageView *roomAvatarView = nil;
        
        if (isVisible)
        {
            [self setRoomTitleViewClass:RoomAvatarTitleView.class];
            // Note the avatar title view does not define tap gesture.
            
            roomAvatarView = ((RoomAvatarTitleView*)self.titleView).roomAvatar;
            roomAvatarView.alpha = 0.0;
            
            shadowImage = [[UIImage alloc] init];
            
            // Dismiss the keyboard when header is expanded.
            [self.inputToolbarView dismissKeyboard];
        }
        else
        {
            [self setRoomTitleViewClass:RoomTitleView.class];
            ((RoomTitleView*)self.titleView).tapGestureDelegate = self;
        }
        
        // Force the layout of expandedHeader to update the position of 'bottomBorderView' which is used
        // to define the actual height of the expandedHeader container.
        [expandedHeader layoutIfNeeded];
        CGRect frame = expandedHeader.bottomBorderView.frame;
        self.expandedHeaderContainerHeightConstraint.constant = frame.origin.y + frame.size.height;
        
        // Report shadow image
        [mainNavigationController.navigationBar setShadowImage:shadowImage];
        [mainNavigationController.navigationBar setBackgroundImage:shadowImage forBarMetrics:UIBarMetricsDefault];
        
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             
                             self.bubblesTableViewTopConstraint.constant = (isVisible ? self.expandedHeaderContainerHeightConstraint.constant - self.bubblesTableView.contentInset.top : 0);
                             
                             if (roomAvatarView)
                             {
                                 roomAvatarView.alpha = 1;
                             }
                             
                             // Force to render the view
                             [self forceLayoutRefresh];
                             
                         }
                         completion:^(BOOL finished){
                         }];
    }
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
            NSLog(@"[Vector RoomVC] Show preview header ignored");
            return;
        }
        
        if (isVisible)
        {
            previewHeader = [PreviewRoomTitleView roomTitleView];
            previewHeader.delegate = self;
            previewHeader.tapGestureDelegate = self;
            previewHeader.translatesAutoresizingMaskIntoConstraints = NO;
            [self.previewHeaderContainer addSubview:previewHeader];
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
            
            // Remove details icon
            RoomTitleView *roomTitleView = (RoomTitleView*)self.titleView;
            [roomTitleView.roomDetailsIconImageView removeFromSuperview];
            roomTitleView.roomDetailsIconImageView = nil;
            
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
}

- (void)refreshPreviewHeader:(BOOL)isLandscapeOriented
{
    if (previewHeader)
    {
        MXKImageView *roomAvatarView = nil;
        
        if (isLandscapeOriented)
        {
            CGRect frame = self.navigationController.navigationBar.frame;
            
            previewHeader.mainHeaderContainer.hidden = YES;
            previewHeader.mainHeaderBackgroundHeightConstraint.constant = frame.size.height + (frame.origin.y > 0 ? frame.origin.y : 0);
            
            [self setRoomTitleViewClass:RoomTitleView.class];
            // We don't want to handle tap gesture here
            
            // Remove details icon
            RoomTitleView *roomTitleView = (RoomTitleView*)self.titleView;
            [roomTitleView.roomDetailsIconImageView removeFromSuperview];
            roomTitleView.roomDetailsIconImageView = nil;
            
            // Set preview data to provide the room name
            roomTitleView.roomPreviewData = roomPreviewData;
        }
        else
        {
            previewHeader.mainHeaderContainer.hidden = NO;
            previewHeader.mainHeaderBackgroundHeightConstraint.constant = previewHeader.mainHeaderContainer.frame.size.height;
            
            [self setRoomTitleViewClass:RoomAvatarTitleView.class];
            // Note the avatar title view does not define tap gesture.
            
            RoomAvatarTitleView *roomAvatarTitleView = (RoomAvatarTitleView*)self.titleView;
            
            roomAvatarView = roomAvatarTitleView.roomAvatar;
            roomAvatarView.alpha = 0.0;
            
            // Set the avatar provided in preview data
            if (roomPreviewData.roomAvatarUrl)
            {
                NSString *roomAvatarUrl = [self.mainSession.matrixRestClient urlOfContentThumbnail:roomPreviewData.roomAvatarUrl toFitViewSize:roomAvatarView.frame.size withMethod:MXThumbnailingMethodCrop];
                
                roomAvatarTitleView.roomAvatarURL = roomAvatarUrl;
            }
            else if (roomPreviewData.roomId && roomPreviewData.roomName)
            {
                roomAvatarTitleView.roomAvatarPlaceholder = [AvatarGenerator generateAvatarForMatrixItem:roomPreviewData.roomId withDisplayName:roomPreviewData.roomName];
            }
            else
            {
                roomAvatarTitleView.roomAvatarPlaceholder = [UIImage imageNamed:@"placeholder"];
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
                             
                             self.bubblesTableViewTopConstraint.constant = self.previewHeaderContainerHeightConstraint.constant - self.bubblesTableView.contentInset.top;
                             
                             if (roomAvatarView)
                             {
                                 roomAvatarView.alpha = 1;
                             }
                             
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
    BOOL isEncryptedRoom = self.roomDataSource.room.state.isEncrypted;
    
    // Sanity check
    if ([cellData conformsToProtocol:@protocol(MXKRoomBubbleCellDataStoring)])
    {
        id<MXKRoomBubbleCellDataStoring> bubbleData = (id<MXKRoomBubbleCellDataStoring>)cellData;
        
        // Select the suitable table view cell class
        if (bubbleData.isIncoming)
        {
            if (bubbleData.isAttachmentWithThumbnail)
            {
                if (bubbleData.isPaginationFirstBubble)
                {
                    cellViewClass = isEncryptedRoom ? RoomIncomingEncryptedAttachmentWithPaginationTitleBubbleCell.class : RoomIncomingAttachmentWithPaginationTitleBubbleCell.class;
                }
                else if (bubbleData.shouldHideSenderInformation)
                {
                    cellViewClass = isEncryptedRoom ? RoomIncomingEncryptedAttachmentWithoutSenderInfoBubbleCell.class : RoomIncomingAttachmentWithoutSenderInfoBubbleCell.class;
                }
                else
                {
                    cellViewClass = isEncryptedRoom ? RoomIncomingEncryptedAttachmentBubbleCell.class : RoomIncomingAttachmentBubbleCell.class;
                }
            }
            else
            {
                if (bubbleData.isPaginationFirstBubble)
                {
                    if (bubbleData.shouldHideSenderName)
                    {
                        cellViewClass = isEncryptedRoom ? RoomIncomingEncryptedTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.class : RoomIncomingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.class;
                    }
                    else
                    {
                        cellViewClass = isEncryptedRoom ? RoomIncomingEncryptedTextMsgWithPaginationTitleBubbleCell.class : RoomIncomingTextMsgWithPaginationTitleBubbleCell.class;
                    }
                }
                else if (bubbleData.shouldHideSenderInformation)
                {
                    cellViewClass = isEncryptedRoom ? RoomIncomingEncryptedTextMsgWithoutSenderInfoBubbleCell.class : RoomIncomingTextMsgWithoutSenderInfoBubbleCell.class;
                }
                else if (bubbleData.shouldHideSenderName)
                {
                    cellViewClass = isEncryptedRoom ? RoomIncomingEncryptedTextMsgWithoutSenderNameBubbleCell.class : RoomIncomingTextMsgWithoutSenderNameBubbleCell.class;
                }
                else
                {
                    cellViewClass = isEncryptedRoom ? RoomIncomingEncryptedTextMsgBubbleCell.class : RoomIncomingTextMsgBubbleCell.class;
                }
            }
        }
        else
        {
            // Handle here outgoing bubbles
            if (bubbleData.isAttachmentWithThumbnail)
            {
                if (bubbleData.isPaginationFirstBubble)
                {
                    cellViewClass = isEncryptedRoom ? RoomOutgoingEncryptedAttachmentWithPaginationTitleBubbleCell.class :RoomOutgoingAttachmentWithPaginationTitleBubbleCell.class;
                }
                else if (bubbleData.shouldHideSenderInformation)
                {
                    cellViewClass = isEncryptedRoom ? RoomOutgoingEncryptedAttachmentWithoutSenderInfoBubbleCell.class : RoomOutgoingAttachmentWithoutSenderInfoBubbleCell.class;
                }
                else
                {
                    cellViewClass = isEncryptedRoom ? RoomOutgoingEncryptedAttachmentBubbleCell.class : RoomOutgoingAttachmentBubbleCell.class;
                }
            }
            else
            {
                if (bubbleData.isPaginationFirstBubble)
                {
                    if (bubbleData.shouldHideSenderName)
                    {
                        cellViewClass = isEncryptedRoom ? RoomOutgoingEncryptedTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.class : RoomOutgoingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.class;
                    }
                    else
                    {
                        cellViewClass = isEncryptedRoom ? RoomOutgoingEncryptedTextMsgWithPaginationTitleBubbleCell.class : RoomOutgoingTextMsgWithPaginationTitleBubbleCell.class;
                    }
                }
                else if (bubbleData.shouldHideSenderInformation)
                {
                    cellViewClass = isEncryptedRoom ? RoomOutgoingEncryptedTextMsgWithoutSenderInfoBubbleCell.class :RoomOutgoingTextMsgWithoutSenderInfoBubbleCell.class;
                }
                else if (bubbleData.shouldHideSenderName)
                {
                    cellViewClass = isEncryptedRoom ? RoomOutgoingEncryptedTextMsgWithoutSenderNameBubbleCell.class : RoomOutgoingTextMsgWithoutSenderNameBubbleCell.class;
                }
                else
                {
                    cellViewClass = isEncryptedRoom ? RoomOutgoingEncryptedTextMsgBubbleCell.class : RoomOutgoingTextMsgBubbleCell.class;
                }
            }
        }
    }
    
    return cellViewClass;
}

#pragma mark - MXKDataSource delegate

- (void)dataSource:(MXKDataSource *)dataSource didCellChange:(id)changes
{
    [super dataSource:dataSource didCellChange:changes];
    
    [self refreshActivitiesViewDisplay];
}

- (void)dataSource:(MXKDataSource *)dataSource didRecognizeAction:(NSString *)actionIdentifier inCell:(id<MXKCellRendering>)cell userInfo:(NSDictionary *)userInfo
{
    // Handle here user actions on bubbles for Vector app
    if (customizedRoomDataSource)
    {
        if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellTapOnAvatarView])
        {
            selectedRoomMember = [self.roomDataSource.room.state memberWithUserId:userInfo[kMXKRoomBubbleCellUserIdKey]];
            if (selectedRoomMember)
            {
                [self performSegueWithIdentifier:@"showMemberDetails" sender:self];
            }
        }
        else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellLongPressOnAvatarView])
        {
            // Add the member display name in text input
            MXRoomMember *roomMember = [self.roomDataSource.room.state memberWithUserId:userInfo[kMXKRoomBubbleCellUserIdKey]];
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
                // Highlight this event in displayed message
                customizedRoomDataSource.selectedEventId = tappedEvent.eventId;
            }
            
            // Force table refresh
            [self dataSource:self.roomDataSource didCellChange:nil];
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
                [self showEditButtonAlertMenuForEvent:selectedEvent inCell:cell level:0];
            }
        }
        else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellTapOnAttachmentView]
                 && ((MXKRoomBubbleTableViewCell*)cell).bubbleData.attachment.eventSentState == MXEventSentStateFailed)
        {
            // Shortcut: when clicking on an unsent media, show the action sheet to resend it
            MXEvent *selectedEvent = [self.roomDataSource eventWithEventId:((MXKRoomBubbleTableViewCell*)cell).bubbleData.attachment.eventId];
            [self dataSource:dataSource didRecognizeAction:kMXKRoomBubbleCellRiotEditButtonPressed inCell:cell userInfo:@{kMXKRoomBubbleCellEventKey:selectedEvent}];
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

// Display the edit menu on 2 pages/levels.
- (void)showEditButtonAlertMenuForEvent:(MXEvent*)selectedEvent inCell:(id<MXKCellRendering>)cell level:(NSUInteger)level;
{
    MXKRoomBubbleTableViewCell *roomBubbleTableViewCell = (MXKRoomBubbleTableViewCell *)cell;
    MXKAttachment *attachment = roomBubbleTableViewCell.bubbleData.attachment;

    if (currentAlert)
    {
        [currentAlert dismiss:NO];
        currentAlert = nil;
    }

    __weak __typeof(self) weakSelf = self;
    currentAlert = [[MXKAlert alloc] initWithTitle:nil message:nil style:MXKAlertStyleActionSheet];

    if (level == 0)
    {
        // Add actions for a failed event
        if (selectedEvent.sentState == MXEventSentStateFailed)
        {
            [currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_event_action_resend", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {

                __strong __typeof(weakSelf)strongSelf = weakSelf;
                [strongSelf cancelEventSelection];

                // Let the datasource resend. It will manage local echo, etc.
                [strongSelf.roomDataSource resendEventWithEventId:selectedEvent.eventId success:nil failure:nil];

            }];

            [currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_event_action_delete", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {

                __strong __typeof(weakSelf)strongSelf = weakSelf;
                [strongSelf cancelEventSelection];
                
                [strongSelf.roomDataSource removeEventWithEventId:selectedEvent.eventId];
            }];
        }
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

        if (level == 0)
        {
            [currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_event_action_copy", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {

                __strong __typeof(weakSelf)strongSelf = weakSelf;
                [strongSelf cancelEventSelection];

                [[UIPasteboard generalPasteboard] setString:selectedComponent.textMessage];
                
            }];
        }

        if (level == 0)
        {
            [currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_event_action_quote", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {

                __strong __typeof(weakSelf)strongSelf = weakSelf;
                [strongSelf cancelEventSelection];

                // Quote the message a la Markdown into the input toolbar composer
                strongSelf.inputToolbarView.textMessage = [NSString stringWithFormat:@"%@\n>%@\n\n", strongSelf.inputToolbarView.textMessage, selectedComponent.textMessage];

                // And display the keyboard
                [strongSelf.inputToolbarView becomeFirstResponder];
            }];
        }

        if (level == 1)
        {
            [currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_event_action_share", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {

                __strong __typeof(weakSelf)strongSelf = weakSelf;
                [strongSelf cancelEventSelection];

                NSArray *activityItems = [NSArray arrayWithObjects:selectedComponent.textMessage, nil];

                UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
                activityViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

                if (activityViewController)
                {
                    [strongSelf presentViewController:activityViewController animated:YES completion:nil];
                }
            }];
        }
    }
    else // Add action for attachment
    {
        if (level == 0)
        {
            if (attachment.type == MXKAttachmentTypeImage || attachment.type == MXKAttachmentTypeVideo)
            {
                [currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_event_action_save", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {

                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    [strongSelf cancelEventSelection];

                    [strongSelf startActivityIndicator];

                    [attachment save:^{

                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        [strongSelf stopActivityIndicator];

                    } failure:^(NSError *error) {

                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        [strongSelf stopActivityIndicator];

                        //Alert user
                        [[AppDelegate theDelegate] showErrorAsAlert:error];
                        
                    }];
                    
                    // Start animation in case of download during attachment preparing
                    [roomBubbleTableViewCell startProgressUI];
                    
                }];
            }
        
            [currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_event_action_copy", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {

                __strong __typeof(weakSelf)strongSelf = weakSelf;
                [strongSelf cancelEventSelection];

                [strongSelf startActivityIndicator];

                [attachment copy:^{

                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    [strongSelf stopActivityIndicator];

                } failure:^(NSError *error) {

                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    [strongSelf stopActivityIndicator];

                    //Alert user
                    [[AppDelegate theDelegate] showErrorAsAlert:error];
                    
                }];
                
                // Start animation in case of download during attachment preparing
                [roomBubbleTableViewCell startProgressUI];
            }];
            
            // Check status of the selected event
            if (selectedEvent.sentState == MXEventSentStatePreparing ||
                selectedEvent.sentState == MXEventSentStateEncrypting ||
                selectedEvent.sentState == MXEventSentStateUploading)
            {
                // Upload id is stored in attachment url (nasty trick)
                NSString *uploadId = roomBubbleTableViewCell.bubbleData.attachment.actualURL;
                if ([MXMediaManager existingUploaderWithId:uploadId])
                {
                    [currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_event_action_cancel_upload", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                        
                        // TODO cancel the attachment encryption if it is in progress.
                        
                        // Get again the loader
                        MXMediaLoader *loader = [MXMediaManager existingUploaderWithId:uploadId];
                        if (loader)
                        {
                            [loader cancel];
                        }
                        // Hide the progress animation
                        roomBubbleTableViewCell.progressView.hidden = YES;
                        
                        if (weakSelf)
                        {
                            __strong __typeof(weakSelf)strongSelf = weakSelf;
                            strongSelf->currentAlert = nil;
                            
                            // Remove the outgoing message and its related cached file.
                            [[NSFileManager defaultManager] removeItemAtPath:roomBubbleTableViewCell.bubbleData.attachment.cacheFilePath error:nil];
                            [[NSFileManager defaultManager] removeItemAtPath:roomBubbleTableViewCell.bubbleData.attachment.cacheThumbnailPath error:nil];
                            [strongSelf.roomDataSource removeEventWithEventId:selectedEvent.eventId];
                            
                            [strongSelf cancelEventSelection];
                        }
                        
                    }];
                }
            }
        }

        if (level == 1)
        {
            [currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_event_action_share", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {

                __strong __typeof(weakSelf)strongSelf = weakSelf;
                [strongSelf cancelEventSelection];

                [attachment prepareShare:^(NSURL *fileURL) {

                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    strongSelf->documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
                    [strongSelf->documentInteractionController setDelegate:strongSelf];
                    strongSelf->currentSharedAttachment = attachment;

                    if (![strongSelf->documentInteractionController presentOptionsMenuFromRect:strongSelf.view.frame inView:strongSelf.view animated:YES])
                    {
                        strongSelf->documentInteractionController = nil;
                        [attachment onShareEnded];
                        strongSelf->currentSharedAttachment = nil;
                    }

                } failure:^(NSError *error) {

                    //Alert user
                    [[AppDelegate theDelegate] showErrorAsAlert:error];
                    
                }];
                
                // Start animation in case of download during attachment preparing
                [roomBubbleTableViewCell startProgressUI];
            }];
        }
    }

    // Check status of the selected event
    if (selectedEvent.sentState == MXEventSentStateSent)
    {
        // Check whether download is in progress
        if (level == 0 && selectedEvent.isMediaAttachment)
        {
            NSString *cacheFilePath = roomBubbleTableViewCell.bubbleData.attachment.cacheFilePath;
            if ([MXMediaManager existingDownloaderWithOutputFilePath:cacheFilePath])
            {
                [currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_event_action_cancel_download", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {

                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    [strongSelf cancelEventSelection];

                    // Get again the loader
                    MXMediaLoader *loader = [MXMediaManager existingDownloaderWithOutputFilePath:cacheFilePath];
                    if (loader)
                    {
                        [loader cancel];
                    }
                    // Hide the progress animation
                    roomBubbleTableViewCell.progressView.hidden = YES;

                }];
            }
        }

        if (level == 0)
        {
            // Do not allow to redact the event that enabled encryption (m.room.encryption)
            // because it breaks everything
            if (selectedEvent.eventType != MXEventTypeRoomEncryption)
            {
                [currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_event_action_redact", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {

                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    [strongSelf cancelEventSelection];

                    [strongSelf startActivityIndicator];

                    [strongSelf.roomDataSource.room redactEvent:selectedEvent.eventId reason:nil success:^{

                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        [strongSelf stopActivityIndicator];

                    } failure:^(NSError *error) {

                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        [strongSelf stopActivityIndicator];

                        NSLog(@"[Vector RoomVC] Redact event (%@) failed", selectedEvent.eventId);
                        //Alert user
                        [[AppDelegate theDelegate] showErrorAsAlert:error];
                        
                    }];
                }];
            }
        }

        if (level == 1)
        {
            [currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_event_action_permalink", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {

                __strong __typeof(weakSelf)strongSelf = weakSelf;
                [strongSelf cancelEventSelection];

                // Create a matrix.to permalink that is common to all matrix clients
                NSString *permalink = [MXTools permalinkToEvent:selectedEvent.eventId inRoom:selectedEvent.roomId];

                // Create a room matrix.to permalink
                [[UIPasteboard generalPasteboard] setString:permalink];
            }];
        }

        if (level == 1)
        {
            [currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_event_action_view_source", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {

                __strong __typeof(weakSelf)strongSelf = weakSelf;
                [strongSelf cancelEventSelection];

                // Display event details
                [strongSelf showEventDetails:selectedEvent];
            }];
        }

        if (level == 1)
        {
            [currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_event_action_report", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {

                __strong __typeof(weakSelf)strongSelf = weakSelf;
                [strongSelf cancelEventSelection];

                // Prompt user to enter a description of the problem content.
                MXKAlert *reasonAlert = [[MXKAlert alloc] initWithTitle:NSLocalizedStringFromTable(@"room_event_action_report_prompt_reason", @"Vector", nil)  message:nil style:MXKAlertStyleAlert];

                [reasonAlert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                    textField.secureTextEntry = NO;
                    textField.placeholder = nil;
                    textField.keyboardType = UIKeyboardTypeDefault;
                }];

                [reasonAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {

                    UITextField *textField = [alert textFieldAtIndex:0];

                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    strongSelf->currentAlert = nil;

                    [strongSelf startActivityIndicator];

                    [strongSelf.roomDataSource.room reportEvent:selectedEvent.eventId score:-100 reason:textField.text success:^{

                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        [strongSelf stopActivityIndicator];

                        // Prompt user to ignore content from this user
                        MXKAlert *ignoreAlert = [[MXKAlert alloc] initWithTitle:NSLocalizedStringFromTable(@"room_event_action_report_prompt_ignore_user", @"Vector", nil)  message:nil style:MXKAlertStyleAlert];

                        [ignoreAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"yes"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {

                            __strong __typeof(weakSelf)strongSelf = weakSelf;
                            strongSelf->currentAlert = nil;

                            [strongSelf startActivityIndicator];

                            // Add the user to the blacklist: ignored users
                            [strongSelf.mainSession ignoreUsers:@[selectedEvent.sender] success:^{

                                __strong __typeof(weakSelf)strongSelf = weakSelf;
                                [strongSelf stopActivityIndicator];

                            } failure:^(NSError *error) {

                                __strong __typeof(weakSelf)strongSelf = weakSelf;
                                [strongSelf stopActivityIndicator];

                                NSLog(@"[Vector RoomVC] Ignore user (%@) failed", selectedEvent.sender);
                                //Alert user
                                [[AppDelegate theDelegate] showErrorAsAlert:error];

                            }];

                        }];

                        ignoreAlert.cancelButtonIndex = [ignoreAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"no"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {

                            __strong __typeof(weakSelf)strongSelf = weakSelf;
                            strongSelf->currentAlert = nil;
                        }];

                        strongSelf->currentAlert = ignoreAlert;
                        [ignoreAlert showInViewController:strongSelf];

                    } failure:^(NSError *error) {

                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        [strongSelf stopActivityIndicator];

                        NSLog(@"[Vector RoomVC] Report event (%@) failed", selectedEvent.eventId);
                        //Alert user
                        [[AppDelegate theDelegate] showErrorAsAlert:error];
                        
                    }];
                }];
                
                reasonAlert.cancelButtonIndex = [reasonAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                    
                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    strongSelf->currentAlert = nil;
                }];
                
                strongSelf->currentAlert = reasonAlert;
                [reasonAlert showInViewController:strongSelf];
            }];
        }
        
        if (level == 1 && self.roomDataSource.room.state.isEncrypted)
        {
            [currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_event_action_view_encryption", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                [strongSelf cancelEventSelection];
                
                // Display encryption details
                [strongSelf showEncryptionInformation:selectedEvent];
            }];
        }


        if (level == 0)
        {
            [currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_event_action_more", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {

                __strong __typeof(weakSelf)strongSelf = weakSelf;
                [strongSelf cancelEventSelection];

                // Show the next level of options
                [strongSelf showEditButtonAlertMenuForEvent:selectedEvent inCell:cell level:1];

            }];
        }
    }
    
    currentAlert.cancelButtonIndex = [currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"cancel", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
        
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf cancelEventSelection];
        
    }];
    
    // Do not display empty action sheet
    if (currentAlert.cancelButtonIndex)
    {
        currentAlert.mxkAccessibilityIdentifier = @"RoomVCEventMenuAlert";
        currentAlert.sourceView = roomBubbleTableViewCell;
        [currentAlert showInViewController:self];
    }
    else
    {
        currentAlert = nil;
    }
}

- (BOOL)dataSource:(MXKDataSource *)dataSource shouldDoAction:(NSString *)actionIdentifier inCell:(id<MXKCellRendering>)cell userInfo:(NSDictionary *)userInfo defaultValue:(BOOL)defaultValue
{
    BOOL shouldDoAction = defaultValue;

    if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellShouldInteractWithURL])
    {
        // Try to catch universal link supported by the app
        NSURL *url = userInfo[kMXKRoomBubbleCellUrl];
        
        // When a link refers to a room alias/id, a user id or an event id, the non-ASCII characters (like '#' in room alias) has been escaped
        // to be able to convert it into a legal URL string.
        NSString *absoluteURLString = [url.absoluteString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

        // If the link can be open it by the app, let it do
        if ([Tools isUniversalLink:url])
        {
            shouldDoAction = NO;

            // iOS Patch: fix vector.im urls before using it
            NSURL *fixedURL = [Tools fixURLWithSeveralHashKeys:url];

            [[AppDelegate theDelegate] handleUniversalLinkFragment:fixedURL.fragment];
        }
        // Open a detail screen about the clicked user
        else if ([MXTools isMatrixUserIdentifier:absoluteURLString])
        {
            shouldDoAction = NO;

            NSString *userId = absoluteURLString;

            MXRoomMember* member = [self.roomDataSource.room.state memberWithUserId:userId];
            if (member)
            {
                // Use the room member detail VC for room members
                selectedRoomMember = member;
                [self performSegueWithIdentifier:@"showMemberDetails" sender:self];
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
            NSString *fragment = [NSString stringWithFormat:@"/room/%@", [roomIdOrAlias stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            [[AppDelegate theDelegate] handleUniversalLinkFragment:fragment];
        }
    }

    return shouldDoAction;
}

- (void)cancelEventSelection
{
    if (currentAlert)
    {
        [currentAlert dismiss:NO];
        currentAlert = nil;
    }

    customizedRoomDataSource.selectedEventId = nil;

    // Force table refresh
    [self dataSource:self.roomDataSource didCellChange:nil];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Keep ref on destinationViewController
    [super prepareForSegue:segue sender:sender];

    id pushedViewController = [segue destinationViewController];

    if ([[segue identifier] isEqualToString:@"showRoomDetails"])
    {
        if ([pushedViewController isKindOfClass:[SegmentedViewController class]])
        {
            // Dismiss keyboard
            [self dismissKeyboard];

            SegmentedViewController* segmentedViewController = (SegmentedViewController*)pushedViewController;

            MXSession* session = self.roomDataSource.mxSession;
            NSString* roomId = self.roomDataSource.roomId;
            NSMutableArray* viewControllers = [[NSMutableArray alloc] init];
            NSMutableArray* titles = [[NSMutableArray alloc] init];

            // members tab
            [titles addObject: NSLocalizedStringFromTable(@"room_details_people", @"Vector", nil)];
            RoomParticipantsViewController* participantsViewController = [RoomParticipantsViewController roomParticipantsViewController];
            participantsViewController.delegate = self;
            participantsViewController.enableMention = YES;
            participantsViewController.mxRoom = [session roomWithRoomId:roomId];
            [viewControllers addObject:participantsViewController];
            
            // Files tab
            [titles addObject: NSLocalizedStringFromTable(@"room_details_files", @"Vector", nil)];
            RoomFilesViewController *roomFilesViewController = [RoomFilesViewController roomViewController];
            MXKRoomDataSource *roomFilesDataSource = [[MXKRoomDataSource alloc] initWithRoomId:roomId andMatrixSession:session];
            roomFilesDataSource.filterMessagesWithURL = YES;
            [roomFilesDataSource finalizeInitialization];
            // Give the data source ownership to the room files view controller.
            roomFilesViewController.hasRoomDataSourceOwnership = YES;
            [roomFilesViewController displayRoom:roomFilesDataSource];
            [viewControllers addObject:roomFilesViewController];

            // Settings tab
            [titles addObject: NSLocalizedStringFromTable(@"room_details_settings", @"Vector", nil)];
            RoomSettingsViewController *settingsViewController = [RoomSettingsViewController roomSettingsViewController];
            [settingsViewController initWithSession:session andRoomId:roomId];
            [viewControllers addObject:settingsViewController];

            // Sanity check
            if (selectedRoomDetailsIndex > 2)
            {
                selectedRoomDetailsIndex = 0;
            }

            segmentedViewController.title = NSLocalizedStringFromTable(@"room_details_title", @"Vector", nil);
            [segmentedViewController initWithTitles:titles viewControllers:viewControllers defaultSelected:selectedRoomDetailsIndex];

            // Add the current session to be able to observe its state change.
            [segmentedViewController addMatrixSession:session];

            // Preselect the tapped field if any
            settingsViewController.selectedRoomSettingsField = selectedRoomSettingsField;
            selectedRoomSettingsField = RoomSettingsViewControllerFieldNone;
        }
    }
    else if ([[segue identifier] isEqualToString:@"showRoomSearch"])
    {
        // Dismiss keyboard
        [self dismissKeyboard];

        RoomSearchViewController* roomSearchViewController = (RoomSearchViewController*)pushedViewController;
        // Add the current data source to be able to search messages.
        roomSearchViewController.roomDataSource = self.roomDataSource;
    }
    else if ([[segue identifier] isEqualToString:@"showMemberDetails"])
    {
        if (selectedRoomMember)
        {
            RoomMemberDetailsViewController *memberViewController = pushedViewController;

            // Set delegate to handle action on member (start chat, mention)
            memberViewController.delegate = self;
            memberViewController.enableMention = (self.inputToolbarView != nil);
            memberViewController.enableVoipCall = NO;

            [memberViewController displayRoomMember:selectedRoomMember withMatrixRoom:self.roomDataSource.room];

            selectedRoomMember = nil;
        }
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

#pragma mark - MXKRoomInputToolbarViewDelegate

- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView isTyping:(BOOL)typing
{
    [super roomInputToolbarView:toolbarView isTyping:typing];
    
    // Cancel potential selected event (to leave edition mode)
    if (typing && customizedRoomDataSource.selectedEventId)
    {
        [self cancelEventSelection];
    }
}

- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView placeCallWithVideo:(BOOL)video
{
    // Conference call is not supported in encrypted rooms
    if (self.roomDataSource.room.state.isEncrypted && self.roomDataSource.room.state.joinedMembers.count > 2)
    {
        [currentAlert dismiss:NO];

        __weak __typeof(self) weakSelf = self;
        currentAlert = [[MXKAlert alloc] initWithTitle:[NSBundle mxk_localizedStringForKey:@"room_no_conference_call_in_encrypted_rooms"]  message:nil style:MXKAlertStyleAlert];

        currentAlert.cancelButtonIndex = [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {

            __strong __typeof(weakSelf)strongSelf = weakSelf;
            strongSelf->currentAlert = nil;
        }];

        currentAlert.mxkAccessibilityIdentifier = @"RoomVCCallAlert";
        [currentAlert showInViewController:self];
    }
    // In case of conference call, check that the user has enough power level
    else if (self.roomDataSource.room.state.joinedMembers.count > 2 &&
        ![MXCallManager canPlaceConferenceCallInRoom:self.roomDataSource.room])
    {
        [currentAlert dismiss:NO];

        __weak __typeof(self) weakSelf = self;
        currentAlert = [[MXKAlert alloc] initWithTitle:[NSBundle mxk_localizedStringForKey:@"room_no_power_to_create_conference_call"]  message:nil style:MXKAlertStyleAlert];

        currentAlert.cancelButtonIndex = [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {

            __strong __typeof(weakSelf)strongSelf = weakSelf;
            strongSelf->currentAlert = nil;
        }];

        currentAlert.mxkAccessibilityIdentifier = @"RoomVCCallAlert";
        [currentAlert showInViewController:self];
    }
    else
    {
        NSString *appDisplayName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];

        // Check app permissions before placing the call
        [MXKTools checkAccessForCall:video
         manualChangeMessageForAudio:[NSString stringWithFormat:[NSBundle mxk_localizedStringForKey:@"microphone_access_not_granted_for_call"], appDisplayName]
         manualChangeMessageForVideo:[NSString stringWithFormat:[NSBundle mxk_localizedStringForKey:@"camera_access_not_granted_for_call"], appDisplayName]
           showPopUpInViewController:self completionHandler:^(BOOL granted) {

               if (granted)
               {
                   [self.roomDataSource.room placeCallWithVideo:video success:nil failure:nil];
               }
               else
               {
                   NSLog(@"RoomViewController: Warning: The application does not have the perssion to place the call");
               }
           }];
    }
}

- (void)roomInputToolbarViewHangupCall:(MXKRoomInputToolbarView *)toolbarView
{
    MXCall *callInRoom = [self.roomDataSource.mxSession.callManager callInRoom:self.roomDataSource.roomId];
    if (callInRoom)
    {
        [callInRoom hangup];
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

            // Here the placeholder may have been defined temporarily to display IRC command usage.
            // The original placeholder (savedInputToolbarPlaceholder) will be restored during the handling of the next typing notification 
            if (!toolbarView.placeholder)
            {
                // Restore the placeholder if any
                toolbarView.placeholder =  savedInputToolbarPlaceholder.length ? savedInputToolbarPlaceholder : nil;
                savedInputToolbarPlaceholder = nil;
            }

        }];
    }
}

#pragma mark - RoomParticipantsViewControllerDelegate

- (void)roomParticipantsViewController:(RoomParticipantsViewController *)roomParticipantsViewController mention:(MXRoomMember*)member
{
    [self mention:member];
}

#pragma mark - MXKRoomMemberDetailsViewControllerDelegate

- (void)roomMemberDetailsViewController:(MXKRoomMemberDetailsViewController *)roomMemberDetailsViewController startChatWithMemberId:(NSString *)matrixId completion:(void (^)(void))completion
{
    [[AppDelegate theDelegate] createDirectChatWithUserId:matrixId completion:completion];
}

- (void)roomMemberDetailsViewController:(MXKRoomMemberDetailsViewController *)roomMemberDetailsViewController mention:(MXRoomMember*)member
{
    [self mention:member];
}

#pragma mark - Action

- (IBAction)onButtonPressed:(id)sender
{
    if (sender == self.navigationItem.rightBarButtonItem)
    {
        [self performSegueWithIdentifier:@"showRoomSearch" sender:self];
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

#pragma mark -

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if ([MXKRoomViewController instancesRespondToSelector:@selector(scrollViewWillBeginDragging:)])
    {
        [super scrollViewWillBeginDragging:scrollView];
    }
    
    if (self.expandedHeaderContainer.isHidden == NO)
    {
        // Store here the position of the first touch down event
        UIPanGestureRecognizer *panGestureRecognizer = scrollView.panGestureRecognizer;
        if (panGestureRecognizer && panGestureRecognizer.numberOfTouches)
        {
            startScrollingPoint = [panGestureRecognizer locationOfTouch:0 inView:self.view];
        }
        else
        {
            startScrollingPoint = CGPointZero;
        }
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
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    if ([MXKRoomViewController instancesRespondToSelector:@selector(scrollViewDidEndScrollingAnimation:)])
    {
        [super scrollViewDidEndScrollingAnimation:scrollView];
    }
    
    [self refreshActivitiesViewDisplay];
}

- (void)onScrollViewDidEndScrolling:(UIScrollView *)scrollView
{
    // Check whether the user's finger has been dragged over the expanded header.
    // In that case the expanded header is collapsed
    if (self.expandedHeaderContainer.isHidden == NO && (startScrollingPoint.y != 0))
    {
        UIPanGestureRecognizer *panGestureRecognizer = scrollView.panGestureRecognizer;
        CGPoint translate = [panGestureRecognizer translationInView:self.view];
        
        if (startScrollingPoint.y + translate.y < self.expandedHeaderContainer.frame.size.height)
        {
            // Hide the expanded header by reseting the property 'showExpandedHeader'. Then the header is not expanded automatically on viewWillAppear.
            self.showExpandedHeader = NO;
        }
    }
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
        if (self.expandedHeaderContainer.isHidden)
        {
            // Expand the header
            [self showExpandedHeader:YES];
        }
        else
        {
            selectedRoomSettingsField = RoomSettingsViewControllerFieldNone;
            
            CGPoint point = [tapGestureRecognizer locationInView:self.expandedHeaderContainer];
            
            CGRect roomNameArea = expandedHeader.displayNameTextField.frame;
            roomNameArea.origin.x -= 10;
            roomNameArea.origin.y -= 10;
            roomNameArea.size.width += 20;
            roomNameArea.size.height += 15;
            if (CGRectContainsPoint(roomNameArea, point))
            {
                // Starting to move the local preview view
                selectedRoomSettingsField = RoomSettingsViewControllerFieldName;
            }
            else
            {
                CGRect roomTopicArea = expandedHeader.roomTopic.frame;
                roomTopicArea.origin.x -= 10;
                roomTopicArea.size.width += 20;
                roomTopicArea.size.height += 10;
                if (CGRectContainsPoint(roomTopicArea, point))
                {
                    // Starting to move the local preview view
                    selectedRoomSettingsField = RoomSettingsViewControllerFieldTopic;
                }
                else if ([self.titleView isKindOfClass:[RoomAvatarTitleView class]])
                {
                    RoomAvatarTitleView *avatarTitleView = (RoomAvatarTitleView*)self.titleView;
                    CGRect roomAvatarFrame = avatarTitleView.roomAvatar.frame;
                    roomAvatarFrame.origin = [avatarTitleView convertPoint:roomAvatarFrame.origin toView:self.expandedHeaderContainer];
                    if (CGRectContainsPoint(roomAvatarFrame, point))
                    {
                        // Starting to move the local preview view
                        selectedRoomSettingsField = RoomSettingsViewControllerFieldAvatar;
                    }
                }
            }
            
            // Open room settings
            selectedRoomDetailsIndex = 2;
            [self performSegueWithIdentifier:@"showRoomDetails" sender:self];
        }
    }
    else if (tappedView == titleView.roomDetailsMask)
    {
        // Open room details by selecting member list
        selectedRoomDetailsIndex = 0;
        [self performSegueWithIdentifier:@"showRoomDetails" sender:self];
    }
    else if (tappedView == previewHeader.rightButton)
    {
        // 'Join' button has been pressed
        if (roomPreviewData)
        {
            // Attempt to join the room (keep reference on the potential eventId, the preview data will be removed automatically in case of success).
            NSString *eventId = roomPreviewData.eventId;
            
            // We promote here join by room alias instead of room id when an alias is available.
            NSString *roomIdOrAlias = roomPreviewData.roomId;
            if (roomPreviewData.roomAliases.count)
            {
                roomIdOrAlias = roomPreviewData.roomAliases.firstObject;
            }
            
            // Note in case of simple link to a room the signUrl param is nil
            [self joinRoomWithRoomIdOrAlias:roomIdOrAlias andSignUrl:roomPreviewData.emailInvitation.signUrl completion:^(BOOL succeed) {

                if (succeed)
                {
                    // If an event was specified, replace the datasource by a non live datasource showing the event
                    if (eventId)
                    {
                        RoomDataSource *roomDataSource = [[RoomDataSource alloc] initWithRoomId:self.roomDataSource.roomId initialEventId:eventId andMatrixSession:self.mainSession];
                        [roomDataSource finalizeInitialization];
                        
                        self.hasRoomDataSourceOwnership = YES;
                        
                        [self displayRoom:roomDataSource];
                    }
                    else
                    {
                        // Enable back the text input
                        [self setRoomInputToolbarViewClass:RoomInputToolbarView.class];
                        
                        // Update the inputToolBar height.
                        CGFloat height = (self.inputToolbarView ? ((RoomInputToolbarView*)self.inputToolbarView).mainToolbarMinHeightConstraint.constant : 0);
                        // Disable animation during the update
                        [UIView setAnimationsEnabled:NO];
                        [self roomInputToolbarView:self.inputToolbarView heightDidChanged:height completion:nil];
                        [UIView setAnimationsEnabled:YES];
                        
                        // And the extra area
                        [self setRoomActivitiesViewClass:RoomActivitiesView.class];
                        
                        [self refreshRoomTitle];
                        [self refreshRoomInputToolbar];
                    }
                }

            }];
        }
        else
        {
            [self joinRoom:^(BOOL succeed) {
                
                if (succeed)
                {
                    [self refreshRoomTitle];
                }
                
            }];
        }
    }
    else if (tappedView == previewHeader.leftButton)
    {
        // 'Decline' button has been pressed
        if (roomPreviewData)
        {
            // Decline this invitation = leave this page
            [[AppDelegate theDelegate] restoreInitialDisplay:^{}];
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
                NSLog(@"[Vector RoomVC] Failed to reject an invited room (%@) failed", self.roomDataSource.room.state.roomId);
                
            }];
        }
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
            [self.roomDataSource.room.liveTimeline removeListener:typingNotifListener];
            typingNotifListener = nil;
        }
    }
    
    currentTypingUsers = nil;
}

- (void)listenTypingNotifications
{
    if (self.roomDataSource)
    {
        // Add typing notification listener
        typingNotifListener = [self.roomDataSource.room.liveTimeline listenToEventsOfTypes:@[kMXEventTypeStringTypingNotification] onEvent:^(MXEvent *event, MXTimelineDirection direction, MXRoomState *roomState) {
            
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
                if (currentTypingUsers.count || typingUsers.count)
                {
                    currentTypingUsers = typingUsers;
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
    if ([self.activitiesView isKindOfClass:RoomActivitiesView.class])
    {
        // Prepare here typing notification
        NSString* text = nil;
        NSUInteger count = currentTypingUsers.count;
        
        // get the room member names
        NSMutableArray *names = [[NSMutableArray alloc] init];
        
        // keeps the only the first two users
        for(int i = 0; i < MIN(count, 2); i++)
        {
            NSString* name = [currentTypingUsers objectAtIndex:i];
            
            MXRoomMember* member = [self.roomDataSource.room.state memberWithUserId:name];
            
            if (member && member.displayname.length)
            {
                name = member.displayname;
            }
            
            // sanity check
            if (name)
            {
                [names addObject:name];
            }
        }
        
        if (0 == names.count)
        {
            // something to do ?
        }
        else if (1 == names.count)
        {
            text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_one_user_is_typing", @"Vector", nil), [names objectAtIndex:0]];
        }
        else if (2 == names.count)
        {
            text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_two_users_are_typing", @"Vector", nil), [names objectAtIndex:0], [names objectAtIndex:1]];
        }
        else
        {
            text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_many_users_are_typing", @"Vector", nil), [names objectAtIndex:0], [names objectAtIndex:1]];
        }
        
        [((RoomActivitiesView*) self.activitiesView) displayTypingNotification:text];
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
    kMXCallStateDidChangeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXCallStateDidChange object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {

        MXCall *call = notif.object;
        if ([call.room.roomId isEqualToString:customizedRoomDataSource.roomId])
        {
            [self refreshActivitiesViewDisplay];
            [self refreshRoomInputToolbar];
        }
    }];
    kMXCallManagerConferenceStartedObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXCallManagerConferenceStarted object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {

        NSString *roomId = notif.object;
        if ([roomId isEqualToString:customizedRoomDataSource.roomId])
        {
            [self refreshActivitiesViewDisplay];
        }
    }];
    kMXCallManagerConferenceFinishedObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXCallManagerConferenceFinished object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {

        NSString *roomId = notif.object;
        if ([roomId isEqualToString:customizedRoomDataSource.roomId])
        {
            [self refreshActivitiesViewDisplay];
            [self refreshRoomInputToolbar];
        }
    }];
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

        if ([AppDelegate theDelegate].isOffline)
        {
            [roomActivitiesView displayNetworkErrorNotification:NSLocalizedStringFromTable(@"room_offline_notification", @"Vector", nil)];
        }
        else if (customizedRoomDataSource.room.state.isOngoingConferenceCall)
        {
            // Show the "Ongoing conference call" banner only if the user is not in the conference
            MXCall *callInRoom = [self.roomDataSource.mxSession.callManager callInRoom:self.roomDataSource.roomId];
            if (callInRoom && callInRoom.state != MXCallStateEnded)
            {
                if ([self checkUnsentMessages] == NO)
                {
                    [self refreshTypingNotification];
                }
            }
            else
            {
                [roomActivitiesView displayOngoingConferenceCall:^(BOOL video) {

                    NSLog(@"[Vector RoomVC] onOngoingConferenceCallPressed");

                    // Make sure there is not yet a call
                    if (![customizedRoomDataSource.mxSession.callManager callInRoom:customizedRoomDataSource.roomId])
                    {
                        [customizedRoomDataSource.room placeCallWithVideo:video success:nil failure:nil];
                    }
                }];
            }
        }
        else if ([self checkUnsentMessages] == NO)
        {
            // Show "scroll to bottom" icon when the most recent message is not visible
            if ([self isBubblesTableScrollViewAtTheBottom] == NO)
            {
                // Retrieve the unread messages count
                NSUInteger unreadCount = self.roomDataSource.room.summary.localUnreadEventCount;
                
                if (unreadCount == 0)
                {
                    // Refresh the typing notification here
                    // We will keep visible this notification (if any) beside the "scroll to bottom" icon.
                    [self refreshTypingNotification];
                }
                
                [roomActivitiesView displayScrollToBottomIcon:unreadCount onIconTapGesture:^{
                    
                    [self scrollBubblesTableViewToBottomAnimated:YES];
                    
                }];
            }
            else
            {
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

#pragma mark - Missed discussions handling

- (void)refreshMissedDiscussionsCount:(BOOL)force
{
    // Ignore this action when no room is displayed
    if (!self.roomDataSource || !missedDiscussionsBarButtonCustomView)
    {
        return;
    }
    
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
        
        NSMutableArray *leftBarButtonItems = [NSMutableArray arrayWithArray: self.navigationItem.leftBarButtonItems];
        
        if (missedCount)
        {
            // Consider the main navigation controller if the current view controller is embedded inside a split view controller.
            UINavigationController *mainNavigationController = self.navigationController;
            if (self.splitViewController.isCollapsed && self.splitViewController.viewControllers.count)
            {
                mainNavigationController = self.splitViewController.viewControllers.firstObject;
            }
            UINavigationItem *backItem = mainNavigationController.navigationBar.backItem;
            UIBarButtonItem *backButton = backItem.backBarButtonItem;

            // Refresh missed discussions count label
            if (missedCount > 99)
            {
                missedDiscussionsBadgeLabel.text = @"99+";
            }
            else
            {
                missedDiscussionsBadgeLabel.text = [NSString stringWithFormat:@"%tu", missedCount];
            }
            
            [missedDiscussionsBadgeLabel sizeToFit];
            
            // Update the label background view frame
            CGRect frame = missedDiscussionsBadgeLabelBgView.frame;
            frame.size.width = round(missedDiscussionsBadgeLabel.frame.size.width + 18);
            if (backButton && !backButton.title.length)
            {
                // Shift the badge on the left to be close the back icon
                frame.origin.x = ([GBDeviceInfo deviceInfo].displayInfo.display > GBDeviceDisplay4Inch ? -35 : -25);
            }
            else
            {
                frame.origin.x = 0;
            }
            // Caution: set label background view frame only in case of changes to prevent from looping on 'viewDidLayoutSubviews'.
            if (!CGRectEqualToRect(missedDiscussionsBadgeLabelBgView.frame, frame))
            {
                missedDiscussionsBadgeLabelBgView.frame = frame;
                
                // Adjust the custom view width of the associated bar button
                CGRect bgFrame = missedDiscussionsBarButtonCustomView.frame;
                CGFloat width = frame.size.width + frame.origin.x;
                bgFrame.size.width = (width > 0 ? width : 0);
                missedDiscussionsBarButtonCustomView.frame = bgFrame;
            }
            
            // Set the right background color
            if (highlightCount)
            {
                missedDiscussionsBadgeLabelBgView.backgroundColor = kRiotColorPinkRed;
            }
            else
            {
                missedDiscussionsBadgeLabelBgView.backgroundColor = kRiotColorGreen;
            }
            
            if (!missedDiscussionsButton || [leftBarButtonItems indexOfObject:missedDiscussionsButton] == NSNotFound)
            {
                missedDiscussionsButton = [[UIBarButtonItem alloc] initWithCustomView:missedDiscussionsBarButtonCustomView];
                
                // Add it in left bar items
                [leftBarButtonItems addObject:missedDiscussionsButton];
            }
        }
        else if (missedDiscussionsButton)
        {
            [leftBarButtonItems removeObject:missedDiscussionsButton];
            missedDiscussionsButton = nil;
        }
        
        self.navigationItem.leftBarButtonItems = leftBarButtonItems;
    }
}

#pragma mark - Unsent Messages Handling

-(BOOL)checkUnsentMessages
{
    BOOL hasUnsent = NO;
    BOOL hasUnsentDueToUnknownDevices = NO;

    if ([self.activitiesView isKindOfClass:RoomActivitiesView.class])
    {
        NSArray<MXEvent*> *outgoingMsgs = self.roomDataSource.room.outgoingMessages;
        
        for (MXEvent *event in outgoingMsgs)
        {
            if (event.sentState == MXEventSentStateFailed)
            {
                hasUnsent = YES;

                // Check if the error is due to unknown devices
                if ([event.sentError.domain isEqualToString:MXEncryptingErrorDomain]
                        && event.sentError.code == MXEncryptingErrorUnknownDeviceCode)
                {
                    hasUnsentDueToUnknownDevices = YES;
                    break;
                }
            }
        }
        
        if (hasUnsent)
        {
            NSString *notification = hasUnsentDueToUnknownDevices ?
                NSLocalizedStringFromTable(@"room_unsent_messages_unknown_devices_notification", @"Vector", nil) :
                NSLocalizedStringFromTable(@"room_unsent_messages_notification", @"Vector", nil);

            RoomActivitiesView *roomActivitiesView = (RoomActivitiesView*) self.activitiesView;
            [roomActivitiesView displayUnsentMessagesNotification:notification withResendLink:^{
                
                [self resendAllUnsentMessages];
                
            } andCancelLink:^{

                [self cancelAllUnsentMessages];

            } andIconTapGesture:^{

                if (currentAlert)
                {
                    [currentAlert dismiss:NO];
                }
                
                __weak __typeof(self) weakSelf = self;
                currentAlert = [[MXKAlert alloc] initWithTitle:nil message:nil style:MXKAlertStyleActionSheet];
                
                [currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_resend_unsent_messages", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                    
                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    [strongSelf resendAllUnsentMessages];
                    strongSelf->currentAlert = nil;
                    
                }];
                
                [currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_delete_unsent_messages", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                    
                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    [strongSelf cancelAllUnsentMessages];
                    strongSelf->currentAlert = nil;
                }];
                
                currentAlert.cancelButtonIndex = [currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"cancel", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                    
                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    strongSelf->currentAlert = nil;
                    
                }];
                
                currentAlert.mxkAccessibilityIdentifier = @"RoomVCUnsentMessagesMenuAlert";
                currentAlert.sourceView = roomActivitiesView;
                [currentAlert showInViewController:self];
                
            }];
        }
    }
    
    return hasUnsent;
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

        currentAlert = [[MXKAlert alloc] initWithTitle:[NSBundle mxk_localizedStringForKey:@"unknown_devices_alert_title"]
                                               message:[NSBundle mxk_localizedStringForKey:@"unknown_devices_alert"]
                                                 style:MXKAlertStyleAlert];

        [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"unknown_devices_verify"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
            if (weakSelf)
            {
                typeof(self) self = weakSelf;
                self->currentAlert = nil;

                [self performSegueWithIdentifier:@"showUnknownDevices" sender:self];
            }
        }];

        [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"unknown_devices_send_anyway"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
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
        }];

        currentAlert.mxkAccessibilityIdentifier = @"RoomVCUnknownDevicesAlert";
        [currentAlert showInViewController:self];
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
}

# pragma mark - Encryption Information view

- (void)showEncryptionInformation:(MXEvent *)event
{
    [self dismissKeyboard];

    // Remove potential existing subviews
    [self dismissTemporarySubViews];
    
    encryptionInfoView = [[EncryptionInfoView alloc] initWithEvent:event andMatrixSession:self.roomDataSource.mxSession];
    
    // Add shadow on added view
    encryptionInfoView.layer.cornerRadius = 5;
    encryptionInfoView.layer.shadowOffset = CGSizeMake(0, 1);
    encryptionInfoView.layer.shadowOpacity = 0.5f;
    
    // Add the view and define edge constraints
    [self.view addSubview:encryptionInfoView];
    
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

@end

