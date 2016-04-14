/*
 Copyright 2014 OpenMarket Ltd
 
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

#import "VectorDesignValues.h"

#import "RageShakeManager.h"

#import "RoomInputToolbarView.h"

#import "RoomActivitiesView.h"

#import "RoomAvatarTitleView.h"
#import "ExpandedRoomTitleView.h"
#import "SimpleRoomTitleView.h"
#import "PreviewRoomTitleView.h"

#import "RoomParticipantsViewController.h"

#import "SegmentedViewController.h"
#import "RoomSettingsViewController.h"
#import "RoomSearchViewController.h"

#import "RoomIncomingTextMsgBubbleCell.h"
#import "RoomIncomingTextMsgWithoutSenderInfoBubbleCell.h"
#import "RoomIncomingTextMsgWithPaginationTitleBubbleCell.h"
#import "RoomIncomingTextMsgWithoutSenderNameBubbleCell.h"
#import "RoomIncomingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.h"
#import "RoomIncomingAttachmentBubbleCell.h"
#import "RoomIncomingAttachmentWithoutSenderInfoBubbleCell.h"
#import "RoomIncomingAttachmentWithPaginationTitleBubbleCell.h"

#import "RoomOutgoingTextMsgBubbleCell.h"
#import "RoomOutgoingTextMsgWithoutSenderInfoBubbleCell.h"
#import "RoomOutgoingTextMsgWithPaginationTitleBubbleCell.h"
#import "RoomOutgoingTextMsgWithoutSenderNameBubbleCell.h"
#import "RoomOutgoingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.h"
#import "RoomOutgoingAttachmentBubbleCell.h"
#import "RoomOutgoingAttachmentWithoutSenderInfoBubbleCell.h"
#import "RoomOutgoingAttachmentWithPaginationTitleBubbleCell.h"

#import "MXKRoomBubbleTableViewCell+Vector.h"

#import "AvatarGenerator.h"

#import "VectorDesignValues.h"

@interface RoomViewController ()
{
    // The expanded header
    ExpandedRoomTitleView *expandedHeader;
    
    // The preview header
    PreviewRoomTitleView *previewHeader;
    
    // The content offset at the beginning of scrolling
    CGFloat storedContentOffset;
    
    // The customized room data source for Vector
    RoomDataSource *customizedRoomDataSource;
    
    // the user taps on a member thumbnail
    MXRoomMember *selectedRoomMember;

    // List of members who are typing in the room.
    NSArray *currentTypingUsers;
    
    // Typing notifications listener.
    id typingNotifListener;
    
    // The first tab is selected by default in room details screen in of case 'showRoomDetails' segue.
    // Use this flag to select a specific tab (0: people, 1: settings).
    NSUInteger selectedRoomDetailsIndex;
    
    // The room invitation received by email
    RoomEmailInvitation *roomEmailInvitation;
}

@property (strong, nonatomic) MXKAlert *currentAlert;

@end

@implementation RoomViewController

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
    }
    
    return self;
}

#pragma mark -

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.defaultBarTintColor = kVectorNavBarTintColor;
    self.enableBarTintColorStatusChange = NO;
    
    // Register first customized cell view classes used to render bubbles
    [self.bubblesTableView registerClass:RoomIncomingTextMsgBubbleCell.class forCellReuseIdentifier:RoomIncomingTextMsgBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomIncomingTextMsgWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:RoomIncomingTextMsgWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomIncomingTextMsgWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomIncomingTextMsgWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomIncomingAttachmentBubbleCell.class forCellReuseIdentifier:RoomIncomingAttachmentBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomIncomingAttachmentWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:RoomIncomingAttachmentWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomIncomingAttachmentWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomIncomingAttachmentWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomIncomingTextMsgWithoutSenderNameBubbleCell.class forCellReuseIdentifier:RoomIncomingTextMsgWithoutSenderNameBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomIncomingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.class forCellReuseIdentifier:RoomIncomingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.defaultReuseIdentifier];
    
    [self.bubblesTableView registerClass:RoomOutgoingAttachmentBubbleCell.class forCellReuseIdentifier:RoomOutgoingAttachmentBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomOutgoingAttachmentWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:RoomOutgoingAttachmentWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomOutgoingAttachmentWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomOutgoingAttachmentWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomOutgoingTextMsgBubbleCell.class forCellReuseIdentifier:RoomOutgoingTextMsgBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomOutgoingTextMsgWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:RoomOutgoingTextMsgWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomOutgoingTextMsgWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomOutgoingTextMsgWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomOutgoingTextMsgWithoutSenderNameBubbleCell.class forCellReuseIdentifier:RoomOutgoingTextMsgWithoutSenderNameBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomOutgoingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.class forCellReuseIdentifier:RoomOutgoingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.defaultReuseIdentifier];
    
    // Prepare expanded header
    self.expandedHeaderContainer.backgroundColor = kVectorColorLightGrey;
    self.expandedHeaderContainerHeightConstraint.constant = 237;
    
    expandedHeader = [ExpandedRoomTitleView roomTitleView];
    expandedHeader.delegate = self;
    expandedHeader.tapGestureDelegate = self;
    expandedHeader.translatesAutoresizingMaskIntoConstraints = NO;
    [self.expandedHeaderContainer addSubview:expandedHeader];
    // Force expanded header in full width
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
    // Vertical constraints are required for iOS > 8
    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:expandedHeader
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.expandedHeaderContainer
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:0];
    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:expandedHeader
                                                                        attribute:NSLayoutAttributeBottom
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self.expandedHeaderContainer
                                                                        attribute:NSLayoutAttributeBottom
                                                                       multiplier:1.0
                                                                         constant:0];
    
    [NSLayoutConstraint activateConstraints:@[leftConstraint, rightConstraint, topConstraint, bottomConstraint]];
    
    // Prepare preview header container
    self.previewHeaderContainer.backgroundColor = kVectorColorLightGrey;
    self.previewHeaderContainerHeightConstraint.constant = 368;
    
    // Replace the default input toolbar view.
    // Note: this operation will force the layout of subviews. That is why cell view classes must be registered before.
    [self setRoomInputToolbarViewClass:RoomInputToolbarView.class];
    
    // Disable animation during the update of the inputToolBar height.
    [UIView setAnimationsEnabled:NO];
    [self roomInputToolbarView:self.inputToolbarView heightDidChanged:((RoomInputToolbarView*)self.inputToolbarView).mainToolbarMinHeightConstraint.constant completion:nil];
    [UIView setAnimationsEnabled:YES];
    
    // set extra area
    [self setRoomActivitiesViewClass:RoomActivitiesView.class];
    
    // Set rageShake handler
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    // Update navigation bar items
    self.navigationItem.rightBarButtonItem.target = self;
    self.navigationItem.rightBarButtonItem.action = @selector(onButtonPressed:);
    
    // Handle potential data source
    if (self.roomDataSource)
    {
        // Set room title view
        [self refreshRoomTitle];
        
        [self refreshRoomInputToolbar];
    }
    else
    {
        self.navigationItem.rightBarButtonItem.enabled = NO;
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
    
    [self listenTypingNotifications];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // hide action
    if (self.currentAlert)
    {
        [self.currentAlert dismiss:NO];
        self.currentAlert = nil;
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
}

- (void)viewDidAppear:(BOOL)animated
{
    if (self.childViewControllers)
    {
        // Dispose data source defined for room member list view controller (if any)
        for (id childViewController in self.childViewControllers)
        {
            if ([childViewController isKindOfClass:[MXKRoomMemberListViewController class]])
            {
                MXKRoomMemberListViewController *viewController = (MXKRoomMemberListViewController*)childViewController;
                MXKDataSource *dataSource = [viewController dataSource];
                [viewController destroy];
                [dataSource destroy];
            }
        }
    }
    
    [super viewDidAppear:animated];
    
    if (self.roomDataSource)
    {
        // Set visible room id
        [AppDelegate theDelegate].visibleRoomId = self.roomDataSource.roomId;
        
        // Observe network reachability
        [[AppDelegate theDelegate]  addObserver:self forKeyPath:@"isOffline" options:0 context:nil];
        [self refreshActivitiesViewDisplay];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // Reset visible room id
    if ([AppDelegate theDelegate].visibleRoomId)
    {
        [AppDelegate theDelegate].visibleRoomId = nil;
        
        [[AppDelegate theDelegate] removeObserver:self forKeyPath:@"isOffline"];
    }
}

- (void)viewDidLayoutSubviews
{
    UIEdgeInsets contentInset = self.bubblesTableView.contentInset;
    contentInset.bottom = self.bottomLayoutGuide.length;
    self.bubblesTableView.contentInset = contentInset;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    // Hide expanded header on device rotation
    [self showExpandedHeader:NO];
    
    // Hide preview header (if any) during device rotation
    BOOL isPreview = !self.previewHeaderContainer.isHidden;
    if (isPreview)
    {
        [self showPreviewHeader:NO];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((coordinator.transitionDuration + 0.5) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            [self showPreviewHeader:YES];
        });
    }
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

#pragma mark - Override MXKRoomViewController

- (void)displayRoom:(MXKRoomDataSource *)dataSource
{
    [super displayRoom:dataSource];
    
    customizedRoomDataSource = nil;
    
    if (self.roomDataSource)
    {
        // This room view controller has its own typing management.
        self.roomDataSource.showTypingNotifications = NO;

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
        
        // Hide input tool bar and activity view. FIXME: These items should be removed instead of being hidden until they will be used for preview.
        self.inputToolbarView.hidden = YES;
        self.activitiesView.hidden = YES;
        
        previewHeader.mxRoom = self.roomDataSource.room;
    }
    else
    {
        [self showPreviewHeader:NO];
        
        self.navigationItem.rightBarButtonItem.enabled = (self.roomDataSource != nil);
        
        self.titleView.editable = NO;
        
        expandedHeader.mxRoom = self.roomDataSource.room;
    }
}

- (BOOL)isIRCStyleCommand:(NSString*)string
{
    // Override the default behavior for `/join` command in order to open automatically the joined room
    
    if ([string hasPrefix:kCmdJoinRoom])
    {
        // Join a room
        NSString *roomAlias = [string substringFromIndex:kCmdJoinRoom.length + 1];
        // Remove white space from both ends
        roomAlias = [roomAlias stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        // Check
        if (roomAlias.length)
        {
            [self.mainSession joinRoom:roomAlias success:^(MXRoom *room)
             {
                 // Show the room
                 [[AppDelegate theDelegate] showRoom:room.state.roomId andEventId:nil withMatrixSession:self.mainSession];
             } failure:^(NSError *error)
             {
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

- (void)destroy
{
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    if (self.currentAlert)
    {
        [self.currentAlert dismiss:NO];
        self.currentAlert = nil;
    }
    
    if (customizedRoomDataSource)
    {
        customizedRoomDataSource.selectedEventId = nil;
        customizedRoomDataSource = nil;
    }
    
    if (expandedHeader)
    {
        [expandedHeader removeFromSuperview];
        expandedHeader = nil;
    }
    
    if (previewHeader)
    {
        [previewHeader removeFromSuperview];
        previewHeader = nil;
    }
    
    [super destroy];
}

#pragma mark - Internals

- (BOOL)isRoomPreview
{
    if (self.roomDataSource && self.roomDataSource.state == MXKDataSourceStateReady && self.roomDataSource.room.state.membership == MXMembershipInvite)
    {
        return YES;
    }
    
    if (roomEmailInvitation)
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
            
            [self setRoomTitleViewClass:RoomTitleView.class];
            ((RoomTitleView*)self.titleView).tapGestureDelegate = self;
        }
        else
        {
            // Hide the search button
            self.navigationItem.rightBarButtonItem = nil;
            
            [self setRoomTitleViewClass:SimpleRoomTitleView.class];
            self.titleView.editable = NO;
        }
    }
}

- (void)refreshRoomInputToolbar
{
    // Check whether the input toolbar is ready before updating it.
    if (self.inputToolbarView && [self.inputToolbarView isKindOfClass:RoomInputToolbarView.class])
    {
        RoomInputToolbarView *roomInputToolbarView = (RoomInputToolbarView*)self.inputToolbarView;
        
        // Check whether the call option is supported
        roomInputToolbarView.supportCallOption = (self.roomDataSource.mxSession.callManager != nil);
        
        // Set user picture in input toolbar
        MXKImageView *userPictureView = roomInputToolbarView.pictureView;
        if (userPictureView)
        {
            UIImage *preview = [AvatarGenerator generateRoomMemberAvatar:self.mainSession.myUser.userId displayName:self.mainSession.myUser.displayname];
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
}

#pragma mark - Hide/Show expanded header

- (void)showExpandedHeader:(BOOL)isVisible
{
    // Check conditions before applying change on room header.
    // This operation is ignored:
    // - if a screen rotation is in progress.
    // - if the room data source has been removed.
    // - if the room data source does not manage a live timeline.
    // - if the user's membership is not 'join'.
    if (self.expandedHeaderContainer.isHidden == isVisible && isSizeTransitionInProgress == NO && self.roomDataSource && self.roomDataSource.isLive && self.roomDataSource.room.state.membership == MXMembershipJoin)
    {
        self.expandedHeaderContainer.hidden = !isVisible;
        
        // Consider the main navigation controller if the current view controller is embedded inside a split view controller.
        UINavigationController *mainNavigationController = self.navigationController;
        if (self.splitViewController && self.splitViewController.isCollapsed && self.splitViewController.viewControllers.count)
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
                             [self.view layoutIfNeeded];
                         }
                         completion:^(BOOL finished){
                         }];
    }
}

#pragma mark - Hide/Show preview header

- (void)showPreviewHeader:(BOOL)isVisible
{
    // Check conditions before applying change on room header.
    // This operation is ignored when a screen rotation is in progress.
    if (self.previewHeaderContainer.isHidden == isVisible && isSizeTransitionInProgress == NO)
    {
        if (isVisible && !previewHeader)
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
            
            if (self.roomDataSource)
            {
                previewHeader.mxRoom = self.roomDataSource.room;
            }
            else
            {
                previewHeader.emailInvitation = roomEmailInvitation;
            }
        }
        
        self.previewHeaderContainer.hidden = !isVisible;
        
        // Consider the main navigation controller if the current view controller is embedded inside a split view controller.
        UINavigationController *mainNavigationController = self.navigationController;
        if (self.splitViewController && self.splitViewController.isCollapsed && self.splitViewController.viewControllers.count)
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
        }
        else
        {
            [self setRoomTitleViewClass:RoomTitleView.class];
            // We don't want to handle tap gesture here
        }
        
        // Report shadow image
        [mainNavigationController.navigationBar setShadowImage:shadowImage];
        [mainNavigationController.navigationBar setBackgroundImage:shadowImage forBarMetrics:UIBarMetricsDefault];
        
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             self.bubblesTableViewTopConstraint.constant = (isVisible ? self.previewHeaderContainerHeightConstraint.constant - self.bubblesTableView.contentInset.top : 0);
                             
                             if (roomAvatarView)
                             {
                                 roomAvatarView.alpha = 1;
                             }
                             
                             // Force to render the view
                             [self.view layoutIfNeeded];
                         }
                         completion:^(BOOL finished){
                         }];
    }
}

#pragma mark - Preview

- (void)displayEmailInvitation:(RoomEmailInvitation*)emailInvitation
{
    if (emailInvitation)
    {
        roomEmailInvitation = emailInvitation;
        previewHeader.emailInvitation = emailInvitation;
        
        [self refreshRoomTitle];
        
        if (emailInvitation.roomAvatarUrl)
        {
            if ([self.titleView isKindOfClass:RoomAvatarTitleView.class])
            {
                RoomAvatarTitleView *roomAvatarTitleView = (RoomAvatarTitleView*)self.titleView;
                MXKImageView *roomAvatarView = roomAvatarTitleView.roomAvatar;
                NSString *roomAvatarUrl = [self.roomDataSource.mxSession.matrixRestClient urlOfContentThumbnail:emailInvitation.roomAvatarUrl toFitViewSize:roomAvatarView.frame.size withMethod:MXThumbnailingMethodCrop];
                
                roomAvatarTitleView.roomAvatarURL = roomAvatarUrl;
            }            
        }
        
        if (emailInvitation.email)
        {
            // FIXME: Check whether the email is linked or not to the account
            // If it is not linked, use 'previewHeader.subInvitationLabel' to warm the user with predefined string 'room_preview_unlinked_email_warning'.
        }
    }
}

#pragma mark - MXKDataSourceDelegate

- (Class<MXKCellRendering>)cellViewClassForCellData:(MXKCellData*)cellData
{
    Class cellViewClass = nil;
    
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
                    cellViewClass = RoomIncomingAttachmentWithPaginationTitleBubbleCell.class;
                }
                else if (bubbleData.shouldHideSenderInformation)
                {
                    cellViewClass = RoomIncomingAttachmentWithoutSenderInfoBubbleCell.class;
                }
                else
                {
                    cellViewClass = RoomIncomingAttachmentBubbleCell.class;
                }
            }
            else
            {
                if (bubbleData.isPaginationFirstBubble)
                {
                    if (bubbleData.shouldHideSenderName)
                    {
                        cellViewClass = RoomIncomingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.class;
                    }
                    else
                    {
                        cellViewClass = RoomIncomingTextMsgWithPaginationTitleBubbleCell.class;
                    }
                }
                else if (bubbleData.shouldHideSenderInformation)
                {
                    cellViewClass = RoomIncomingTextMsgWithoutSenderInfoBubbleCell.class;
                }
                else if (bubbleData.shouldHideSenderName)
                {
                    cellViewClass = RoomIncomingTextMsgWithoutSenderNameBubbleCell.class;
                }
                else
                {
                    cellViewClass = RoomIncomingTextMsgBubbleCell.class;
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
                    cellViewClass = RoomOutgoingAttachmentWithPaginationTitleBubbleCell.class;
                }
                else if (bubbleData.shouldHideSenderInformation)
                {
                    cellViewClass = RoomOutgoingAttachmentWithoutSenderInfoBubbleCell.class;
                }
                else
                {
                    cellViewClass = RoomOutgoingAttachmentBubbleCell.class;
                }
            }
            else
            {
                if (bubbleData.isPaginationFirstBubble)
                {
                    if (bubbleData.shouldHideSenderName)
                    {
                        cellViewClass = RoomOutgoingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.class;
                    }
                    else
                    {
                        cellViewClass = RoomOutgoingTextMsgWithPaginationTitleBubbleCell.class;
                    }
                }
                else if (bubbleData.shouldHideSenderInformation)
                {
                    cellViewClass = RoomOutgoingTextMsgWithoutSenderInfoBubbleCell.class;
                }
                else if (bubbleData.shouldHideSenderName)
                {
                    cellViewClass = RoomOutgoingTextMsgWithoutSenderNameBubbleCell.class;
                }
                else
                {
                    cellViewClass = RoomOutgoingTextMsgBubbleCell.class;
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
        if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellTapOnMessageTextView] || [actionIdentifier isEqualToString:kMXKRoomBubbleCellTapOnContentView])
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
        else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellVectorEditButtonPressed])
        {
            [self dismissKeyboard];
            
            MXEvent *selectedEvent = userInfo[kMXKRoomBubbleCellEventKey];
            MXKRoomBubbleTableViewCell *roomBubbleTableViewCell = (MXKRoomBubbleTableViewCell *)cell;
            MXKAttachment *attachment = roomBubbleTableViewCell.bubbleData.attachment;
            
            if (selectedEvent)
            {
                if (self.currentAlert)
                {
                    [self.currentAlert dismiss:NO];
                    self.currentAlert = nil;
                }
                
                __weak __typeof(self) weakSelf = self;
                self.currentAlert = [[MXKAlert alloc] initWithTitle:nil message:nil style:MXKAlertStyleActionSheet];
                
                // Add actions for a failed event
                if (selectedEvent.mxkState == MXKEventStateSendingFailed)
                {
                    [self.currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_event_action_resend", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                        
                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        [strongSelf cancelEventSelection];
                        
                        // Let the datasource resend. It will manage local echo, etc.
                        [strongSelf.roomDataSource resendEventWithEventId:selectedEvent.eventId success:nil failure:nil];
                        
                    }];
                    
                    [self.currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_event_action_delete", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                        
                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        [strongSelf cancelEventSelection];
                        
                        [strongSelf.roomDataSource removeEventWithEventId:selectedEvent.eventId];
                    }];
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
                    
                    [self.currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_event_action_copy", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                        
                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        [strongSelf cancelEventSelection];
                        
                        [[UIPasteboard generalPasteboard] setString:selectedComponent.textMessage];
                        
                    }];
                    
                    [self.currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_event_action_share", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                        
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
                else // Add action for attachment
                {
                    if (attachment.type == MXKAttachmentTypeImage || attachment.type == MXKAttachmentTypeVideo)
                    {
                        [self.currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_event_action_save", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                            
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
                    
                    [self.currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_event_action_copy", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                        
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
                    
                    [self.currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_event_action_share", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                        
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
                
                // Check status of the selected event
                if (selectedEvent.mxkState == MXKEventStateUploading)
                {
                    // Upload id is stored in attachment url (nasty trick)
                    NSString *uploadId = roomBubbleTableViewCell.bubbleData.attachment.actualURL;
                    if ([MXKMediaManager existingUploaderWithId:uploadId])
                    {
                        [self.currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_event_action_cancel_upload", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                            
                            __strong __typeof(weakSelf)strongSelf = weakSelf;
                            [strongSelf cancelEventSelection];
                            
                            // Get again the loader
                            MXKMediaLoader *loader = [MXKMediaManager existingUploaderWithId:uploadId];
                            if (loader)
                            {
                                [loader cancel];
                            }
                            // Hide the progress animation
                            roomBubbleTableViewCell.progressView.hidden = YES;
                            
                        }];
                    }
                }
                else if (selectedEvent.mxkState != MXKEventStateSending && selectedEvent.mxkState != MXKEventStateSendingFailed)
                {
                    // Check whether download is in progress
                    if (selectedEvent.isMediaAttachment)
                    {
                        NSString *cacheFilePath = roomBubbleTableViewCell.bubbleData.attachment.cacheFilePath;
                        if ([MXKMediaManager existingDownloaderWithOutputFilePath:cacheFilePath])
                        {
                            [self.currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_event_action_cancel_download", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                                
                                __strong __typeof(weakSelf)strongSelf = weakSelf;
                                [strongSelf cancelEventSelection];
                                
                                // Get again the loader
                                MXKMediaLoader *loader = [MXKMediaManager existingDownloaderWithOutputFilePath:cacheFilePath];
                                if (loader)
                                {
                                    [loader cancel];
                                }
                                // Hide the progress animation
                                roomBubbleTableViewCell.progressView.hidden = YES;
                                
                            }];
                        }
                    }
                    
                    [self.currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_event_action_redact", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                        
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
                
                self.currentAlert.cancelButtonIndex = [self.currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"cancel", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                    
                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    [strongSelf cancelEventSelection];
                    
                }];
                
                // Do not display empty action sheet
                if (self.currentAlert.cancelButtonIndex)
                {
                    self.currentAlert.sourceView = roomBubbleTableViewCell;
                    [self.currentAlert showInViewController:self];
                }
                else
                {
                    self.currentAlert = nil;
                }
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

- (void)cancelEventSelection
{
    if (self.currentAlert)
    {
        [self.currentAlert dismiss:NO];
        self.currentAlert = nil;
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
            NSString* roomid = self.roomDataSource.roomId;
            NSMutableArray* viewControllers = [[NSMutableArray alloc] init];
            NSMutableArray* titles = [[NSMutableArray alloc] init];
            
            // members screens
            [titles addObject: NSLocalizedStringFromTable(@"room_details_people", @"Vector", nil)];
            
            RoomParticipantsViewController* participantsViewController = [[RoomParticipantsViewController alloc] init];
            participantsViewController.mxRoom = [session roomWithRoomId:roomid];
            participantsViewController.segmentedViewController = segmentedViewController;
            [viewControllers addObject:participantsViewController];
            
            [titles addObject: NSLocalizedStringFromTable(@"room_details_settings", @"Vector", nil)];
            RoomSettingsViewController *settingsViewController = [RoomSettingsViewController roomSettingsViewController];
            [settingsViewController initWithSession:session andRoomId:roomid];
            [viewControllers addObject:settingsViewController];
            
            // Sanity check
            if (selectedRoomDetailsIndex > 1)
            {
                selectedRoomDetailsIndex = 0;
            }
            
            segmentedViewController.title = NSLocalizedStringFromTable(@"room_details_title", @"Vector", nil);
            [segmentedViewController initWithTitles:titles viewControllers:viewControllers defaultSelected:selectedRoomDetailsIndex];
            
            // to display a red navbar when the home server cannot be reached.
            [segmentedViewController addMatrixSession:session];
        }
    }
    else if ([[segue identifier] isEqualToString:@"showRoomSearch"])
    {
        // Dismiss keyboard
        [self dismissKeyboard];

        RoomSearchViewController* roomSearchViewController = (RoomSearchViewController*)pushedViewController;

        RoomSearchDataSource *roomSearchDataSource = [[RoomSearchDataSource alloc] initWithRoomDataSource:self.roomDataSource andMatrixSession:self.mainSession];
        [roomSearchViewController displaySearch:roomSearchDataSource];
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
    [self.mainSession.callManager placeCallInRoom:self.roomDataSource.roomId withVideo:video];
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

#pragma mark - Action

- (IBAction)onButtonPressed:(id)sender
{
    if (sender == self.navigationItem.rightBarButtonItem)
    {
        [self performSegueWithIdentifier:@"showRoomSearch" sender:self];
    }
}

#pragma mark - UITableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    // Store the current offset to detect scroll down
    storedContentOffset = scrollView.contentOffset.y;
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    [super scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
    
    // Hide expanded header on scroll down
    if (storedContentOffset < scrollView.contentOffset.y)
    {
        [self showExpandedHeader:NO];
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
    UIView *view = tapGestureRecognizer.view;
    
    if (view == titleView.titleMask)
    {
        if (self.expandedHeaderContainer.isHidden)
        {
            // Expand the header
            [self showExpandedHeader:YES];
        }
        else
        {
            // Open room settings
            selectedRoomDetailsIndex = 1;
            [self performSegueWithIdentifier:@"showRoomDetails" sender:self];
        }
    }
    else if (view == titleView.roomDetailsMask)
    {
        // Open room details by selecting member list
        selectedRoomDetailsIndex = 0;
        [self performSegueWithIdentifier:@"showRoomDetails" sender:self];
    }
    else if (view == previewHeader.leftButton)
    {
        if (roomEmailInvitation)
        {
            //FIXME Accept the invitation
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
    else if (view == previewHeader.rightButton)
    {
        if (roomEmailInvitation)
        {
            //FIXME Decline this invitation
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
            currentTypingUsers = nil;
        }
    }
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
    if (self.activitiesView)
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

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([@"isOffline" isEqualToString:keyPath])
    {
        [self refreshActivitiesViewDisplay];
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Unreachable Network Handling

- (void)refreshActivitiesViewDisplay
{
    if (self.activitiesView)
    {
        if ([AppDelegate theDelegate].isOffline)
        {
            [((RoomActivitiesView*) self.activitiesView) displayNetworkErrorNotification:NSLocalizedStringFromTable(@"room_offline_notification", @"Vector", nil)];
        }
        else if ([self checkUnsentMessages] == NO)
        {
            [self refreshTypingNotification];
        }
    }
}


#pragma mark - Unsent Messages Handling

-(BOOL)checkUnsentMessages
{
    BOOL hasUnsent = NO;
    
    if (self.activitiesView)
    {
        NSArray *outgoingMsgs = self.roomDataSource.room.outgoingMessages;
        
        for (MXEvent *event in outgoingMsgs)
        {
            if (event.mxkState == MXKEventStateSendingFailed)
            {
                hasUnsent = YES;
                break;
            }
        }
        
        if (hasUnsent)
        {
            RoomActivitiesView *roomActivitiesView = (RoomActivitiesView*) self.activitiesView;
            [roomActivitiesView displayUnsentMessagesNotificationWithResendLink:^{
                
                [self resendAllUnsentMessages];
                
            } andIconTapGesture:^{
                
                if (self.currentAlert)
                {
                    [self.currentAlert dismiss:NO];
                }
                
                __weak __typeof(self) weakSelf = self;
                self.currentAlert = [[MXKAlert alloc] initWithTitle:nil message:nil style:MXKAlertStyleActionSheet];
                
                [self.currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_resend_unsent_messages", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                    
                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    [strongSelf resendAllUnsentMessages];
                    strongSelf.currentAlert = nil;
                    
                }];
                
                [self.currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_delete_unsent_messages", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                    
                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    
                    // Remove unsent event ids
                    for (NSUInteger index = 0; index < strongSelf.roomDataSource.room.outgoingMessages.count;)
                    {
                        MXEvent *event = strongSelf.roomDataSource.room.outgoingMessages[index];
                        if (event.mxkState == MXKEventStateSendingFailed)
                        {
                            [strongSelf.roomDataSource removeEventWithEventId:event.eventId];
                        }
                        else
                        {
                            index ++;
                        }
                    }
                    strongSelf.currentAlert = nil;
                }];
                
                self.currentAlert.cancelButtonIndex = [self.currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"cancel", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                    
                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    strongSelf.currentAlert = nil;
                    
                }];
                
                self.currentAlert.sourceView = roomActivitiesView;
                [self.currentAlert showInViewController:self];
                
            }];
        }
    }
    
    return hasUnsent;
}

- (void)resendAllUnsentMessages
{
    // List unsent event ids
    NSArray *outgoingMsgs = self.roomDataSource.room.outgoingMessages;
    NSMutableArray *failedEventIds = [NSMutableArray arrayWithCapacity:outgoingMsgs.count];
    
    for (MXEvent *event in outgoingMsgs)
    {
        if (event.mxkState == MXKEventStateSendingFailed)
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

@end

