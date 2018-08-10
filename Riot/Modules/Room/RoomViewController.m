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

#import "RoomViewController.h"

#import "RoomDataSource.h"
#import "RoomBubbleCellData.h"

#import "AppDelegate.h"

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

#import "RoomSelectedStickerBubbleCell.h"
#import "RoomPredecessorBubbleCell.h"

#import "MXKRoomBubbleTableViewCell+Riot.h"

#import "AvatarGenerator.h"
#import "Tools.h"
#import "WidgetManager.h"

#import "GBDeviceInfo_iOS.h"

#import "RoomEncryptedDataBubbleCell.h"
#import "EncryptionInfoView.h"

#import "MXRoom+Riot.h"

#import "IntegrationManagerViewController.h"
#import "WidgetPickerViewController.h"
#import "StickerPickerViewController.h"

#import "EventFormatter.h"
#import <MatrixKit/MXKSlashCommands.h>

#import "Riot-Swift.h"

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

    // Observers to manage widgets
    id kMXKWidgetManagerDidUpdateWidgetObserver;
    
    // Observer kMXRoomSummaryDidChangeNotification to keep updated the missed discussion count
    id mxRoomSummaryDidChangeObserver;

    // Observer for removing the re-request explanation/waiting dialog
    id mxEventDidDecryptNotificationObserver;
    
    // The table view cell in which the read marker is displayed (nil by default).
    MXKRoomBubbleTableViewCell *readMarkerTableViewCell;
    
    // Tell whether the view controller is appeared or not.
    BOOL isAppeared;
    
    // The right bar button items back up.
    NSArray<UIBarButtonItem *> *rightBarButtonItems;

    // Observe kRiotDesignValuesDidChangeThemeNotification to handle user interface theme change.
    id kRiotDesignValuesDidChangeThemeNotificationObserver;
    
    // Tell whether the input text field is in send reply mode. If true typed message will be sent to highlighted event.
    BOOL isInReplyMode;
    
    // Listener for `m.room.tombstone` event type
    id tombstoneEventNotificationsListener;
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
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    _showExpandedHeader = NO;
    _showMissedDiscussionsBadge = YES;
    
    
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
    
    [self.bubblesTableView registerClass:RoomEmptyBubbleCell.class forCellReuseIdentifier:RoomEmptyBubbleCell.defaultReuseIdentifier];
    
    [self.bubblesTableView registerClass:RoomMembershipBubbleCell.class forCellReuseIdentifier:RoomMembershipBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomMembershipWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomMembershipWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomMembershipCollapsedBubbleCell.class forCellReuseIdentifier:RoomMembershipCollapsedBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomMembershipCollapsedWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomMembershipCollapsedWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomMembershipExpandedBubbleCell.class forCellReuseIdentifier:RoomMembershipExpandedBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomMembershipExpandedWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomMembershipExpandedWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    
    [self.bubblesTableView registerClass:RoomSelectedStickerBubbleCell.class forCellReuseIdentifier:RoomSelectedStickerBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomPredecessorBubbleCell.class forCellReuseIdentifier:RoomPredecessorBubbleCell.defaultReuseIdentifier];
    
    // Prepare expanded header
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
    
    // Replace the default input toolbar view.
    // Note: this operation will force the layout of subviews. That is why cell view classes must be registered before.
    [self setRoomInputToolbarViewClass];
    [self updateInputToolBarViewHeight];
    
    // set extra area
    [self setRoomActivitiesViewClass:RoomActivitiesView.class];
    
    // Custom the attachmnet viewer
    [self setAttachmentsViewerClass:AttachmentsViewController.class];
    
    // Custom the event details view
    [self setEventDetailsViewClass:EventDetailsView.class];
    
    // Update navigation bar items
    for (UIBarButtonItem *barButtonItem in self.navigationItem.rightBarButtonItems)
    {
        barButtonItem.target = self;
        barButtonItem.action = @selector(onButtonPressed:);
    }

    // Prepare missed dicussion badge (if any)
    self.showMissedDiscussionsBadge = _showMissedDiscussionsBadge;
    
    // Set up the room title view according to the data source (if any)
    [self refreshRoomTitle];
    
    // Refresh tool bar if the room data source is set.
    if (self.roomDataSource)
    {
        [self refreshRoomInputToolbar];
    }
    
    // Observe user interface theme change.
    kRiotDesignValuesDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kRiotDesignValuesDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self userInterfaceThemeDidChange];
        
    }];
    [self userInterfaceThemeDidChange];
}

- (void)userInterfaceThemeDidChange
{
    self.defaultBarTintColor = kRiotSecondaryBgColor;
    self.barTitleColor = kRiotPrimaryTextColor;
    self.activityIndicator.backgroundColor = kRiotOverlayColor;
    
    // Prepare jump to last unread banner
    self.jumpToLastUnreadBannerContainer.backgroundColor = kRiotPrimaryBgColor;
    self.jumpToLastUnreadLabel.attributedText = [[NSAttributedString alloc] initWithString:NSLocalizedStringFromTable(@"room_jump_to_first_unread", @"Vector", nil) attributes:@{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle), NSUnderlineColorAttributeName: kRiotPrimaryTextColor, NSForegroundColorAttributeName: kRiotPrimaryTextColor}];
    
    
    self.expandedHeaderContainer.backgroundColor = kRiotSecondaryBgColor;
    self.previewHeaderContainer.backgroundColor = kRiotSecondaryBgColor;
    
    missedDiscussionsBadgeLabel.textColor = kRiotPrimaryBgColor;
    missedDiscussionsBadgeLabel.font = [UIFont boldSystemFontOfSize:14];
    missedDiscussionsBadgeLabel.backgroundColor = [UIColor clearColor];
    
    // Check the table view style to select its bg color.
    self.bubblesTableView.backgroundColor = ((self.bubblesTableView.style == UITableViewStylePlain) ? kRiotPrimaryBgColor : kRiotSecondaryBgColor);
    self.view.backgroundColor = self.bubblesTableView.backgroundColor;
    
    if (self.bubblesTableView.dataSource)
    {
        [self.bubblesTableView reloadData];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return kRiotDesignStatusBarStyle;
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
    
    // Refresh tool bar if the room data source is set.
    if (self.roomDataSource)
    {
        [self refreshRoomInputToolbar];
    }
    
    [self listenTypingNotifications];
    [self listenCallNotifications];
    [self listenWidgetNotifications];
    [self listenTombstoneEventNotifications];
    
    if (self.showExpandedHeader)
    {
        [self showExpandedHeader:YES];
    }
    
    // Observe kAppDelegateDidTapStatusBarNotification.
    kAppDelegateDidTapStatusBarNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kAppDelegateDidTapStatusBarNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self.bubblesTableView setContentOffset:CGPointMake(-self.bubblesTableView.mxk_adjustedContentInset.left, -self.bubblesTableView.mxk_adjustedContentInset.top) animated:YES];
        
    }];
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
    
    // Hide expanded/preview header to restore navigation bar settings
    [self showExpandedHeader:NO];
    [self showPreviewHeader:NO];
    
    if (kAppDelegateDidTapStatusBarNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kAppDelegateDidTapStatusBarNotificationObserver];
        kAppDelegateDidTapStatusBarNotificationObserver = nil;
    }
    
    [self removeCallNotificationsListeners];
    [self removeWidgetNotificationsListeners];
    [self removeTombstoneEventNotificationsListener];

    // Re-enable the read marker display, and disable its update.
    self.roomDataSource.showReadMarker = YES;
    self.updateRoomReadMarker = NO;
    isAppeared = NO;
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
    
    // Observe network reachability
    kAppDelegateNetworkStatusDidChangeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kAppDelegateNetworkStatusDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self refreshActivitiesViewDisplay];
        
    }];
    [self refreshActivitiesViewDisplay];
    [self refreshJumpToLastUnreadBannerDisplay];
    
    // Observe missed notifications
    mxRoomSummaryDidChangeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXRoomSummaryDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {

        MXRoomSummary *roomSummary = notif.object;

        if ([roomSummary.roomId isEqualToString:self.roomDataSource.roomId])
        {
            [self refreshMissedDiscussionsCount:NO];
        }
    }];
    [self refreshMissedDiscussionsCount:YES];
    
    // Warn about the beta state of e2e encryption when entering the first time in an encrypted room
    MXKAccount *account = [[MXKAccountManager sharedManager] accountForUserId:self.roomDataSource.mxSession.myUser.userId];
    if (account && !account.isWarnedAboutEncryption && self.roomDataSource.room.summary.isEncrypted)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        
        __weak __typeof(self) weakSelf = self;
        currentAlert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"warning", @"Vector", nil)
                                                           message:NSLocalizedStringFromTable(@"room_warning_about_encryption", @"Vector", nil)
                                                    preferredStyle:UIAlertControllerStyleAlert];
        
        [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"]
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {
                                                           
                                                           if (weakSelf)
                                                           {
                                                               typeof(self) self = weakSelf;
                                                               self->currentAlert = nil;
                                                               
                                                               account.warnedAboutEncryption = YES;
                                                           }
                                                           
                                                       }]];
        
        [currentAlert mxk_setAccessibilityIdentifier:@"RoomVCEncryptionAlert"];
        [self presentViewController:currentAlert animated:YES completion:nil];
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

    if (mxEventDidDecryptNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:mxEventDidDecryptNotificationObserver];
        mxEventDidDecryptNotificationObserver = nil;
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
        // This position depends automatically on the screen orientation.
        if ([self.titleView isKindOfClass:[RoomAvatarTitleView class]])
        {
            RoomAvatarTitleView *avatarTitleView = (RoomAvatarTitleView*)self.titleView;
            CGPoint roomAvatarOriginInTitleView = avatarTitleView.roomAvatarMask.frame.origin;
            CGPoint roomAvatarActualPosition = [avatarTitleView convertPoint:roomAvatarOriginInTitleView toView:self.view];
            
            CGFloat avatarHeaderHeight = roomAvatarActualPosition.y + expandedHeader.roomAvatar.frame.size.height;
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
        
        self.bubblesTableViewTopConstraint.constant = self.expandedHeaderContainerHeightConstraint.constant - self.bubblesTableView.mxk_adjustedContentInset.top;
        self.jumpToLastUnreadBannerContainerTopConstraint.constant = self.expandedHeaderContainerHeightConstraint.constant;
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
        
        self.bubblesTableViewTopConstraint.constant = self.previewHeaderContainerHeightConstraint.constant - self.bubblesTableView.mxk_adjustedContentInset.top;
        self.jumpToLastUnreadBannerContainerTopConstraint.constant = self.previewHeaderContainerHeightConstraint.constant;
    }
    else
    {
        self.jumpToLastUnreadBannerContainerTopConstraint.constant = self.bubblesTableView.mxk_adjustedContentInset.top;
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

- (void)onMatrixSessionChange
{
    [super onMatrixSessionChange];
    
    // Re-enable the read marker display, and disable its update.
    self.roomDataSource.showReadMarker = YES;
    self.updateRoomReadMarker = NO;
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
        self.eventsAcknowledgementEnabled = YES;
        
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
                [self setRoomInputToolbarViewClass];
                [self updateInputToolBarViewHeight];
                
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
    
    // Force a simple title view initialised with the current room before leaving actually the room.
    [self setRoomTitleViewClass:SimpleRoomTitleView.class];
    self.titleView.editable = NO;
    self.titleView.mxRoom = self.roomDataSource.room;
    
    // Hide the potential read marker banner.
    self.jumpToLastUnreadBannerContainer.hidden = YES;
    
    [super leaveRoomOnEvent:event];
}

// Set the input toolbar according to the current display
- (void)setRoomInputToolbarViewClass
{
    Class roomInputToolbarViewClass = RoomInputToolbarView.class;

    // Check the user has enough power to post message
    if (self.roomDataSource.roomState)
    {
        MXRoomPowerLevels *powerLevels = self.roomDataSource.roomState.powerLevels;
        NSInteger userPowerLevel = [powerLevels powerLevelOfUserWithUserID:self.mainSession.myUser.userId];
        
        BOOL canSend = (userPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsMessage:kMXEventTypeStringRoomMessage]);
        BOOL isRoomObsolete = self.roomDataSource.roomState.isObsolete;
        
        if (isRoomObsolete)
        {
            roomInputToolbarViewClass = nil;
        }
        else if (!canSend)
        {
            roomInputToolbarViewClass = DisabledRoomInputToolbarView.class;
        }
    }

    // Do not show toolbar in case of preview
    if (self.isRoomPreview)
    {
        roomInputToolbarViewClass = nil;
    }
    
    [super setRoomInputToolbarViewClass:roomInputToolbarViewClass];
}

// Get the height of the current room input toolbar
- (CGFloat)inputToolbarHeight
{
    CGFloat height = 0;

    if ([self.inputToolbarView isKindOfClass:RoomInputToolbarView.class])
    {
        height = ((RoomInputToolbarView*)self.inputToolbarView).mainToolbarMinHeightConstraint.constant;
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
            [self.mainSession joinRoom:roomAlias success:^(MXRoom *room) {
                
                // Show the room
                [[AppDelegate theDelegate] showRoom:room.roomId andEventId:nil withMatrixSession:self.mainSession];
                
            } failure:^(NSError *error) {
                
                NSLog(@"[RoomVC] Join roomAlias (%@) failed", roomAlias);
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
    if (isInReplyMode && customizedRoomDataSource.selectedEventId)
    {
        [self.roomDataSource sendReplyToEventWithId:customizedRoomDataSource.selectedEventId withTextMessage:msgTxt success:nil failure:^(NSError *error) {
            // Just log the error. The message will be displayed in red in the room history
            NSLog(@"[MXKRoomViewController] sendTextMessage failed.");
        }];
    }
    else
    {
        // Let the datasource send it and manage the local echo
        [self.roomDataSource sendTextMessage:msgTxt success:nil failure:^(NSError *error)
         {
             // Just log the error. The message will be displayed in red in the room history
             NSLog(@"[MXKRoomViewController] sendTextMessage failed.");
         }];
    }
    
    [self cancelEventSelection];
}

- (void)destroy
{
    rightBarButtonItems = nil;
    for (UIBarButtonItem *barButtonItem in self.navigationItem.rightBarButtonItems)
    {
        barButtonItem.enabled = NO;
    }
    
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
    
    if (kRiotDesignValuesDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kRiotDesignValuesDidChangeThemeNotificationObserver];
        kRiotDesignValuesDidChangeThemeNotificationObserver = nil;
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
    
    [self removeCallNotificationsListeners];
    [self removeWidgetNotificationsListeners];
    [self removeTombstoneEventNotificationsListener];

    if (previewHeader || (self.expandedHeaderContainer.isHidden == NO))
    {
        // Here [destroy] is called before [viewWillDisappear:]
        NSLog(@"[RoomVC] destroyed whereas it is still visible");
        
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

- (void)setShowMissedDiscussionsBadge:(BOOL)showMissedDiscussionsBadge
{
    _showMissedDiscussionsBadge = showMissedDiscussionsBadge;
    
    if (_showMissedDiscussionsBadge && !missedDiscussionsBarButtonCustomView)
    {
        // Prepare missed dicussion badge
        missedDiscussionsBarButtonCustomView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 21)];
        missedDiscussionsBarButtonCustomView.backgroundColor = [UIColor clearColor];
        missedDiscussionsBarButtonCustomView.clipsToBounds = NO;
        
        NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:missedDiscussionsBarButtonCustomView
                                                                            attribute:NSLayoutAttributeHeight
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:nil
                                                                            attribute:NSLayoutAttributeNotAnAttribute
                                                                           multiplier:1.0
                                                                             constant:21];
        
        missedDiscussionsBadgeLabelBgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 21, 21)];
        [missedDiscussionsBadgeLabelBgView.layer setCornerRadius:10];
        
        [missedDiscussionsBarButtonCustomView addSubview:missedDiscussionsBadgeLabelBgView];
        missedDiscussionsBarButtonCustomView.accessibilityIdentifier = @"RoomVCMissedDiscussionsBarButton";
        
        missedDiscussionsBadgeLabel = [[UILabel alloc]initWithFrame:CGRectMake(2, 2, 17, 17)];
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
        
        [NSLayoutConstraint activateConstraints:@[heightConstraint, centerXConstraint, centerYConstraint]];
    }
    else
    {
        missedDiscussionsBarButtonCustomView = nil;
        missedDiscussionsBadgeLabelBgView = nil;
        missedDiscussionsBadgeLabel = nil;
    }
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
    
    if (self.roomDataSource && self.roomDataSource.state == MXKDataSourceStateReady && self.roomDataSource.room.summary.membership == MXMembershipInvite)
    {
        return YES;
    }
    
    return NO;
}

- (void)refreshRoomTitle
{
    if (rightBarButtonItems && !self.navigationItem.rightBarButtonItems)
    {
        // Restore by default the search bar button.
        self.navigationItem.rightBarButtonItems = rightBarButtonItems;
    }
    
    // Set the right room title view
    if (self.isRoomPreview)
    {
        // Do not show the right buttons
        self.navigationItem.rightBarButtonItems = nil;
        
        [self showPreviewHeader:YES];
    }
    else if (self.roomDataSource)
    {
        [self showPreviewHeader:NO];
        
        if (self.roomDataSource.isLive)
        {
            // Enable the right buttons (Search and Integrations)
            for (UIBarButtonItem *barButtonItem in self.navigationItem.rightBarButtonItems)
            {
                barButtonItem.enabled = YES;
            }

            if (self.navigationItem.rightBarButtonItems.count == 2)
            {
                BOOL matrixAppsEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"matrixApps"];
                if (!matrixAppsEnabled)
                {
                    // If the setting is disabled, do not show the icon
                    self.navigationItem.rightBarButtonItems = @[self.navigationItem.rightBarButtonItem];
                }
                else if ([self widgetsCount:NO])
                {
                    // Show there are widgets by changing the "apps" icon color
                    // Show it in red only for room widgets, not user's widgets
                    // TODO: Design must be reviewed
                    UIImage *icon = self.navigationItem.rightBarButtonItems[1].image;
                    icon = [MXKTools paintImage:icon withColor:kRiotColorPinkRed];
                    icon = [icon imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];

                    self.navigationItem.rightBarButtonItems[1].image = icon;
                }
                else
                {
                    // Reset original icon
                    self.navigationItem.rightBarButtonItems[1].image = [UIImage imageNamed:@"apps-icon"];
                }
            }

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
            // Remove the search button temporarily
            rightBarButtonItems = self.navigationItem.rightBarButtonItems;
            self.navigationItem.rightBarButtonItems = nil;
            
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
    MXKImageView *userPictureView;

    // Check whether the input toolbar is ready before updating it.
    if (self.inputToolbarView && [self.inputToolbarView isKindOfClass:RoomInputToolbarView.class])
    {
        RoomInputToolbarView *roomInputToolbarView = (RoomInputToolbarView*)self.inputToolbarView;
        
        // Check whether the call option is supported
        roomInputToolbarView.supportCallOption = self.roomDataSource.mxSession.callManager && self.roomDataSource.room.summary.membersCount.joined >= 2;
        
        // Get user picture view in input toolbar
        userPictureView = roomInputToolbarView.pictureView;
        
        // Show the hangup button if there is an active call or an active jitsi
        // conference call in the current room
        MXCall *callInRoom = [self.roomDataSource.mxSession.callManager callInRoom:self.roomDataSource.roomId];
        if ((callInRoom && callInRoom.state != MXCallStateEnded)
            || [[AppDelegate theDelegate].jitsiViewController.widget.roomId isEqualToString:self.roomDataSource.roomId])
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
        if (self.roomDataSource.room.summary.isEncrypted)
        {
            // Encrypt the user's messages as soon as the user supports the encryption?
            roomInputToolbarView.isEncryptionEnabled = (self.mainSession.crypto != nil);
        }
    }
    else if (self.inputToolbarView && [self.inputToolbarView isKindOfClass:DisabledRoomInputToolbarView.class])
    {
        DisabledRoomInputToolbarView *roomInputToolbarView = (DisabledRoomInputToolbarView*)self.inputToolbarView;

        // Get user picture view in input toolbar
        userPictureView = roomInputToolbarView.pictureView;

        // For the moment, there is only one reason to use `DisabledRoomInputToolbarView`
        [roomInputToolbarView setDisabledReason:NSLocalizedStringFromTable(@"room_do_not_have_permission_to_post", @"Vector", nil)];
    }

    // Set user picture in input toolbar
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
}

- (void)enableReplyMode:(BOOL)enable
{
    isInReplyMode = enable;
    
    if (self.inputToolbarView && [self.inputToolbarView isKindOfClass:[RoomInputToolbarView class]])
    {
        RoomInputToolbarView *roomInputToolbarView = (RoomInputToolbarView*)self.inputToolbarView;
        roomInputToolbarView.replyToEnabled = enable;
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

- (void)updateInputToolBarViewHeight
{
    // Update the inputToolBar height.
    CGFloat height = [self inputToolbarHeight];
    // Disable animation during the update
    [UIView setAnimationsEnabled:NO];
    [self roomInputToolbarView:self.inputToolbarView heightDidChanged:height completion:nil];
    [UIView setAnimationsEnabled:YES];
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
        if (isVisible && (isSizeTransitionInProgress == YES || !self.roomDataSource || !self.roomDataSource.isLive || (self.roomDataSource.room.summary.membership != MXMembershipJoin) || !self.splitViewController || encryptionInfoView.superview || eventDetailsView.superview))
        {
            NSLog(@"[RoomVC] Show expanded header ignored");
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
        
        if (isVisible)
        {
            [self setRoomTitleViewClass:RoomAvatarTitleView.class];
            // Note the avatar title view does not define tap gesture.
            
            expandedHeader.roomAvatar.alpha = 0.0;
            
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
                             
                             self.bubblesTableViewTopConstraint.constant = (isVisible ? self.expandedHeaderContainerHeightConstraint.constant - self.bubblesTableView.mxk_adjustedContentInset.top : 0);
                             self.jumpToLastUnreadBannerContainerTopConstraint.constant = (isVisible ? self.expandedHeaderContainerHeightConstraint.constant : self.bubblesTableView.mxk_adjustedContentInset.top);
                             
                             expandedHeader.roomAvatar.alpha = 1;
                             
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
            NSLog(@"[RoomVC] Show preview header ignored");
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
                                 self.jumpToLastUnreadBannerContainerTopConstraint.constant = self.bubblesTableView.mxk_adjustedContentInset.top;
                                 
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
            [roomTitleView.roomDetailsIconImageView removeFromSuperview];
            roomTitleView.roomDetailsIconImageView = nil;
            
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
                NSString *roomAvatarUrl = [self.mainSession.matrixRestClient urlOfContentThumbnail:roomPreviewData.roomAvatarUrl toFitViewSize:previewHeader.roomAvatar.frame.size withMethod:MXThumbnailingMethodCrop];
                
                previewHeader.roomAvatarURL = roomAvatarUrl;
            }
            else if (roomPreviewData.roomId && roomPreviewData.roomName)
            {
                previewHeader.roomAvatarPlaceholder = [AvatarGenerator generateAvatarForMatrixItem:roomPreviewData.roomId withDisplayName:roomPreviewData.roomName];
            }
            else
            {
                previewHeader.roomAvatarPlaceholder = [UIImage imageNamed:@"placeholder"];
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
                             
                             self.bubblesTableViewTopConstraint.constant = self.previewHeaderContainerHeightConstraint.constant - self.bubblesTableView.mxk_adjustedContentInset.top;
                             self.jumpToLastUnreadBannerContainerTopConstraint.constant = self.previewHeaderContainerHeightConstraint.constant;
                             
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
    BOOL isEncryptedRoom = self.roomDataSource.room.summary.isEncrypted;
    
    // Sanity check
    if ([cellData conformsToProtocol:@protocol(MXKRoomBubbleCellDataStoring)])
    {
        id<MXKRoomBubbleCellDataStoring> bubbleData = (id<MXKRoomBubbleCellDataStoring>)cellData;
        
        // Select the suitable table view cell class, by considering first the empty bubble cell.
        if (bubbleData.hasNoDisplay)
        {
            cellViewClass = RoomEmptyBubbleCell.class;
        }
        else if (bubbleData.tag == RoomBubbleCellDataTagRoomCreateWithPredecessor)
        {
            cellViewClass = RoomPredecessorBubbleCell.class;
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
                // Check whether the provided celldata corresponds to a selected sticker
                if (customizedRoomDataSource.selectedEventId && (bubbleData.attachment.type == MXKAttachmentTypeSticker) && [bubbleData.attachment.eventId isEqualToString:customizedRoomDataSource.selectedEventId])
                {
                    cellViewClass = RoomSelectedStickerBubbleCell.class;
                }
                else if (bubbleData.isPaginationFirstBubble)
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

- (void)dataSource:(MXKDataSource *)dataSource didRecognizeAction:(NSString *)actionIdentifier inCell:(id<MXKCellRendering>)cell userInfo:(NSDictionary *)userInfo
{
    // Handle here user actions on bubbles for Vector app
    if (customizedRoomDataSource)
    {
        if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellTapOnAvatarView])
        {
            selectedRoomMember = [self.roomDataSource.roomState.members memberWithUserId:userInfo[kMXKRoomBubbleCellUserIdKey]];
            if (selectedRoomMember)
            {
                [self performSegueWithIdentifier:@"showMemberDetails" sender:self];
            }
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
                // Highlight this event in displayed message
                [self selectEventWithId:tappedEvent.eventId];
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
        else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellTapOnAttachmentView])
        {
            if (((MXKRoomBubbleTableViewCell*)cell).bubbleData.attachment.eventSentState == MXEventSentStateFailed)
            {
                // Shortcut: when clicking on an unsent media, show the action sheet to resend it
                MXEvent *selectedEvent = [self.roomDataSource eventWithEventId:((MXKRoomBubbleTableViewCell*)cell).bubbleData.attachment.eventId];
                [self dataSource:dataSource didRecognizeAction:kMXKRoomBubbleCellRiotEditButtonPressed inCell:cell userInfo:@{kMXKRoomBubbleCellEventKey:selectedEvent}];
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
                
                // Force table refresh
                [self dataSource:self.roomDataSource didCellChange:nil];
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
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
    
    __weak __typeof(self) weakSelf = self;
    currentAlert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    if (level == 0)
    {
        // Add actions for a failed event
        if (selectedEvent.sentState == MXEventSentStateFailed)
        {
            [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_event_action_resend", @"Vector", nil)
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               
                                                               if (weakSelf)
                                                               {
                                                                   typeof(self) self = weakSelf;
                                                                   
                                                                   [self cancelEventSelection];
                                                                   
                                                                   // Let the datasource resend. It will manage local echo, etc.
                                                                   [self.roomDataSource resendEventWithEventId:selectedEvent.eventId success:nil failure:nil];
                                                               }
                                                               
                                                           }]];
            
            [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_event_action_delete", @"Vector", nil)
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               
                                                               if (weakSelf)
                                                               {
                                                                   typeof(self) self = weakSelf;
                                                                   
                                                                   [self cancelEventSelection];
                                                                   
                                                                   [self.roomDataSource removeEventWithEventId:selectedEvent.eventId];
                                                               }
                                                               
                                                           }]];
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
            // Check status of the selected event
            if (selectedEvent.sentState == MXEventSentStatePreparing ||
                selectedEvent.sentState == MXEventSentStateEncrypting ||
                selectedEvent.sentState == MXEventSentStateSending)
            {
                    [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_event_action_cancel_send", @"Vector", nil)
                                                                     style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * action)
                                             {
                                                 if (weakSelf)
                                                 {
                                                     typeof(self) self = weakSelf;

                                                     self->currentAlert = nil;

                                                     // Cancel and remove the outgoing message
                                                     [self.roomDataSource.room cancelSendingOperation:selectedEvent.eventId];
                                                     [self.roomDataSource removeEventWithEventId:selectedEvent.eventId];
 
                                                     [self cancelEventSelection];
                                                 }

                                             }]];
            }
        }

        if (level == 0)
        {
            [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_event_action_copy", @"Vector", nil)
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               
                                                               if (weakSelf)
                                                               {
                                                                   typeof(self) self = weakSelf;
                                                                   
                                                                   [self cancelEventSelection];
                                                                   
                                                                   [[UIPasteboard generalPasteboard] setString:selectedComponent.textMessage];
                                                               }
                                                               
                                                           }]];
        }
        
        if (level == 0)
        {
            [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_event_action_quote", @"Vector", nil)
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               
                                                               if (weakSelf)
                                                               {
                                                                   typeof(self) self = weakSelf;
                                                                   
                                                                   [self cancelEventSelection];
                                                                   
                                                                   // Quote the message a la Markdown into the input toolbar composer
                                                                   self.inputToolbarView.textMessage = [NSString stringWithFormat:@"%@\n>%@\n\n", self.inputToolbarView.textMessage, selectedComponent.textMessage];
                                                                   
                                                                   // And display the keyboard
                                                                   [self.inputToolbarView becomeFirstResponder];
                                                               }
                                                               
                                                           }]];
        }
        
        if (level == 1)
        {
            [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_event_action_share", @"Vector", nil)
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               
                                                               if (weakSelf)
                                                               {
                                                                   typeof(self) self = weakSelf;
                                                                   
                                                                   [self cancelEventSelection];
                                                                   
                                                                   NSArray *activityItems = [NSArray arrayWithObjects:selectedComponent.textMessage, nil];
                                                                   
                                                                   UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
                                                                   
                                                                   if (activityViewController)
                                                                   {
                                                                       activityViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                                                                       activityViewController.popoverPresentationController.sourceView = roomBubbleTableViewCell;
                                                                       activityViewController.popoverPresentationController.sourceRect = roomBubbleTableViewCell.bounds;
                                                                       
                                                                       [self presentViewController:activityViewController animated:YES completion:nil];
                                                                   }
                                                               }
                                                               
                                                           }]];
        }
    }
    else // Add action for attachment
    {
        if (level == 0)
        {
            if (attachment.type == MXKAttachmentTypeImage || attachment.type == MXKAttachmentTypeVideo)
            {
                [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_event_action_save", @"Vector", nil)
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {
                                                                   
                                                                   if (weakSelf)
                                                                   {
                                                                       typeof(self) self = weakSelf;
                                                                       
                                                                       [self cancelEventSelection];
                                                                       
                                                                       [self startActivityIndicator];
                                                                       
                                                                       [attachment save:^{
                                                                           
                                                                           __strong __typeof(weakSelf)self = weakSelf;
                                                                           [self stopActivityIndicator];
                                                                           
                                                                       } failure:^(NSError *error) {
                                                                           
                                                                           __strong __typeof(weakSelf)self = weakSelf;
                                                                           [self stopActivityIndicator];
                                                                           
                                                                           //Alert user
                                                                           [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                                           
                                                                       }];
                                                                       
                                                                       // Start animation in case of download during attachment preparing
                                                                       [roomBubbleTableViewCell startProgressUI];
                                                                   }
                                                                   
                                                               }]];
            }
            
            if (attachment.type != MXKAttachmentTypeSticker)
            {
                [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_event_action_copy", @"Vector", nil)
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {
                                                                   
                                                                   if (weakSelf)
                                                                   {
                                                                       typeof(self) self = weakSelf;
                                                                       
                                                                       [self cancelEventSelection];
                                                                       
                                                                       [self startActivityIndicator];
                                                                       
                                                                       [attachment copy:^{
                                                                           
                                                                           __strong __typeof(weakSelf)self = weakSelf;
                                                                           [self stopActivityIndicator];
                                                                           
                                                                       } failure:^(NSError *error) {
                                                                           
                                                                           __strong __typeof(weakSelf)self = weakSelf;
                                                                           [self stopActivityIndicator];
                                                                           
                                                                           //Alert user
                                                                           [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                                           
                                                                       }];
                                                                       
                                                                       // Start animation in case of download during attachment preparing
                                                                       [roomBubbleTableViewCell startProgressUI];
                                                                   }
                                                                   
                                                               }]];
            }
            
            // Check status of the selected event
            if (selectedEvent.sentState == MXEventSentStatePreparing ||
                selectedEvent.sentState == MXEventSentStateEncrypting ||
                selectedEvent.sentState == MXEventSentStateUploading ||
                selectedEvent.sentState == MXEventSentStateSending)
            {
                // Upload id is stored in attachment url (nasty trick)
                NSString *uploadId = roomBubbleTableViewCell.bubbleData.attachment.actualURL;
                if ([MXMediaManager existingUploaderWithId:uploadId])
                {
                    [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_event_action_cancel_send", @"Vector", nil)
                                                                     style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * action) {

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
                                                                           typeof(self) self = weakSelf;
                                                                           
                                                                           self->currentAlert = nil;
                                                                           
                                                                           // Remove the outgoing message and its related cached file.
                                                                           [[NSFileManager defaultManager] removeItemAtPath:roomBubbleTableViewCell.bubbleData.attachment.cacheFilePath error:nil];
                                                                           [[NSFileManager defaultManager] removeItemAtPath:roomBubbleTableViewCell.bubbleData.attachment.cacheThumbnailPath error:nil];

                                                                           // Cancel and remove the outgoing message
                                                                           [self.roomDataSource.room cancelSendingOperation:selectedEvent.eventId];
                                                                           [self.roomDataSource removeEventWithEventId:selectedEvent.eventId];
                                                                           
                                                                           [self cancelEventSelection];
                                                                       }
                                                                       
                                                                   }]];
                }
            }
        }
        
        if (level == 1 && (attachment.type != MXKAttachmentTypeSticker))
        {
            [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_event_action_share", @"Vector", nil)
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               
                                                               if (weakSelf)
                                                               {
                                                                   typeof(self) self = weakSelf;
                                                                   
                                                                   [self cancelEventSelection];
                                                                   
                                                                   [attachment prepareShare:^(NSURL *fileURL) {
                                                                       
                                                                       __strong __typeof(weakSelf)self = weakSelf;
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
                                                                       
                                                                       //Alert user
                                                                       [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                                       
                                                                   }];
                                                                   
                                                                   // Start animation in case of download during attachment preparing
                                                                   [roomBubbleTableViewCell startProgressUI];
                                                               }
                                                               
                                                           }]];
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
                [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_event_action_cancel_download", @"Vector", nil)
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {
                                                                   
                                                                   if (weakSelf)
                                                                   {
                                                                       typeof(self) self = weakSelf;
                                                                       
                                                                       [self cancelEventSelection];
                                                                       
                                                                       // Get again the loader
                                                                       MXMediaLoader *loader = [MXMediaManager existingDownloaderWithOutputFilePath:cacheFilePath];
                                                                       if (loader)
                                                                       {
                                                                           [loader cancel];
                                                                       }
                                                                       // Hide the progress animation
                                                                       roomBubbleTableViewCell.progressView.hidden = YES;
                                                                   }
                                                                   
                                                               }]];
            }
        }
        
        if (level == 0)
        {
            // Do not allow to redact the event that enabled encryption (m.room.encryption)
            // because it breaks everything
            if (selectedEvent.eventType != MXEventTypeRoomEncryption)
            {
                [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_event_action_redact", @"Vector", nil)
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {
                                                                   
                                                                   if (weakSelf)
                                                                   {
                                                                       typeof(self) self = weakSelf;
                                                                       
                                                                       [self cancelEventSelection];
                                                                       
                                                                       [self startActivityIndicator];
                                                                       
                                                                       [self.roomDataSource.room redactEvent:selectedEvent.eventId reason:nil success:^{
                                                                           
                                                                           __strong __typeof(weakSelf)self = weakSelf;
                                                                           [self stopActivityIndicator];
                                                                           
                                                                       } failure:^(NSError *error) {
                                                                           
                                                                           __strong __typeof(weakSelf)self = weakSelf;
                                                                           [self stopActivityIndicator];
                                                                           
                                                                           NSLog(@"[RoomVC] Redact event (%@) failed", selectedEvent.eventId);
                                                                           //Alert user
                                                                           [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                                           
                                                                       }];
                                                                   }
                                                                   
                                                               }]];
            }
        }
        
        if (level == 1)
        {
            [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_event_action_permalink", @"Vector", nil)
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               
                                                               if (weakSelf)
                                                               {
                                                                   typeof(self) self = weakSelf;
                                                                   
                                                                   [self cancelEventSelection];
                                                                   
                                                                   // Create a matrix.to permalink that is common to all matrix clients
                                                                   NSString *permalink = [MXTools permalinkToEvent:selectedEvent.eventId inRoom:selectedEvent.roomId];
                                                                   
                                                                   // Create a room matrix.to permalink
                                                                   [[UIPasteboard generalPasteboard] setString:permalink];
                                                               }
                                                               
                                                           }]];
        }
        
        if (level == 1)
        {
            [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_event_action_view_source", @"Vector", nil)
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               
                                                               if (weakSelf)
                                                               {
                                                                   typeof(self) self = weakSelf;
                                                                   
                                                                   [self cancelEventSelection];
                                                                   
                                                                   // Display event details
                                                                   [self showEventDetails:selectedEvent];
                                                               }
                                                               
                                                           }]];
        }

        // Add "View Decrypted Source" for e2ee event we can decrypt
        if (level == 1 && selectedEvent.isEncrypted && selectedEvent.clearEvent)
        {
            [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_event_action_view_decrypted_source", @"Vector", nil)
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {

                                                               if (weakSelf)
                                                               {
                                                                   typeof(self) self = weakSelf;

                                                                   [self cancelEventSelection];

                                                                   // Display clear event details
                                                                   [self showEventDetails:selectedEvent.clearEvent];
                                                               }

                                                           }]];
        }
        
        if (level == 1)
        {
            [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_event_action_report", @"Vector", nil)
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               
                                                               if (weakSelf)
                                                               {
                                                                   typeof(self) self = weakSelf;
                                                                   
                                                                   [self cancelEventSelection];
                                                                   
                                                                   // Prompt user to enter a description of the problem content.
                                                                   self->currentAlert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"room_event_action_report_prompt_reason", @"Vector", nil)  message:nil preferredStyle:UIAlertControllerStyleAlert];
                                                                   
                                                                   [self->currentAlert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                                                                       textField.secureTextEntry = NO;
                                                                       textField.placeholder = nil;
                                                                       textField.keyboardType = UIKeyboardTypeDefault;
                                                                   }];
                                                                   
                                                                   [self->currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                                       
                                                                       if (weakSelf)
                                                                       {
                                                                           typeof(self) self = weakSelf;
                                                                           UITextField *textField = [self->currentAlert textFields].firstObject;
                                                                           self->currentAlert = nil;
                                                                           
                                                                           [self startActivityIndicator];
                                                                           
                                                                           [self.roomDataSource.room reportEvent:selectedEvent.eventId score:-100 reason:textField.text success:^{
                                                                               
                                                                               __strong __typeof(weakSelf)self = weakSelf;
                                                                               [self stopActivityIndicator];
                                                                               
                                                                               // Prompt user to ignore content from this user
                                                                               self->currentAlert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"room_event_action_report_prompt_ignore_user", @"Vector", nil)  message:nil preferredStyle:UIAlertControllerStyleAlert];
                                                                               
                                                                               [self->currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"yes"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                                                   
                                                                                   if (weakSelf)
                                                                                   {
                                                                                       typeof(self) self = weakSelf;
                                                                                       self->currentAlert = nil;
                                                                                       
                                                                                       [self startActivityIndicator];
                                                                                       
                                                                                       // Add the user to the blacklist: ignored users
                                                                                       [self.mainSession ignoreUsers:@[selectedEvent.sender] success:^{
                                                                                           
                                                                                           __strong __typeof(weakSelf)self = weakSelf;
                                                                                           [self stopActivityIndicator];
                                                                                           
                                                                                       } failure:^(NSError *error) {
                                                                                           
                                                                                           __strong __typeof(weakSelf)self = weakSelf;
                                                                                           [self stopActivityIndicator];
                                                                                           
                                                                                           NSLog(@"[RoomVC] Ignore user (%@) failed", selectedEvent.sender);
                                                                                           //Alert user
                                                                                           [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                                                           
                                                                                       }];
                                                                                   }
                                                                                   
                                                                               }]];
                                                                               
                                                                               [self->currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"no"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                                                   
                                                                                   if (weakSelf)
                                                                                   {
                                                                                       typeof(self) self = weakSelf;
                                                                                       self->currentAlert = nil;
                                                                                   }
                                                                                   
                                                                               }]];
                                                                               
                                                                               [self presentViewController:self->currentAlert animated:YES completion:nil];
                                                                               
                                                                           } failure:^(NSError *error) {
                                                                               
                                                                               __strong __typeof(weakSelf)self = weakSelf;
                                                                               [self stopActivityIndicator];
                                                                               
                                                                               NSLog(@"[RoomVC] Report event (%@) failed", selectedEvent.eventId);
                                                                               //Alert user
                                                                               [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                                               
                                                                           }];
                                                                       }
                                                                       
                                                                   }]];
                                                                   
                                                                   [self->currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"] style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
                                                                       
                                                                       if (weakSelf)
                                                                       {
                                                                           typeof(self) self = weakSelf;
                                                                           self->currentAlert = nil;
                                                                       }
                                                                       
                                                                   }]];
                                                                   
                                                                   [self presentViewController:self->currentAlert animated:YES completion:nil];
                                                               }
                                                               
                                                           }]];
        }
        
        if (level == 1 && self.roomDataSource.room.summary.isEncrypted)
        {
            [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_event_action_view_encryption", @"Vector", nil)
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               
                                                               if (weakSelf)
                                                               {
                                                                   typeof(self) self = weakSelf;
                                                                   [self cancelEventSelection];
                                                                   
                                                                   // Display encryption details
                                                                   [self showEncryptionInformation:selectedEvent];
                                                               }
                                                               
                                                           }]];
        }
        
        
        if (level == 0)
        {
            [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_event_action_more", @"Vector", nil)
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               
                                                               if (weakSelf)
                                                               {
                                                                   typeof(self) self = weakSelf;
                                                                   self->currentAlert = nil;
                                                                   
                                                                   // Show the next level of options
                                                                   [self showEditButtonAlertMenuForEvent:selectedEvent inCell:cell level:1];
                                                               }
                                                               
                                                           }]];
        }
    }
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"cancel", @"Vector", nil)
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           [self cancelEventSelection];
                                                       }
                                                       
                                                   }]];
    
    // Do not display empty action sheet
    if (currentAlert.actions.count > 1)
    {
        [currentAlert mxk_setAccessibilityIdentifier:@"RoomVCEventMenuAlert"];
        [currentAlert popoverPresentationController].sourceView = roomBubbleTableViewCell;
        [currentAlert popoverPresentationController].sourceRect = roomBubbleTableViewCell.bounds;
        [self presentViewController:currentAlert animated:YES completion:nil];
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
            
            MXRoomMember* member = [self.roomDataSource.roomState.members memberWithUserId:userId];
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
        // Preview the clicked group
        else if ([MXTools isMatrixGroupIdentifier:absoluteURLString])
        {
            shouldDoAction = NO;
            
            // Open the group or preview it
            NSString *fragment = [NSString stringWithFormat:@"/group/%@", [absoluteURLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            [[AppDelegate theDelegate] handleUniversalLinkFragment:fragment];
        }
        else if ([absoluteURLString hasPrefix:kEventFormatterOnReRequestKeysLinkAction])
        {
            NSArray<NSString*> *arguments = [absoluteURLString componentsSeparatedByString:kEventFormatterOnReRequestKeysLinkActionSeparator];
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
    }
    
    return shouldDoAction;
}

- (void)selectEventWithId:(NSString*)eventId
{
    BOOL shouldEnableReplyMode = [self.roomDataSource canReplyToEventWithId:eventId];;
    
    [self enableReplyMode:shouldEnableReplyMode];
    
    customizedRoomDataSource.selectedEventId = eventId;
}

- (void)cancelEventSelection
{
    [self enableReplyMode:NO];
    
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
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
            // @TODO (async-state): This call should be synchronous. Every thing will be fine
            __block MXKRoomDataSource *roomFilesDataSource;
            [MXKRoomDataSource loadRoomDataSourceWithRoomId:roomId andMatrixSession:session onComplete:^(id roomDataSource) {
                roomFilesDataSource = roomDataSource;
            }];
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
    else if ([[segue identifier] isEqualToString:@"showContactPicker"])
    {
        ContactsTableViewController *contactsPickerViewController = (ContactsTableViewController*)pushedViewController;
        
        // Set delegate to handle selected contact
        contactsPickerViewController.contactsTableViewControllerDelegate = self;
        
        // Prepare its data source
        ContactsDataSource *contactsDataSource = [[ContactsDataSource alloc] initWithMatrixSession:self.roomDataSource.mxSession];
        contactsDataSource.areSectionsShrinkable = YES;
        contactsDataSource.displaySearchInputInContactsList = YES;
        contactsDataSource.forceMatrixIdInDisplayName = YES;
        // Add a plus icon to the contact cell in the contacts picker, in order to make it more understandable for the end user.
        contactsDataSource.contactCellAccessoryImage = [UIImage imageNamed:@"plus_icon"];
        
        // List all the participants matrix user id to ignore them during the contacts search.
        NSArray *members = [self.roomDataSource.roomState.members membersWithoutConferenceUser];
        for (MXRoomMember *mxMember in members)
        {
            // Check his status
            if (mxMember.membership == MXMembershipJoin || mxMember.membership == MXMembershipInvite)
            {
                // Create the contact related to this member
                MXKContact *contact = [[MXKContact alloc] initMatrixContactWithDisplayName:mxMember.displayname andMatrixID:mxMember.userId];
                [contactsDataSource.ignoredContactsByMatrixId setObject:contact forKey:mxMember.userId];
            }
        }

        [contactsPickerViewController showSearch:YES];
        contactsPickerViewController.searchBar.placeholder = NSLocalizedStringFromTable(@"room_participants_invite_another_user", @"Vector", nil);
        
        [contactsPickerViewController displayList:contactsDataSource];
    }
    
    // Hide back button title
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
}

#pragma mark - RoomInputToolbarViewDelegate

- (void)roomInputToolbarViewPresentStickerPicker:(MXKRoomInputToolbarView*)toolbarView
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

            NSLog(@"[RoomVC] Cannot display widget %@", widget);
            [[AppDelegate theDelegate] showErrorAsAlert:error];
        }];
    }
    else
    {
        // The Sticker picker widget is not installed yet. Propose the user to install it
        __weak typeof(self) weakSelf = self;

        [currentAlert dismissViewControllerAnimated:NO completion:nil];

        NSString *alertMessage = [NSString stringWithFormat:@"%@\n%@",
                                  NSLocalizedStringFromTable(@"widget_sticker_picker_no_stickerpacks_alert", @"Vector", nil),
                                  NSLocalizedStringFromTable(@"widget_sticker_picker_no_stickerpacks_alert_add_now", @"Vector", nil)
                                  ];

        currentAlert = [UIAlertController alertControllerWithTitle:nil message:alertMessage preferredStyle:UIAlertControllerStyleAlert];

        [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"no"]
                                                         style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction * action)
        {
            if (weakSelf)
            {
                typeof(self) self = weakSelf;
                self->currentAlert = nil;
            }

        }]];

        [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"yes"]
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action)
        {
            if (weakSelf)
            {
                typeof(self) self = weakSelf;
                self->currentAlert = nil;

                // Show the sticker picker settings screen
                IntegrationManagerViewController *modularVC = [[IntegrationManagerViewController alloc]
                                                               initForMXSession:self.roomDataSource.mxSession
                                                               inRoom:self.roomDataSource.roomId
                                                               screen:[IntegrationManagerViewController screenForWidget:kWidgetTypeStickerPicker]
                                                               widgetId:nil];

                [self presentViewController:modularVC animated:NO completion:nil];
            }
        }]];

        [currentAlert mxk_setAccessibilityIdentifier:@"RoomVCStickerPickerAlert"];
        [self presentViewController:currentAlert animated:YES completion:nil];
    }
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

- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView placeCallWithVideo:(BOOL)video
{
    __weak __typeof(self) weakSelf = self;

    NSString *appDisplayName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];

    // Check app permissions first
    [MXKTools checkAccessForCall:video
     manualChangeMessageForAudio:[NSString stringWithFormat:[NSBundle mxk_localizedStringForKey:@"microphone_access_not_granted_for_call"], appDisplayName]
     manualChangeMessageForVideo:[NSString stringWithFormat:[NSBundle mxk_localizedStringForKey:@"camera_access_not_granted_for_call"], appDisplayName]
       showPopUpInViewController:self completionHandler:^(BOOL granted) {

           if (weakSelf)
           {
               typeof(self) self = weakSelf;

               if (granted)
               {
                   [self roomInputToolbarView:toolbarView placeCallWithVideo2:video];
               }
               else
               {
                   NSLog(@"RoomViewController: Warning: The application does not have the perssion to place the call");
               }
           }
       }];
}

- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView placeCallWithVideo2:(BOOL)video
{
     __weak __typeof(self) weakSelf = self;

    // If there is already a jitsi widget, join it
    Widget *jitsiWidget = [customizedRoomDataSource jitsiWidget];
    if (jitsiWidget)
    {
        [[AppDelegate theDelegate] displayJitsiViewControllerWithWidget:jitsiWidget andVideo:video];
    }

    // If enabled, create the conf using jitsi widget and open it directly
    else if (RiotSettings.shared.createConferenceCallsWithJitsi
             && self.roomDataSource.room.summary.membersCount.joined > 2)
    {
        [self startActivityIndicator];

        [[WidgetManager sharedManager] createJitsiWidgetInRoom:self.roomDataSource.room
                                                     withVideo:video
                                                       success:^(Widget *jitsiWidget)
         {
             if (weakSelf)
             {
                 typeof(self) self = weakSelf;
                 [self stopActivityIndicator];

                 [[AppDelegate theDelegate] displayJitsiViewControllerWithWidget:jitsiWidget andVideo:video];
             }
         }
                                                       failure:^(NSError *error)
         {
             if (weakSelf)
             {
                 typeof(self) self = weakSelf;
                 [self stopActivityIndicator];

                 [self showJitsiErrorAsAlert:error];
             }
         }];
    }
    // Classic conference call is not supported in encrypted rooms
    else if (self.roomDataSource.room.summary.isEncrypted && self.roomDataSource.room.summary.membersCount.joined > 2)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];

        currentAlert = [UIAlertController alertControllerWithTitle:[NSBundle mxk_localizedStringForKey:@"room_no_conference_call_in_encrypted_rooms"]  message:nil preferredStyle:UIAlertControllerStyleAlert];

        [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"]
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action)
                                 {
                                     if (weakSelf)
                                     {
                                         typeof(self) self = weakSelf;
                                         self->currentAlert = nil;
                                     }

                                 }]];

        [currentAlert mxk_setAccessibilityIdentifier:@"RoomVCCallAlert"];
        [self presentViewController:currentAlert animated:YES completion:nil];
    }

    // In case of conference call, check that the user has enough power level
    else if (self.roomDataSource.room.summary.membersCount.joined > 2 &&
             ![MXCallManager canPlaceConferenceCallInRoom:self.roomDataSource.room roomState:self.roomDataSource.roomState])
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];

        currentAlert = [UIAlertController alertControllerWithTitle:[NSBundle mxk_localizedStringForKey:@"room_no_power_to_create_conference_call"]  message:nil preferredStyle:UIAlertControllerStyleAlert];

        [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"]
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action)
                                 {
                                     if (weakSelf)
                                     {
                                         typeof(self) self = weakSelf;
                                         self->currentAlert = nil;
                                     }
                                 }]];

        [currentAlert mxk_setAccessibilityIdentifier:@"RoomVCCallAlert"];
        [self presentViewController:currentAlert animated:YES completion:nil];
    }

    // Classic 1:1 or group call can be done
    else
    {
        [self.roomDataSource.room placeCallWithVideo:video success:nil failure:nil];
    }
}

- (void)roomInputToolbarViewHangupCall:(MXKRoomInputToolbarView *)toolbarView
{
    MXCall *callInRoom = [self.roomDataSource.mxSession.callManager callInRoom:self.roomDataSource.roomId];
    if (callInRoom)
    {
        [callInRoom hangup];
    }
    else if ([[AppDelegate theDelegate].jitsiViewController.widget.roomId isEqualToString:self.roomDataSource.roomId])
    {
        [[AppDelegate theDelegate].jitsiViewController hangup];
    }

    [self refreshActivitiesViewDisplay];
    [self refreshRoomInputToolbar];
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
                toolbarView.placeholder =  savedInputToolbarPlaceholder.length ? savedInputToolbarPlaceholder : nil;
            }
            savedInputToolbarPlaceholder = nil;
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
    // Search button
    if (sender == self.navigationItem.rightBarButtonItem)
    {
        [self performSegueWithIdentifier:@"showRoomSearch" sender:self];
    }
    // Matrix Apps button
    else if (self.navigationItem.rightBarButtonItems.count == 2 && sender == self.navigationItem.rightBarButtonItems[1])
    {
        if ([self widgetsCount:NO])
        {
            WidgetPickerViewController *widgetPicker = [[WidgetPickerViewController alloc] initForMXSession:self.roomDataSource.mxSession
                                                                                                     inRoom:self.roomDataSource.roomId];

            [widgetPicker showInViewController:self];
        }
        else
        {
            // No widgets -> Directly show the integration manager
            IntegrationManagerViewController *modularVC = [[IntegrationManagerViewController alloc] initForMXSession:self.roomDataSource.mxSession
                                                                                                              inRoom:self.roomDataSource.roomId
                                                                                                              screen:kIntegrationManagerMainScreen
                                                                                                            widgetId:nil];

            [self presentViewController:modularVC animated:NO completion:nil];
        }
    }
    else if (sender == self.jumpToLastUnreadButton)
    {
        // Hide expanded header to restore navigation bar settings.
        [self showExpandedHeader:NO];
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
    cell.backgroundColor = kRiotPrimaryBgColor;
    
    // Update the selected background view
    if (kRiotSelectedBgColor)
    {
        cell.selectedBackgroundView = [[UIView alloc] init];
        cell.selectedBackgroundView.backgroundColor = kRiotSelectedBgColor;
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
        CGFloat contentBottomPosY = self.bubblesTableView.contentOffset.y + self.bubblesTableView.frame.size.height - self.bubblesTableView.mxk_adjustedContentInset.bottom;
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
                else
                {
                    CGRect roomAvatarFrame = expandedHeader.roomAvatar.frame;
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
    else if (tappedView == titleView.addParticipantMask)
    {
        // Open contact picker
        [self performSegueWithIdentifier:@"showContactPicker" sender:self];
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
                NSLog(@"[RoomVC] Failed to reject an invited room (%@) failed", self.roomDataSource.room.roomId);
                
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
            
            MXRoomMember* member = [self.roomDataSource.roomState.members memberWithUserId:name];
            
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
    kMXKWidgetManagerDidUpdateWidgetObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kWidgetManagerDidUpdateWidgetNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {

        Widget *widget = notif.object;
        if (widget.mxSession == self.roomDataSource.mxSession
            && [widget.roomId isEqualToString:customizedRoomDataSource.roomId])
        {
            // Jitsi conference widget existence is shown in the bottom bar
            // Update the bar
            [self refreshActivitiesViewDisplay];
            [self refreshRoomInputToolbar];
            [self refreshRoomTitle];
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
                                           NSLocalizedDescriptionKey: NSLocalizedStringFromTable(@"room_conference_call_no_power", @"Vector", nil)
                                           }];
    }

    // Alert user
    [[AppDelegate theDelegate] showErrorAsAlert:error];
}

- (NSUInteger)widgetsCount:(BOOL)includeUserWidgets
{
    NSUInteger widgetsCount = [[WidgetManager sharedManager] widgetsNotOfTypes:@[kWidgetTypeJitsi]
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

        Widget *jitsiWidget = [customizedRoomDataSource jitsiWidget];
        
        if ([AppDelegate theDelegate].isOffline)
        {
            [roomActivitiesView displayNetworkErrorNotification:NSLocalizedStringFromTable(@"room_offline_notification", @"Vector", nil)];
        }
        else if (customizedRoomDataSource.roomState.isObsolete)
        {
            NSString *replacementRoomId = customizedRoomDataSource.roomState.tombStoneContent.replacementRoomId;
            NSString *roomLinkFragment = [NSString stringWithFormat:@"/room/%@", [replacementRoomId stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            
            [roomActivitiesView displayRoomReplacementWithRoomLinkTappedHandler:^{
                [[AppDelegate theDelegate] handleUniversalLinkFragment:roomLinkFragment];
            }];
        }
        else if (customizedRoomDataSource.roomState.isOngoingConferenceCall)
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
                    
                    NSLog(@"[RoomVC] onOngoingConferenceCallPressed");
                    
                    // Make sure there is not yet a call
                    if (![customizedRoomDataSource.mxSession.callManager callInRoom:customizedRoomDataSource.roomId])
                    {
                        [customizedRoomDataSource.room placeCallWithVideo:video success:nil failure:nil];
                    }
                } onClosePressed:nil];
            }
        }
        else if (jitsiWidget)
        {
            // The room has an active jitsi widget
            // Show it in the banner if the user is not already in
            AppDelegate *appDelegate = [AppDelegate theDelegate];
            if ([appDelegate.jitsiViewController.widget.widgetId isEqualToString:jitsiWidget.widgetId])
            {
                if ([self checkUnsentMessages] == NO)
                {
                    [self refreshTypingNotification];
                }
            }
            else
            {
                [roomActivitiesView displayOngoingConferenceCall:^(BOOL video) {

                    NSLog(@"[RoomVC] onOngoingConferenceCallPressed (jitsi)");

                    __weak __typeof(self) weakSelf = self;
                    NSString *appDisplayName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];

                    // Check app permissions first
                    [MXKTools checkAccessForCall:video
                     manualChangeMessageForAudio:[NSString stringWithFormat:[NSBundle mxk_localizedStringForKey:@"microphone_access_not_granted_for_call"], appDisplayName]
                     manualChangeMessageForVideo:[NSString stringWithFormat:[NSBundle mxk_localizedStringForKey:@"camera_access_not_granted_for_call"], appDisplayName]
                       showPopUpInViewController:self completionHandler:^(BOOL granted) {

                           if (weakSelf)
                           {
                               if (granted)
                               {
                                   // Present the Jitsi view controller
                                   [appDelegate displayJitsiViewControllerWithWidget:jitsiWidget andVideo:video];
                               }
                               else
                               {
                                   NSLog(@"[RoomVC] onOngoingConferenceCallPressed: Warning: The application does not have the perssion to join the call");
                               }
                           }
                       }];

                } onClosePressed:^{

                    [self startActivityIndicator];

                    // Close the widget
                    __weak __typeof(self) weakSelf = self;
                    [[WidgetManager sharedManager] closeWidget:jitsiWidget.widgetId inRoom:self.roomDataSource.room success:^{

                        if (weakSelf)
                        {
                            typeof(self) self = weakSelf;
                            [self stopActivityIndicator];

                            // The banner will automatically leave thanks to kWidgetManagerDidUpdateWidgetNotification
                        }

                    } failure:^(NSError *error) {
                        if (weakSelf)
                        {
                            typeof(self) self = weakSelf;

                            [self showJitsiErrorAsAlert:error];
                            [self stopActivityIndicator];
                        }
                    }];
                }];
            }
        }
        else if ([self checkUnsentMessages] == NO)
        {
            // Show "scroll to bottom" icon when the most recent message is not visible,
            // or when the timelime is not live (this icon is used to go back to live).
            // Note: we check if `currentEventIdAtTableBottom` is set to know whether the table has been rendered at least once.
            if (!self.roomDataSource.isLive || (currentEventIdAtTableBottom && [self isBubblesTableScrollViewAtTheBottom] == NO))
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
                    
                    [self goBackToLive];
                    
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
            
            if ([GBDeviceInfo deviceInfo].osVersion.major < 11)
            {
                // Consider the main navigation controller if the current view controller is embedded inside a split view controller.
                UINavigationController *mainNavigationController = self.navigationController;
                if (self.splitViewController.isCollapsed && self.splitViewController.viewControllers.count)
                {
                    mainNavigationController = self.splitViewController.viewControllers.firstObject;
                }
                UINavigationItem *backItem = mainNavigationController.navigationBar.backItem;
                UIBarButtonItem *backButton = backItem.backBarButtonItem;
                
                if (backButton && !backButton.title.length)
                {
                    // Shift the badge on the left to be close the back icon
                    frame.origin.x = ([GBDeviceInfo deviceInfo].displayInfo.display > GBDeviceDisplay4Inch ? -35 : -25);
                }
                else
                {
                    frame.origin.x = 0;
                }
            }
            
            // Caution: set label background view frame only in case of changes to prevent from looping on 'viewDidLayoutSubviews'.
            if (!CGRectEqualToRect(missedDiscussionsBadgeLabelBgView.frame, frame))
            {
                missedDiscussionsBadgeLabelBgView.frame = frame;
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
                    [currentAlert dismissViewControllerAnimated:NO completion:nil];
                }
                
                __weak __typeof(self) weakSelf = self;
                currentAlert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
                
                [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_resend_unsent_messages", @"Vector", nil)
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {
                                                                   
                                                                   if (weakSelf)
                                                                   {
                                                                       typeof(self) self = weakSelf;
                                                                       [self resendAllUnsentMessages];
                                                                       self->currentAlert = nil;
                                                                   }
                                                                   
                                                               }]];
                
                [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_delete_unsent_messages", @"Vector", nil)
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {
                                                                   
                                                                   if (weakSelf)
                                                                   {
                                                                       typeof(self) self = weakSelf;
                                                                       [self cancelAllUnsentMessages];
                                                                       self->currentAlert = nil;
                                                                   }
                                                                   
                                                               }]];
                
                [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"cancel", @"Vector", nil)
                                                                 style:UIAlertActionStyleCancel
                                                               handler:^(UIAlertAction * action) {
                                                                   
                                                                   if (weakSelf)
                                                                   {
                                                                       typeof(self) self = weakSelf;
                                                                       self->currentAlert = nil;
                                                                   }
                                                                   
                                                               }]];
                
                [currentAlert mxk_setAccessibilityIdentifier:@"RoomVCUnsentMessagesMenuAlert"];
                [currentAlert popoverPresentationController].sourceView = roomActivitiesView;
                [currentAlert popoverPresentationController].sourceRect = roomActivitiesView.bounds;
                [self presentViewController:currentAlert animated:YES completion:nil];
                
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
        
        currentAlert = [UIAlertController alertControllerWithTitle:[NSBundle mxk_localizedStringForKey:@"unknown_devices_alert_title"]
                                                           message:[NSBundle mxk_localizedStringForKey:@"unknown_devices_alert"]
                                                    preferredStyle:UIAlertControllerStyleAlert];
        
        [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"unknown_devices_verify"]
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {
                                                           
                                                           if (weakSelf)
                                                           {
                                                               typeof(self) self = weakSelf;
                                                               self->currentAlert = nil;
                                                               
                                                               [self performSegueWithIdentifier:@"showUnknownDevices" sender:self];
                                                           }
                                                           
                                                       }]];
        
        [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"unknown_devices_send_anyway"]
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
        
        [currentAlert mxk_setAccessibilityIdentifier:@"RoomVCUnknownDevicesAlert"];
        [self presentViewController:currentAlert animated:YES completion:nil];
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



#pragma mark - Read marker handling

- (void)checkReadMarkerVisibility
{
    if (readMarkerTableViewCell && isAppeared && !self.isBubbleTableViewDisplayInTransition)
    {
        // Check whether the read marker is visible
        CGFloat contentTopPosY = self.bubblesTableView.contentOffset.y + self.bubblesTableView.mxk_adjustedContentInset.top;
        CGFloat readMarkerViewPosY = readMarkerTableViewCell.frame.origin.y + readMarkerTableViewCell.readMarkerView.frame.origin.y;
        if (contentTopPosY <= readMarkerViewPosY)
        {
            // Compute the max vertical position visible according to contentOffset
            CGFloat contentBottomPosY = self.bubblesTableView.contentOffset.y + self.bubblesTableView.frame.size.height - self.bubblesTableView.mxk_adjustedContentInset.bottom;
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
                CGFloat contentTopPosY = self.bubblesTableView.contentOffset.y + self.bubblesTableView.mxk_adjustedContentInset.top;
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
    NSString *promptMsg = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_participants_invite_prompt_msg", @"Vector", nil), contact.displayName];
    currentAlert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"room_participants_invite_prompt_title", @"Vector", nil)
                                                       message:promptMsg
                                                preferredStyle:UIAlertControllerStyleAlert];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           self->currentAlert = nil;
                                                       }
                                                       
                                                   }]];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"invite", @"Vector", nil)
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
                                                               
                                                               NSLog(@"[RoomVC] Invite %@ failed", participantId);
                                                               // Alert user
                                                               [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                               
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
                                                                   
                                                                   NSLog(@"[RoomVC] Invite be email %@ failed", participantId);
                                                                   // Alert user
                                                                   [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                                   
                                                               }];
                                                           }
                                                           else //if ([MXTools isMatrixUserIdentifier:participantId])
                                                           {
                                                               [room inviteUser:participantId success:^{
                                                                   
                                                                   // Refresh display by removing the contacts picker
                                                                   [contactsTableViewController withdrawViewControllerAnimated:YES completion:nil];
                                                                   
                                                               } failure:^(NSError *error) {
                                                                   
                                                                   NSLog(@"[RoomVC] Invite %@ failed", participantId);
                                                                   // Alert user
                                                                   [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                                   
                                                               }];
                                                           }
                                                       }
                                                       
                                                   }]];
    
    [currentAlert mxk_setAccessibilityIdentifier:@"RoomVCInviteAlert"];
    [self presentViewController:currentAlert animated:YES completion:nil];
}

#pragma mark - Re-request encryption keys

- (void)reRequestKeysAndShowExplanationAlert:(MXEvent*)event
{
    MXWeakify(self);
    __block UIAlertController *alert;

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
    alert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"rerequest_keys_alert_title", @"Vector", nil)
                                                       message:NSLocalizedStringFromTable(@"rerequest_keys_alert_message", @"Vector", nil)
                                                preferredStyle:UIAlertControllerStyleAlert];
    currentAlert = alert;


    [alert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"]
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action)
                             {
                                 MXStrongifyAndReturnIfNil(self);

                                 [[NSNotificationCenter defaultCenter] removeObserver:self->mxEventDidDecryptNotificationObserver];
                                 self->mxEventDidDecryptNotificationObserver = nil;

                                 self->currentAlert = nil;
                             }]];

    [self presentViewController:currentAlert animated:YES completion:nil];
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
        [self setRoomInputToolbarViewClass];
        [self updateInputToolBarViewHeight];
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

@end

