/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "RoomParticipantsViewController.h"

#import "RoomMemberDetailsViewController.h"

#import "GeneratedInterface-Swift.h"

#import "Contact.h"

#import "MXCallManager.h"

#import "ContactTableViewCell.h"

#import "RageShakeManager.h"

@interface RoomParticipantsViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UIGestureRecognizerDelegate, MXKRoomMemberDetailsViewControllerDelegate, RoomParticipantsInviteCoordinatorBridgePresenterDelegate>
{
    // Search result
    NSString *currentSearchText;
    NSMutableArray<Contact*> *filteredActualParticipants;
    NSMutableArray<Contact*> *filteredInvitedParticipants;
    
    // Mask view while processing a request
    UIActivityIndicatorView *pendingMaskSpinnerView;
    
    // The members events listener.
    id membersListener;
    
    // Observe kMXSessionWillLeaveRoomNotification to be notified if the user leaves the current room.
    id leaveRoomNotificationObserver;
    
    // Observe kMXRoomDidFlushDataNotification to take into account the updated room members when the room history is flushed.
    id roomDidFlushDataNotificationObserver;
    
    RoomMemberDetailsViewController *memberDetailsViewController;
    
    UIAlertController *currentAlert;
    
    // Observe kThemeServiceDidChangeThemeNotification to handle user interface theme change.
    id kThemeServiceDidChangeThemeNotificationObserver;
    
    RoomParticipantsInviteCoordinatorBridgePresenter *invitePresenter;
}

@end

@implementation RoomParticipantsViewController

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([RoomParticipantsViewController class])
                          bundle:[NSBundle bundleForClass:[RoomParticipantsViewController class]]];
}

+ (instancetype)roomParticipantsViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass([RoomParticipantsViewController class])
                                          bundle:[NSBundle bundleForClass:[RoomParticipantsViewController class]]];
}

#pragma mark -

- (void)finalizeInit
{
    [super finalizeInit];
    
    // Setup `MXKViewControllerHandling` properties
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
    self.showParticipantCustomAccessoryView = YES;
    self.showInviteUserFab = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Check whether the view controller has been pushed via storyboard
    if (!self.tableView)
    {
        // Instantiate view controller objects
        [[[self class] nib] instantiateWithOwner:self options:nil];
    }
    
    // Adjust Top and Bottom constraints to take into account potential navBar and tabBar.
    [NSLayoutConstraint deactivateConstraints:@[_searchBarTopConstraint]];
    
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated"
    _searchBarTopConstraint = [NSLayoutConstraint constraintWithItem:self.topLayoutGuide
                                                           attribute:NSLayoutAttributeBottom
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:self.searchBarHeader
                                                           attribute:NSLayoutAttributeTop
                                                          multiplier:1.0f
                                                            constant:0.0f];
    #pragma clang diagnostic pop
    
    [NSLayoutConstraint activateConstraints:@[_searchBarTopConstraint]];
    
    self.navigationItem.title = [VectorL10n roomParticipantsTitle];
    
    if (self.mxRoom.summary.roomType == MXRoomTypeSpace)
    {
        _searchBarView.placeholder = [VectorL10n searchDefaultPlaceholder];
    }
    else if (self.mxRoom.isDirect)
    {
        _searchBarView.placeholder = [VectorL10n roomParticipantsFilterRoomMembersForDm];
    }
    else
    {
        _searchBarView.placeholder = [VectorL10n roomParticipantsFilterRoomMembers];
    }
    _searchBarView.returnKeyType = UIReturnKeyDone;
    _searchBarView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    
    // Search bar header is hidden when no room is provided
    _searchBarHeader.hidden = (self.mxRoom == nil);
    
    [self setNavBarButtons];
    
    // Hide line separators of empty cells
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    [self.tableView registerClass:ContactTableViewCell.class forCellReuseIdentifier:@"ParticipantTableViewCellId"];
    
    
    if (_showInviteUserFab)
    {
        // Add invite members button programmatically
        [self vc_addFABWithImage:AssetImages.addMemberFloatingAction.image
                          target:self
                          action:@selector(onAddParticipantButtonPressed)];
    }
    
    // Observe user interface theme change.
    kThemeServiceDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kThemeServiceDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self userInterfaceThemeDidChange];
        
    }];
    [self userInterfaceThemeDidChange];
}

- (void)userInterfaceThemeDidChange
{
    [ThemeService.shared.theme applyStyleOnNavigationBar:self.navigationController.navigationBar];

    self.activityIndicator.backgroundColor = ThemeService.shared.theme.overlayBackgroundColor;
    
    [self refreshSearchBarItemsColor:_searchBarView];
    
    _searchBarHeaderBorder.backgroundColor = ThemeService.shared.theme.headerBorderColor;
    
    // Check the table view style to select its bg color.
    self.tableView.backgroundColor = ((self.tableView.style == UITableViewStylePlain) ? ThemeService.shared.theme.backgroundColor : ThemeService.shared.theme.headerBackgroundColor);
    self.view.backgroundColor = self.tableView.backgroundColor;
    self.tableView.separatorColor = ThemeService.shared.theme.lineBreakColor;
    
    if (self.tableView.dataSource)
    {
        [self.tableView reloadData];
    }

    [self setNeedsStatusBarAppearanceUpdate];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return ThemeService.shared.theme.statusBarStyle;
}

// This method is called when the viewcontroller is added or removed from a container view controller.
- (void)didMoveToParentViewController:(nullable UIViewController *)parent
{
    [super didMoveToParentViewController:parent];
    
    [self setNavBarButtons];
}

- (void)destroy
{
    if (kThemeServiceDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kThemeServiceDidChangeThemeNotificationObserver];
        kThemeServiceDidChangeThemeNotificationObserver = nil;
    }
    
    if (leaveRoomNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:leaveRoomNotificationObserver];
        leaveRoomNotificationObserver = nil;
    }
    
    if (roomDidFlushDataNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:roomDidFlushDataNotificationObserver];
        roomDidFlushDataNotificationObserver = nil;
    }
    
    if (membersListener)
    {
        MXWeakify(self);
        [self.mxRoom liveTimeline:^(id<MXEventTimeline> liveTimeline) {
            MXStrongifyAndReturnIfNil(self);

            [liveTimeline removeListener:self->membersListener];
            self->membersListener = nil;
        }];
    }
    
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
    
    _mxRoom = nil;
    
    filteredActualParticipants = nil;
    filteredInvitedParticipants = nil;
    
    actualParticipants = nil;
    invitedParticipants = nil;
    userParticipant = nil;
    
    [self removePendingActionMask];
    
    [super destroy];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Refresh display
    [self refreshTableView];
    
    [self.screenTracker trackScreen];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (memberDetailsViewController)
    {
        [memberDetailsViewController destroy];
        memberDetailsViewController = nil;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
    
    // cancel any pending search
    [self searchBarCancelButtonClicked:_searchBarView];
}

- (void)withdrawViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    // Check whether the current view controller is displayed inside a segmented view controller in order to withdraw the right item
    if (self.parentViewController && [self.parentViewController isKindOfClass:SegmentedViewController.class])
    {
        [((SegmentedViewController*)self.parentViewController) withdrawViewControllerAnimated:animated completion:completion];
    }
    else
    {
        [super withdrawViewControllerAnimated:animated completion:completion];
    }
}

#pragma mark -

- (void)setMxRoom:(MXRoom *)mxRoom
{
    // Cancel any pending search
    [self searchBarCancelButtonClicked:_searchBarView];

    // Make sure we can access synchronously to self.mxRoom and mxRoom data
    // to avoid race conditions
    MXWeakify(self);
    [mxRoom.mxSession preloadRoomsData:_mxRoom ? @[_mxRoom.roomId, mxRoom.roomId] : @[mxRoom.roomId]
                             onComplete:^{
        MXStrongifyAndReturnIfNil(self);

        // Remove previous room registration (if any).
        if (self.mxRoom)
        {
            // Remove the previous listener
            if (self->leaveRoomNotificationObserver)
            {
                [[NSNotificationCenter defaultCenter] removeObserver:self->leaveRoomNotificationObserver];
                self->leaveRoomNotificationObserver = nil;
            }
            if (self->roomDidFlushDataNotificationObserver)
            {
                [[NSNotificationCenter defaultCenter] removeObserver:self->roomDidFlushDataNotificationObserver];
                self->roomDidFlushDataNotificationObserver = nil;
            }
            if (self->membersListener)
            {
                MXWeakify(self);
                [self.mxRoom liveTimeline:^(id<MXEventTimeline> liveTimeline) {
                    MXStrongifyAndReturnIfNil(self);

                    [liveTimeline removeListener:self->membersListener];
                    self->membersListener = nil;
                }];
            }

            [self removeMatrixSession:self.mxRoom.mxSession];
        }

        self->_mxRoom = mxRoom;

        if (self.mxRoom)
        {
            self.searchBarHeader.hidden = NO;
            
            if (self.mxRoom.summary.roomType == MXRoomTypeSpace)
            {
                self.searchBarView.placeholder = [VectorL10n searchDefaultPlaceholder];
            }
            else if (self.mxRoom.isDirect)
            {
                self.searchBarView.placeholder = [VectorL10n roomParticipantsFilterRoomMembersForDm];
            }
            else
            {
                self.searchBarView.placeholder = [VectorL10n roomParticipantsFilterRoomMembers];
            }

            // Update the current matrix session.
            [self addMatrixSession:self.mxRoom.mxSession];

            // Observe kMXSessionWillLeaveRoomNotification to be notified if the user leaves the current room.
            self->leaveRoomNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXSessionWillLeaveRoomNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {

                // Check whether the user will leave the room related to the displayed participants
                if (notif.object == self.mxRoom.mxSession)
                {
                    NSString *roomId = notif.userInfo[kMXSessionNotificationRoomIdKey];
                    if (roomId && [roomId isEqualToString:self.mxRoom.roomId])
                    {
                        // We remove the current view controller.
                        [self withdrawViewControllerAnimated:YES completion:nil];
                    }
                }
            }];

            // Observe room history flush (sync with limited timeline, or state event redaction)
            self->roomDidFlushDataNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXRoomDidFlushDataNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {

                MXRoom *room = notif.object;
                if (self.mxRoom.mxSession == room.mxSession && [self.mxRoom.roomId isEqualToString:room.roomId])
                {
                    // The existing room history has been flushed during server sync. Take into account the updated room members list.
                    [self refreshParticipantsFromRoomMembers];

                    [self refreshTableView];
                }

            }];

            // Register a listener for events that concern room members
            NSArray *mxMembersEvents = @[kMXEventTypeStringRoomMember, kMXEventTypeStringRoomThirdPartyInvite, kMXEventTypeStringRoomPowerLevels];

            MXWeakify(self);
            [self.mxRoom liveTimeline:^(id<MXEventTimeline> liveTimeline) {
                MXStrongifyAndReturnIfNil(self);

                self->membersListener = [liveTimeline listenToEventsOfTypes:mxMembersEvents onEvent:^(MXEvent *event, MXTimelineDirection direction, id customObject) {

                    // Consider only live event
                    if (direction == MXTimelineDirectionForwards)
                    {
                        switch (event.eventType)
                        {
                            case MXEventTypeRoomMember:
                            {
                                // Take into account updated member
                                // Ignore here change related to the current user (this change is handled by leaveRoomNotificationObserver)
                                if ([event.stateKey isEqualToString:self.mxRoom.mxSession.myUser.userId] == NO)
                                {
                                    MXRoomMember *mxMember = [liveTimeline.state.members memberWithUserId:event.stateKey];
                                    if (mxMember)
                                    {
                                        // Remove previous occurrence of this member (if any)
                                        [self removeParticipantByKey:mxMember.userId];

                                        // If any, remove 3pid invite corresponding to this room member
                                        if (mxMember.thirdPartyInviteToken)
                                        {
                                            [self removeParticipantByKey:mxMember.thirdPartyInviteToken];
                                        }

                                        [self handleRoomMember:mxMember];

                                        [self finalizeParticipantsList:liveTimeline.state];

                                        [self refreshTableView];
                                    }
                                }

                                break;
                            }
                            case MXEventTypeRoomThirdPartyInvite:
                            {
                                MXRoomThirdPartyInvite *thirdPartyInvite = [liveTimeline.state thirdPartyInviteWithToken:event.stateKey];
                                if (thirdPartyInvite)
                                {
                                    [self addRoomThirdPartyInviteToParticipants:thirdPartyInvite roomState:liveTimeline.state];

                                    [self finalizeParticipantsList:liveTimeline.state];

                                    [self refreshTableView];
                                }
                                break;
                            }
                            case MXEventTypeRoomPowerLevels:
                            {
                                [self refreshParticipantsFromRoomMembers];

                                [self refreshTableView];
                                break;
                            }
                            default:
                                break;
                        }
                    }
                }];
            }];
        }
        else
        {
            // Search bar header is hidden when no room is provided
            self.searchBarHeader.hidden = YES;
        }

        // Refresh the members list.
        [self refreshParticipantsFromRoomMembers];

        [self refreshTableView];
    }];
}

- (void)setEnableMention:(BOOL)enableMention
{
    if (_enableMention != enableMention)
    {
        _enableMention = enableMention;
        
        if (memberDetailsViewController)
        {
            memberDetailsViewController.enableMention = enableMention;
        }
    }
}

- (void)startActivityIndicator
{
    // Check whether the current view controller is displayed inside a segmented view controller in order to run the right activity view
    if (self.parentViewController && [self.parentViewController isKindOfClass:SegmentedViewController.class])
    {
        [((SegmentedViewController*)self.parentViewController) startActivityIndicator];
        
        // Force stop the activity view of the view controller
        [self.activityIndicator stopAnimating];
    }
    else
    {
        [super startActivityIndicator];
    }
}

- (void)stopActivityIndicator
{
    // Check whether the current view controller is displayed inside a segmented view controller in order to stop the right activity view
    if (self.parentViewController && [self.parentViewController isKindOfClass:SegmentedViewController.class])
    {
        [((SegmentedViewController*)self.parentViewController) stopActivityIndicator];
        
        // Force stop the activity view of the view controller
        [self.activityIndicator stopAnimating];
    }
    else
    {
        [super stopActivityIndicator];
    }
}

#pragma mark - Internals

- (void)refreshTableView
{
    [self.tableView reloadData];
}

- (void)setNavBarButtons
{
    // Check whether the view controller is currently displayed inside a segmented view controller or not.
    UIViewController* topViewController = ((self.parentViewController) ? self.parentViewController : self);
    topViewController.navigationItem.rightBarButtonItem = nil;
    
    if (self.showCancelBarButtonItem)
    {
        topViewController.navigationItem.leftBarButtonItem  = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onCancel:)];
    }
    else
    {
        topViewController.navigationItem.leftBarButtonItem = nil;
    }
}

- (void)onAddParticipantButtonPressed
{
    self->invitePresenter = [[RoomParticipantsInviteCoordinatorBridgePresenter alloc] initWithSession:self.mxRoom.mxSession room:self.mxRoom parentSpaceId:self.parentSpaceId currentSearchText:currentSearchText actualParticipants:actualParticipants invitedParticipants:invitedParticipants userParticipant:userParticipant];
    self->invitePresenter.delegate = self;
    [self->invitePresenter presentFrom:self animated:true];
}

- (void)refreshParticipantsFromRoomMembers
{
    actualParticipants = [NSMutableArray array];
    invitedParticipants = [NSMutableArray array];
    userParticipant = nil;
    
    if (self.mxRoom)
    {
        // Retrieve the current members from the room state
        MXWeakify(self);
        [self.mxRoom state:^(MXRoomState *roomState) {
            MXStrongifyAndReturnIfNil(self);

            NSArray *members = [roomState.members membersWithoutConferenceUser];
            NSString *userId = self.mxRoom.mxSession.myUser.userId;
            NSArray *roomThirdPartyInvites = roomState.thirdPartyInvites;

            for (MXRoomMember *mxMember in members)
            {
                // Update the current participants list
                if ([mxMember.userId isEqualToString:userId])
                {
                    if (mxMember.membership == MXMembershipJoin || mxMember.membership == MXMembershipInvite)
                    {
                        // The user is in this room
                        NSString *displayName = [VectorL10n you];

                        self->userParticipant = [[Contact alloc] initMatrixContactWithDisplayName:displayName andMatrixID:userId];
                        self->userParticipant.mxMember = [roomState.members memberWithUserId:userId];
                    }
                }
                else
                {
                    [self handleRoomMember:mxMember];
                }
            }

            for (MXRoomThirdPartyInvite *roomThirdPartyInvite in roomThirdPartyInvites)
            {
                [self addRoomThirdPartyInviteToParticipants:roomThirdPartyInvite roomState:roomState];
            }

            [self finalizeParticipantsList:roomState];
        }];
    }
}

- (void)handleRoomMember:(MXRoomMember*)mxMember
{
    // Add this member after checking his status
    if (mxMember.membership == MXMembershipJoin || mxMember.membership == MXMembershipInvite)
    {
        // Prepare the display name of this member
        NSString *displayName = mxMember.displayname;
        if (displayName.length == 0)
        {
            // Look for the corresponding MXUser in matrix session
            MXUser *mxUser = [self.mxRoom.mxSession userWithUserId:mxMember.userId];
            if (mxUser)
            {
                displayName = ((mxUser.displayname.length > 0) ? mxUser.displayname : mxMember.userId);
            }
            else
            {
                displayName = mxMember.userId;
            }
        }
        
        // Create the contact related to this member
        Contact *contact = [[Contact alloc] initMatrixContactWithDisplayName:displayName andMatrixID:mxMember.userId];
        contact.mxMember = mxMember;
        
        if (mxMember.membership == MXMembershipInvite)
        {
            [invitedParticipants addObject:contact];
        }
        else
        {
            [actualParticipants addObject:contact];
        }
    }
}

- (void)reloadSearchResult
{
    if (currentSearchText.length)
    {
        NSString *searchText = currentSearchText;
        currentSearchText = nil;
        
        [self searchBar:_searchBarView textDidChange:searchText];
    }
}

- (void)addRoomThirdPartyInviteToParticipants:(MXRoomThirdPartyInvite*)roomThirdPartyInvite roomState:(MXRoomState*)roomState
{
    // If the homeserver has converted the 3pid invite into a room member, do no show it
    // If the invite has been revoked (null display name), do not show it too.
    if (![roomState memberWithThirdPartyInviteToken:roomThirdPartyInvite.token]
        && roomThirdPartyInvite.displayname)
    {
        Contact *contact = [[Contact alloc] initMatrixContactWithDisplayName:roomThirdPartyInvite.displayname andMatrixID:nil];
        contact.isThirdPartyInvite = YES;
        contact.mxThirdPartyInvite = roomThirdPartyInvite;
        
        [invitedParticipants addObject:contact];
    }
}

// key is a room member user id or a room 3pid invite token
- (void)removeParticipantByKey:(NSString*)key
{
    NSUInteger index;
    
    if (actualParticipants.count)
    {
        for (index = 0; index < actualParticipants.count; index++)
        {
            Contact *contact = actualParticipants[index];
            
            if (contact.mxMember && [contact.mxMember.userId isEqualToString:key])
            {
                [actualParticipants removeObjectAtIndex:index];
                return;
            }
        }
    }
    
    if (invitedParticipants.count)
    {
        for (index = 0; index < invitedParticipants.count; index++)
        {
            Contact *contact = invitedParticipants[index];
            
            if (contact.mxMember && [contact.mxMember.userId isEqualToString:key])
            {
                [invitedParticipants removeObjectAtIndex:index];
                return;
            }
            
            if (contact.mxThirdPartyInvite && [contact.mxThirdPartyInvite.token isEqualToString:key])
            {
                [invitedParticipants removeObjectAtIndex:index];
                return;
            }
        }
    }
}

- (void)finalizeParticipantsList:(MXRoomState*)roomState
{
    // Sort contacts by last active, with "active now" first.
    // ...and then by power
    // ...and then alphabetically.
    // We could tiebreak instead by "last recently spoken in this room" if we wanted to.
    NSComparator comparator = ^NSComparisonResult(Contact *contactA, Contact *contactB) {
        
        MXUser *userA = [self.mxRoom.mxSession userWithUserId:contactA.mxMember.userId];
        MXUser *userB = [self.mxRoom.mxSession userWithUserId:contactB.mxMember.userId];
        
        if (!userA && !userB)
        {
            return [contactA.sortingDisplayName compare:contactB.sortingDisplayName options:NSCaseInsensitiveSearch];
        }
        if (userA && !userB)
        {
            return NSOrderedAscending;
        }
        if (!userA && userB)
        {
            return NSOrderedDescending;
        }
        
        if (userA.currentlyActive && userB.currentlyActive)
        {
            // Order first by power levels (admins then moderators then others)
            MXRoomPowerLevels *powerLevels = [roomState powerLevels];
            NSInteger powerLevelA = [powerLevels powerLevelOfUserWithUserID:contactA.mxMember.userId];
            NSInteger powerLevelB = [powerLevels powerLevelOfUserWithUserID:contactB.mxMember.userId];
            
            if (powerLevelA == powerLevelB)
            {
                // Then order by name
                if (contactA.sortingDisplayName.length && contactB.sortingDisplayName.length)
                {
                    return [contactA.sortingDisplayName compare:contactB.sortingDisplayName options:NSCaseInsensitiveSearch];
                }
                else if (contactA.sortingDisplayName.length)
                {
                    return NSOrderedAscending;
                }
                else if (contactB.sortingDisplayName.length)
                {
                    return NSOrderedDescending;
                }
                return [contactA.displayName compare:contactB.displayName options:NSCaseInsensitiveSearch];
            }
            else
            {
                return powerLevelB - powerLevelA;
            }
            
        }
        
        if (userA.currentlyActive && !userB.currentlyActive)
        {
            return NSOrderedAscending;
        }
        if (!userA.currentlyActive && userB.currentlyActive)
        {
            return NSOrderedDescending;
        }
        
        // Finally, compare the lastActiveAgo
        NSUInteger lastActiveAgoA = userA.lastActiveAgo;
        NSUInteger lastActiveAgoB = userB.lastActiveAgo;
        
        if (lastActiveAgoA == lastActiveAgoB)
        {
            return NSOrderedSame;
        }
        else
        {
            return ((lastActiveAgoA > lastActiveAgoB) ? NSOrderedDescending : NSOrderedAscending);
        }
    };
    
    // Sort each participants list in alphabetical order
    [actualParticipants sortUsingComparator:comparator];
    [invitedParticipants sortUsingComparator:comparator];
    
    // Reload search result if any
    [self reloadSearchResult];
}

- (void)addPendingActionMask
{
    // Remove potential existing mask
    [self removePendingActionMask];
    
    // Add a spinner above the tableview to avoid that the user tap on any other button
    pendingMaskSpinnerView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    pendingMaskSpinnerView.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:0.5];
    pendingMaskSpinnerView.frame = self.tableView.frame;
    pendingMaskSpinnerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin;
    
    // append it
    [self.tableView.superview addSubview:pendingMaskSpinnerView];
    
    // animate it
    [pendingMaskSpinnerView startAnimating];
    
    // Show the spinner after a delay so that if it is removed in a short future,
    // it is not displayed to the end user.
    pendingMaskSpinnerView.alpha = 0;
    [UIView animateWithDuration:0.3 delay:0.3 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        
        self->pendingMaskSpinnerView.alpha = 1;
        
    } completion:^(BOOL finished) {
    }];
}

- (void)removePendingActionMask
{
    if (pendingMaskSpinnerView)
    {
        [pendingMaskSpinnerView removeFromSuperview];
        pendingMaskSpinnerView = nil;
    }
}

- (void)pushViewController:(UIViewController*)viewController
{
    // Check whether the view controller is displayed inside a segmented one.
    if (self.parentViewController.navigationController)
    {
        // Hide back button title
        [self.parentViewController vc_removeBackTitle];

        [self.parentViewController.navigationController pushViewController:viewController animated:YES];
    }
    else
    {
        // Hide back button title
        [self vc_removeBackTitle];

        [self.navigationController pushViewController:viewController animated:YES];
    }
}

- (void)showDetailFor:(MXRoomMember* _Nonnull)member from:(UIView* _Nullable)sourceView {
    memberDetailsViewController = [RoomMemberDetailsViewController roomMemberDetailsViewController];
    
    // Set delegate to handle action on member (start chat, mention)
    memberDetailsViewController.delegate = self;
    memberDetailsViewController.enableMention = _enableMention;
    memberDetailsViewController.enableVoipCall = NO;
    
    [memberDetailsViewController displayRoomMember:member withMatrixRoom:self.mxRoom];
    
    [self pushViewController:memberDetailsViewController];
}

#pragma mark - UITableView data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger count = 0;
    
    participantsSection = invitedSection = -1;
    
    if (currentSearchText.length)
    {
        if (filteredActualParticipants.count)
        {
            participantsSection = count++;
        }
        
        if (filteredInvitedParticipants.count)
        {
            invitedSection = count++;
        }
    }
    else
    {
        if (userParticipant || actualParticipants.count)
        {
            participantsSection = count++;
        }
        
        if (invitedParticipants.count)
        {
            invitedSection = count++;
        }
    }
    
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    
    if (section == participantsSection)
    {
        if (currentSearchText.length)
        {
            count = filteredActualParticipants.count;
        }
        else
        {
            count = actualParticipants.count;
            if (userParticipant)
            {
                count++;
            }
        }
    }
    else if (section == invitedSection)
    {
        if (currentSearchText.length)
        {
            count = filteredInvitedParticipants.count;
        }
        else
        {
            count = invitedParticipants.count;
        }
    }
    
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    if (indexPath.section == participantsSection || indexPath.section == invitedSection)
    {
        ContactTableViewCell* participantCell = [tableView dequeueReusableCellWithIdentifier:@"ParticipantTableViewCellId" forIndexPath:indexPath];
        participantCell.selectionStyle = UITableViewCellSelectionStyleNone;
        participantCell.showCustomAccessoryView = self.showParticipantCustomAccessoryView;
        
        participantCell.mxRoom = self.mxRoom;
        
        Contact *contact;
        
        if ((indexPath.section == participantsSection && userParticipant && indexPath.row == 0) && !currentSearchText.length)
        {
            // oneself dedicated cell
            contact = userParticipant;
        }
        else
        {
            NSInteger index = indexPath.row;
            NSArray *participants;
            
            if (indexPath.section == participantsSection)
            {
                if (currentSearchText.length)
                {
                    participants = filteredActualParticipants;
                }
                else
                {
                    participants = actualParticipants;
                    
                    if (userParticipant)
                    {
                        index --;
                    }
                }
            }
            else
            {
                if (currentSearchText.length)
                {
                    participants = filteredInvitedParticipants;
                }
                else
                {
                    participants = invitedParticipants;
                }
            }
            
            if (index < participants.count)
            {
                contact = participants[index];
            }
        }
        
        if (contact)
        {
            [participantCell render:contact];
            
            if (contact.mxMember)
            {
                MXRoomState *roomState = self.mxRoom.dangerousSyncState;
                
                // Update member power level
                MXRoomPowerLevels *powerLevels = [roomState powerLevels];
                NSInteger powerLevel = [powerLevels powerLevelOfUserWithUserID:contact.mxMember.userId];
                
                RoomPowerLevel roomPowerLevel = [RoomPowerLevelHelper roomPowerLevelFrom:powerLevel];
                
                NSString *powerLevelText;
                
                switch (roomPowerLevel) {
                    case RoomPowerLevelAdmin:
                        powerLevelText = [VectorL10n roomMemberPowerLevelShortAdmin];
                        break;
                    case RoomPowerLevelModerator:
                        powerLevelText = [VectorL10n roomMemberPowerLevelShortModerator];
                        break;
                    default:
                        powerLevelText = nil;
                        break;
                }
                
                participantCell.powerLevelLabel.text = powerLevelText;
                
                // Update the contact display name by considering the current room state.
                if (contact.mxMember.userId)
                {
                    participantCell.contactDisplayNameLabel.text = [roomState.members memberName:contact.mxMember.userId];
                }
            }
        }
        
        cell = participantCell;
    }
    else
    {
        // Return a fake cell to prevent app from crashing.
        cell = [[UITableViewCell alloc] init];
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == participantsSection || indexPath.section == invitedSection)
    {
        return YES;
    }
    return NO;
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
    // iOS8 requires this method to enable editing (see editActionsForRowAtIndexPath).
}

#pragma mark - UITableView delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
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
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = 0.0;
    
    if (section == invitedSection)
    {
        height = 30.0;
    }
    
    return height;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView* sectionHeader;
    
    if (section == invitedSection)
    {
        sectionHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 30)];
        sectionHeader.backgroundColor = ThemeService.shared.theme.headerBackgroundColor;
        
        CGRect frame = sectionHeader.frame;
        frame.origin.x = 20;
        frame.origin.y = 5;
        frame.size.width = sectionHeader.frame.size.width - 10;
        frame.size.height -= 10;
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:frame];
        headerLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
        headerLabel.font = [UIFont boldSystemFontOfSize:15.0];
        headerLabel.backgroundColor = [UIColor clearColor];
        
        headerLabel.text = [VectorL10n roomParticipantsInvitedSection];
        
        [sectionHeader addSubview:headerLabel];
    }
    
    return sectionHeader;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 74.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Sanity check
    if (!self.mxRoom)
    {
        return;
    }
    
    Contact *contact;
    
    // oneself dedicated cell
    if ((indexPath.section == participantsSection && userParticipant && indexPath.row == 0) && !currentSearchText.length)
    {
        contact = userParticipant;
    }
    else
    {
        NSInteger index = indexPath.row;
        NSArray *participants;
        
        if (indexPath.section == participantsSection)
        {
            if (currentSearchText.length)
            {
                participants = filteredActualParticipants;
            }
            else
            {
                participants = actualParticipants;
                
                if (userParticipant)
                {
                    index --;
                }
            }
        }
        else
        {
            if (currentSearchText.length)
            {
                participants = filteredInvitedParticipants;
            }
            else
            {
                participants = invitedParticipants;
            }
        }
        
        if (index < participants.count)
        {
            contact = participants[index];
        }
    }
    
    if (contact.mxMember)
    {
        UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
        [self showDetailFor:contact.mxMember from:selectedCell];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray* actions;
    
    // add the swipe to delete only on participants sections
    if (indexPath.section == participantsSection || indexPath.section == invitedSection)
    {
        actions = [[NSMutableArray alloc] init];
        
        // Patch: Force the width of the button by adding whitespace characters into the title string.
        UITableViewRowAction *leaveAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"        "  handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
            
            [self onDeleteAt:indexPath];
            
        }];
        
        leaveAction.backgroundColor = [MXKTools convertImageToPatternColor:@"remove_icon" backgroundColor:ThemeService.shared.theme.headerBackgroundColor patternSize:CGSizeMake(74, 74) resourceSize:CGSizeMake(24, 24)];
        [actions insertObject:leaveAction atIndex:0];
    }
    
    return actions;
}

#pragma mark - MXKRoomMemberDetailsViewControllerDelegate

- (void)roomMemberDetailsViewController:(MXKRoomMemberDetailsViewController *)roomMemberDetailsViewController startChatWithMemberId:(NSString *)matrixId completion:(void (^)(void))completion
{
    [[AppDelegate theDelegate] showNewDirectChat:matrixId withMatrixSession:self.mxRoom.mxSession completion:completion];
}

- (void)roomMemberDetailsViewController:(MXKRoomMemberDetailsViewController *)roomMemberDetailsViewController mention:(MXRoomMember*)member
{
    if (_delegate)
    {
        id<RoomParticipantsViewControllerDelegate> delegate = _delegate;
        
        // Withdraw the current view controller, and let the delegate mention the member
        [self withdrawViewControllerAnimated:YES completion:^{
            
            [delegate roomParticipantsViewController:self mention:member];
            
        }];
    }
}

#pragma mark - Actions

- (void)onDeleteAt:(NSIndexPath*)path
{
    NSUInteger section = path.section;
    NSUInteger row = path.row;
    
    if (section == participantsSection || section == invitedSection)
    {
        if (currentAlert)
        {
            [currentAlert dismissViewControllerAnimated:NO completion:nil];
            currentAlert = nil;
        }
        
        if (section == participantsSection && userParticipant && (0 == row) && !currentSearchText.length)
        {
            // Leave ?
            MXWeakify(self);
            
            NSString *title, *message;
            if (self.mxRoom.isDirect)
            {
                title = [VectorL10n roomParticipantsLeavePromptTitleForDm];
                message = [VectorL10n roomParticipantsLeavePromptMsgForDm];
            }
            else
            {
                title = [VectorL10n roomParticipantsLeavePromptTitle];
                message = [VectorL10n roomParticipantsLeavePromptMsg];
            }
            
            currentAlert = [UIAlertController alertControllerWithTitle:title
                                                               message:message
                                                        preferredStyle:UIAlertControllerStyleAlert];
            
            [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                             style:UIAlertActionStyleCancel
                                                           handler:^(UIAlertAction * action) {
                                                               
                                                               MXStrongifyAndReturnIfNil(self);
                                                               self->currentAlert = nil;
                                                               
                                                           }]];
            
            [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n leave]
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               
                                                               MXStrongifyAndReturnIfNil(self);
                                                               self->currentAlert = nil;
                                                               
                                                               [self addPendingActionMask];
                                                               MXWeakify(self);
                                                               [self.mxRoom leave:^{
                                                                   
                                                                   MXStrongifyAndReturnIfNil(self);
                                                                   [self withdrawViewControllerAnimated:YES completion:nil];
                                                                   
                                                               } failure:^(NSError *error) {
                                                                   
                                                                   MXStrongifyAndReturnIfNil(self);
                                                                   [self removePendingActionMask];
                                                                   MXLogDebug(@"[RoomParticipantsVC] Leave room %@ failed", self.mxRoom.roomId);
                                                                   // Alert user
                                                                   [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                                   
                                                               }];
                                                               
                                                           }]];
            
            [currentAlert mxk_setAccessibilityIdentifier:@"RoomParticipantsVCLeaveAlert"];
            [self presentViewController:currentAlert animated:YES completion:nil];
        }
        else
        {
            NSMutableArray *participants;
            
            if (section == participantsSection)
            {
                if (currentSearchText.length)
                {
                    participants = filteredActualParticipants;
                }
                else
                {
                    participants = actualParticipants;
                    
                    if (userParticipant)
                    {
                        row --;
                    }
                }
            }
            else
            {
                if (currentSearchText.length)
                {
                    participants = filteredInvitedParticipants;
                }
                else
                {
                    participants = invitedParticipants;
                }
            }
            
            if (row < participants.count)
            {
                Contact *contact = participants[row];
                MXWeakify(self);
                
                if (contact.mxMember)
                {
                    NSString *memberUserId = contact.mxMember.userId;
                    
                    // Kick ?
                    NSString *promptMsg = [VectorL10n roomParticipantsRemovePromptMsg:(contact ? contact.displayName : memberUserId)];
                    currentAlert = [UIAlertController alertControllerWithTitle:[VectorL10n roomParticipantsRemovePromptTitle]
                                                                       message:promptMsg
                                                                preferredStyle:UIAlertControllerStyleAlert];
                    
                    [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                                     style:UIAlertActionStyleCancel
                                                                   handler:^(UIAlertAction * action) {
                                                                       
                                                                       MXStrongifyAndReturnIfNil(self);
                                                                       self->currentAlert = nil;
                                                                       
                                                                   }]];
                    
                    [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n remove]
                                                                     style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * action) {
                                                                       
                                                                       MXStrongifyAndReturnIfNil(self);
                                                                       self->currentAlert = nil;
                                                                       
                                                                       [self addPendingActionMask];
                                                                       MXWeakify(self);
                                                                       [self.mxRoom kickUser:memberUserId
                                                                                      reason:nil
                                                                                     success:^{
                                                                                         
                                                                                         MXStrongifyAndReturnIfNil(self);
                                                                                         [self removePendingActionMask];
                                                                                         
                                                                                         [participants removeObjectAtIndex:row];
                                                                                         
                                                                                         // Refresh display
                                                                                         [self.tableView reloadData];
                                                                                         
                                                                                     } failure:^(NSError *error) {
                                                                                         
                                                                                         MXStrongifyAndReturnIfNil(self);
                                                                                         [self removePendingActionMask];
                                                                                         MXLogDebug(@"[RoomParticipantsVC] Kick %@ failed", memberUserId);
                                                                                         // Alert user
                                                                                         [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                                                         
                                                                                     }];
                                                                       
                                                                   }]];
                }
                else if (contact.mxThirdPartyInvite)
                {
                    // This is a third-party invite
                    currentAlert = [UIAlertController alertControllerWithTitle:nil
                                                                       message:[VectorL10n roomParticipantsRemoveThirdPartyInvitePromptMsg]
                                                                preferredStyle:UIAlertControllerStyleAlert];
                    
                    [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                                     style:UIAlertActionStyleCancel
                                                                   handler:^(UIAlertAction * action) {
                                                                       
                                                                       MXStrongifyAndReturnIfNil(self);
                                                                       self->currentAlert = nil;
                                                                       
                                                                   }]];
                    
                    [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n remove]
                                                                     style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * action) {
                                                                       
                                                                       MXStrongifyAndReturnIfNil(self);
                                                                       self->currentAlert = nil;
                                                                       
                                                                       [self addPendingActionMask];
                                                                       MXWeakify(self);
                                                                       [self.mxRoom sendStateEventOfType:kMXEventTypeStringRoomThirdPartyInvite
                                                                                                 content:@{} stateKey:contact.mxThirdPartyInvite.token success:^(NSString *eventId) {
                                                                                                     
                                                                                                     MXStrongifyAndReturnIfNil(self);
                                                                                                     [self removePendingActionMask];
                                                                                                     
                                                                                                     [participants removeObjectAtIndex:row];
                                                                                                     
                                                                                                     // Refresh display
                                                                                                     [self.tableView reloadData];
                                                                                                     
                                                                                                 } failure:^(NSError *error) {
                                                                                                     
                                                                                                     MXStrongifyAndReturnIfNil(self);
                                                                                                     [self removePendingActionMask];
                                                                                                     MXLogDebug(@"[RoomParticipantsVC] Revoke 3pid invite failed");
                                                                                                     // Alert user
                                                                                                     [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                                                                     
                                                                                                 }];
                                                                       
                                                                   }]];
                }
                
                [currentAlert mxk_setAccessibilityIdentifier:@"RoomParticipantsVCKickAlert"];
                [self presentViewController:currentAlert animated:YES completion:nil];
            }
        }
    }
}

- (void)onCancel:(id)sender
{
    [self withdrawViewControllerAnimated:YES completion:nil];
}

#pragma mark - UISearchBar delegate

- (void)refreshSearchBarItemsColor:(UISearchBar *)searchBar
{
    // bar tint color
    searchBar.barTintColor = searchBar.tintColor = ThemeService.shared.theme.tintColor;
    searchBar.tintColor = ThemeService.shared.theme.tintColor;
    
    // FIXME: this all seems incredibly fragile and tied to gutwrenching the current UISearchBar internals.
    
    // text color
    UITextField *searchBarTextField = searchBar.vc_searchTextField;
    searchBarTextField.textColor = ThemeService.shared.theme.textSecondaryColor;
    
    // Magnifying glass icon.
    UIImageView *leftImageView = (UIImageView *)searchBarTextField.leftView;
    leftImageView.image = [leftImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
    // remove the gray background color
    UIView *effectBackgroundTop =  [searchBarTextField valueForKey:@"_effectBackgroundTop"];
    UIView *effectBackgroundBottom =  [searchBarTextField valueForKey:@"_effectBackgroundBottom"];
    effectBackgroundTop.hidden = YES;
    effectBackgroundBottom.hidden = YES;
    
    // place holder
    searchBarTextField.textColor = ThemeService.shared.theme.searchPlaceholderColor;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    // Update search results.
    NSUInteger index;
    MXKContact *contact;
    
    searchText = [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (!currentSearchText.length || [searchText hasPrefix:currentSearchText] == NO)
    {
        // Copy participants and invited participants
        filteredActualParticipants = [NSMutableArray arrayWithArray:actualParticipants];
        filteredInvitedParticipants = [NSMutableArray arrayWithArray:invitedParticipants];
        
        // Add the current user if he belongs to the room members.
        if (userParticipant)
        {
            [filteredActualParticipants addObject:userParticipant];
        }
    }
    
    currentSearchText = searchText;
    
    // Filter room participants
    if (currentSearchText.length)
    {
        for (index = 0; index < filteredActualParticipants.count;)
        {
            contact = filteredActualParticipants[index];
            if (![contact matchedWithPatterns:@[currentSearchText]])
            {
                [filteredActualParticipants removeObjectAtIndex:index];
            }
            else
            {
                index++;
            }
        }
        
        for (index = 0; index < filteredInvitedParticipants.count;)
        {
            contact = filteredInvitedParticipants[index];
            if (![contact matchedWithPatterns:@[currentSearchText]])
            {
                [filteredInvitedParticipants removeObjectAtIndex:index];
            }
            else
            {
                index++;
            }
        }
    }
    else
    {
        filteredActualParticipants = nil;
        filteredInvitedParticipants = nil;
    }
    
    // Refresh display
    [self refreshTableView];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    searchBar.showsCancelButton = YES;
    
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
{
    searchBar.showsCancelButton = NO;
    
    return YES;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    // "Done" key has been pressed.
    
    // Dismiss keyboard
    [_searchBarView resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    if (currentSearchText)
    {
        currentSearchText = nil;
        filteredActualParticipants = nil;
        filteredInvitedParticipants = nil;
        
        [self refreshTableView];
    }
    
    searchBar.text = nil;
    // Leave search
    [searchBar resignFirstResponder];
}

#pragma mark - RoomParticipantsInviteCoordinatorBridgePresenterDelegate

- (void)roomParticipantsInviteCoordinatorBridgePresenterDidComplete:(RoomParticipantsInviteCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    self->invitePresenter = nil;
}

- (void)roomParticipantsInviteCoordinatorBridgePresenterDidStartLoading:(RoomParticipantsInviteCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    [self addPendingActionMask];
}

- (void)roomParticipantsInviteCoordinatorBridgePresenterDidEndLoading:(RoomParticipantsInviteCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    [self removePendingActionMask];
}

@end
