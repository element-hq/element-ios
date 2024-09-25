/*
Copyright 2018-2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKRoomMemberListViewController.h"

#import "MXKRoomMemberTableViewCell.h"

#import "MXKConstants.h"

#import "NSBundle+MatrixKit.h"

#import "MXKSwiftHeader.h"

@interface MXKRoomMemberListViewController ()
{
    /**
     The data source providing UITableViewCells
     */
    MXKRoomMemberListDataSource *dataSource;
    
    /**
     Timer used to update members presence
     */
    NSTimer* presenceUpdateTimer;
    
    /**
     Optional bar buttons
     */
    UIBarButtonItem *searchBarButton;
    UIBarButtonItem *addBarButton;
    
    /**
     The current displayed alert (if any).
     */
    UIAlertController *currentAlert;
    
    /**
     Search bar
     */
    BOOL ignoreSearchRequest;
    
    /**
     Observe kMXSessionWillLeaveRoomNotification to be notified if the user leaves the current room.
     */
    id leaveRoomNotificationObserver;
}

@end

@implementation MXKRoomMemberListViewController
@synthesize dataSource;

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([MXKRoomMemberListViewController class])
                          bundle:[NSBundle bundleForClass:[MXKRoomMemberListViewController class]]];
}

+ (instancetype)roomMemberListViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass([MXKRoomMemberListViewController class])
                                          bundle:[NSBundle bundleForClass:[MXKRoomMemberListViewController class]]];
}


#pragma mark -

- (void)finalizeInit
{
    [super finalizeInit];
    
    // Enable both bar button by default.
    _enableMemberInvitation = YES;
    _enableMemberSearch = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Check whether the view controller has been pushed via storyboard
    if (!self.membersTableView)
    {
        // Instantiate view controller objects
        [[[self class] nib] instantiateWithOwner:self options:nil];
    }
    
    // Adjust Top and Bottom constraints to take into account potential navBar and tabBar.
    [NSLayoutConstraint deactivateConstraints:@[_membersSearchBarTopConstraint, _membersTableViewBottomConstraint]];
    
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated"
    _membersSearchBarTopConstraint = [NSLayoutConstraint constraintWithItem:self.topLayoutGuide
                                                                  attribute:NSLayoutAttributeBottom
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.membersSearchBar
                                                                  attribute:NSLayoutAttributeTop
                                                                 multiplier:1.0f
                                                                   constant:0.0f];
    
    _membersTableViewBottomConstraint = [NSLayoutConstraint constraintWithItem:self.bottomLayoutGuide
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.membersTableView
                                                                     attribute:NSLayoutAttributeBottom
                                                                    multiplier:1.0f
                                                                      constant:0.0f];
    #pragma clang diagnostic pop
    
    [NSLayoutConstraint activateConstraints:@[_membersSearchBarTopConstraint, _membersTableViewBottomConstraint]];
    
    // Hide search bar by default
    self.membersSearchBar.hidden = YES;
    self.membersSearchBarHeightConstraint.constant = 0;
    [self.view setNeedsUpdateConstraints];
    
    searchBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(search:)];
    addBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(inviteNewMember:)];
    
    // Refresh bar button display.
    [self refreshUIBarButtons];
    
    // Add an accessory view to the search bar in order to retrieve keyboard view.
    self.membersSearchBar.inputAccessoryView = [[UIView alloc] initWithFrame:CGRectZero];
    
    // Finalize table view configuration
    self.membersTableView.delegate = self;
    self.membersTableView.dataSource = dataSource; // Note datasource may be nil here.
    
    // Set up default table view cell class
    [self.membersTableView registerNib:MXKRoomMemberTableViewCell.nib forCellReuseIdentifier:MXKRoomMemberTableViewCell.defaultReuseIdentifier];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Check whether the user still belongs to the room's members.
    if (self.dataSource && [self.mainSession roomWithRoomId:self.dataSource.roomId])
    {
        [self refreshUIBarButtons];
        
        // Observe kMXSessionWillLeaveRoomNotification to be notified if the user leaves the current room.
        leaveRoomNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXSessionWillLeaveRoomNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif)
        {
            
            // Check whether the user will leave the room related to the displayed member list
            if (notif.object == self.mainSession)
            {
                NSString *roomId = notif.userInfo[kMXSessionNotificationRoomIdKey];
                if (roomId && [roomId isEqualToString:self.dataSource.roomId])
                {
                    // We remove the current view controller.
                    [self withdrawViewControllerAnimated:YES completion:nil];
                }
            }
        }];
    }
    else
    {
        // We remove the current view controller.
        [self withdrawViewControllerAnimated:YES completion:nil];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Restore search mechanism (if enabled)
    ignoreSearchRequest = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // The user may still press search button whereas the view disappears
    ignoreSearchRequest = YES;
    
    if (leaveRoomNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:leaveRoomNotificationObserver];
        leaveRoomNotificationObserver = nil;
    }
    
    // Leave potential search session
    if (!self.membersSearchBar.isHidden)
    {
        [self searchBarCancelButtonClicked:self.membersSearchBar];
    }
}

- (void)dealloc
{
    self.membersSearchBar.inputAccessoryView = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // Dispose of any resources that can be recreated.
}

#pragma mark - Override MXKTableViewController

- (void)onKeyboardShowAnimationComplete
{
    // Report the keyboard view in order to track keyboard frame changes
    self.keyboardView = _membersSearchBar.inputAccessoryView.superview;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
- (void)setKeyboardHeight:(CGFloat)keyboardHeight
{
    // Deduce the bottom constraint for the table view (Don't forget the potential tabBar)
    CGFloat tableViewBottomConst = keyboardHeight - self.bottomLayoutGuide.length;
    // Check whether the keyboard is over the tabBar
    if (tableViewBottomConst < 0)
    {
        tableViewBottomConst = 0;
    }
    
    // Update constraints
    _membersTableViewBottomConstraint.constant = tableViewBottomConst;
    
    // Force layout immediately to take into account new constraint
    [self.view layoutIfNeeded];
}
#pragma clang diagnostic pop

- (void)destroy
{
    if (presenceUpdateTimer)
    {
        [presenceUpdateTimer invalidate];
        presenceUpdateTimer = nil;
    }
    
    self.membersTableView.dataSource = nil;
    self.membersTableView.delegate = nil;
    self.membersTableView = nil;
    dataSource.delegate = nil;
    dataSource = nil;
    
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
    
    searchBarButton = nil;
    addBarButton = nil;
    
    _delegate = nil;
    
    [super destroy];
}

#pragma mark - Internal methods

- (void)updateMembersActivityInfo
{
    for (id memberCell in self.membersTableView.visibleCells)
    {
        if ([memberCell respondsToSelector:@selector(updateActivityInfo)])
        {
            [memberCell updateActivityInfo];
        }
    }
}

#pragma mark - UIBarButton handling

- (void)setEnableMemberSearch:(BOOL)enableMemberSearch
{
    _enableMemberSearch = enableMemberSearch;
    [self refreshUIBarButtons];
}

- (void)setEnableMemberInvitation:(BOOL)enableMemberInvitation
{
    _enableMemberInvitation = enableMemberInvitation;
    [self refreshUIBarButtons];
}

- (void)refreshUIBarButtons
{
    MXRoom *mxRoom = [self.mainSession roomWithRoomId:dataSource.roomId];

    MXWeakify(self);
    [mxRoom state:^(MXRoomState *roomState) {
        MXStrongifyAndReturnIfNil(self);

        BOOL showInvitationOption = self.enableMemberInvitation;

        if (showInvitationOption && self->dataSource)
        {
            // Check conditions to be able to invite someone
            NSInteger oneSelfPowerLevel = [roomState.powerLevels powerLevelOfUserWithUserID:self.mainSession.myUser.userId];
            if (oneSelfPowerLevel < [roomState.powerLevels invite])
            {
                showInvitationOption = NO;
            }
        }

        if (showInvitationOption)
        {
            if (self.enableMemberSearch)
            {
                self.navigationItem.rightBarButtonItems = @[self->searchBarButton, self->addBarButton];
            }
            else
            {
                self.navigationItem.rightBarButtonItems = @[self->addBarButton];
            }
        }
        else if (self.enableMemberSearch)
        {
            self.navigationItem.rightBarButtonItems = @[self->searchBarButton];
        }
        else
        {
            self.navigationItem.rightBarButtonItems = nil;
        }
    }];
}

#pragma mark -
- (void)displayList:(MXKRoomMemberListDataSource *)listDataSource
{
    if (dataSource)
    {
        dataSource.delegate = nil;
        dataSource = nil;
        [self removeMatrixSession:self.mainSession];
    }
    
    dataSource = listDataSource;
    dataSource.delegate = self;
    
    // Report the matrix session at view controller level to update UI according to session state
    [self addMatrixSession:dataSource.mxSession];
    
    if (self.membersTableView)
    {
        // Set up table data source
        self.membersTableView.dataSource = dataSource;
    }
}

- (void)scrollToTop:(BOOL)animated
{
    [self.membersTableView setContentOffset:CGPointMake(-self.membersTableView.adjustedContentInset.left, -self.membersTableView.adjustedContentInset.top) animated:animated];
}

#pragma mark - MXKDataSourceDelegate

- (Class<MXKCellRendering>)cellViewClassForCellData:(MXKCellData*)cellData
{
    // Return the default member table view cell
    return MXKRoomMemberTableViewCell.class;
}

- (NSString *)cellReuseIdentifierForCellData:(MXKCellData*)cellData
{
    // Consider the default member table view cell
    return MXKRoomMemberTableViewCell.defaultReuseIdentifier;
}

- (void)dataSource:(MXKDataSource *)dataSource didCellChange:(id)changes
{
    if (presenceUpdateTimer)
    {
        [presenceUpdateTimer invalidate];
        presenceUpdateTimer = nil;
    }
    
    // For now, do a simple full reload
    [self.membersTableView reloadData];
    
    if (shouldScrollToTopOnRefresh)
    {
        [self scrollToTop:NO];
        shouldScrollToTopOnRefresh = NO;
    }
    
    // Place a timer to update members's activity information
    presenceUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(updateMembersActivityInfo) userInfo:self repeats:YES];
}

#pragma mark - UITableView delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [dataSource cellHeightAtIndex:indexPath.row];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_delegate)
    {
        id<MXKRoomMemberCellDataStoring> cellData = [dataSource cellDataAtIndex:indexPath.row];
        
        [_delegate roomMemberListViewController:self didSelectMember:cellData.roomMember];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0;
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    // Release here resources, and restore reusable cells
    if ([cell respondsToSelector:@selector(didEndDisplay)])
    {
        [(id<MXKCellRendering>)cell didEndDisplay];
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    // Apply filter
    shouldScrollToTopOnRefresh = YES;
    if (searchText.length)
    {
        [self.dataSource searchWithPatterns:@[searchText]];
    }
    else
    {
        [self.dataSource searchWithPatterns:nil];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    // "Done" key has been pressed
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    // Leave search
    [searchBar resignFirstResponder];
    
    self.membersSearchBar.hidden = YES;
    self.membersSearchBarHeightConstraint.constant = 0;
    [self.view setNeedsUpdateConstraints];
    
    self.membersSearchBar.text = nil;
    
    // Refresh display
    shouldScrollToTopOnRefresh = YES;
    [self.dataSource searchWithPatterns:nil];
}

#pragma mark - Actions

- (void)search:(id)sender
{
    // The user may have pressed search button whereas the view controller was disappearing
    if (ignoreSearchRequest)
    {
        return;
    }
    
    if (self.membersSearchBar.isHidden)
    {
        // Check whether there are data in which search
        if ([self.dataSource tableView:self.membersTableView numberOfRowsInSection:0])
        {
            self.membersSearchBar.hidden = NO;
            self.membersSearchBarHeightConstraint.constant = 44;
            [self.view setNeedsUpdateConstraints];
            
            // Create search bar
            [self.membersSearchBar becomeFirstResponder];
        }
    }
    else
    {
        [self searchBarCancelButtonClicked: self.membersSearchBar];
    }
}

- (void)inviteNewMember:(id)sender
{
    __weak typeof(self) weakSelf = self;
    
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
    }
    
    // Ask for userId to invite
    currentAlert = [UIAlertController alertControllerWithTitle:[VectorL10n userIdTitle] message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           self->currentAlert = nil;
                                                       }
                                                       
                                                   }]];
    
    
    [currentAlert addTextFieldWithConfigurationHandler:^(UITextField *textField)
    {
        textField.secureTextEntry = NO;
        textField.placeholder = [VectorL10n userIdPlaceholder];
    }];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n invite]
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           
                                                           NSString *userId = [self->currentAlert textFields].firstObject.text;
                                                           
                                                           self->currentAlert = nil;
                                                           
                                                           if (userId.length)
                                                           {
                                                               MXRoom *mxRoom = [self.mainSession roomWithRoomId:self.dataSource.roomId];
                                                               if (mxRoom)
                                                               {
                                                                   [mxRoom inviteUser:userId success:^{
                                                                       
                                                                   } failure:^(NSError *error) {
                                                                       
                                                                       MXLogDebug(@"[MXKRoomVC] Invite %@ failed", userId);
                                                                       // Notify MatrixKit user
                                                                       NSString *myUserId = self.mainSession.myUser.userId;
                                                                       [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error userInfo:myUserId ? @{kMXKErrorUserIdKey: myUserId} : nil];
                                                                       
                                                                   }];
                                                               }
                                                           }
                                                       }
                                                       
                                                   }]];
    
    [self presentViewController:currentAlert animated:YES completion:nil];
}

@end
