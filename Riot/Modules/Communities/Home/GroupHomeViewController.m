/*
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

#import "GroupHomeViewController.h"

#import "AppDelegate.h"

#import "RiotDesignValues.h"
#import "Tools.h"

#import "MXGroup+Riot.h"

#import "DTCoreText.h"

@interface GroupHomeViewController ()
{
    MXHTTPOperation *currentRequest;
    
    /**
     The current visibility of the status bar in this view controller.
     */
    BOOL isStatusBarHidden;
    
    // Observe kRiotDesignValuesDidChangeThemeNotification to handle user interface theme change.
    id kRiotDesignValuesDidChangeThemeNotificationObserver;
    
    // The options used to load long description html content.
    NSDictionary *options;
    NSString *sanitisedGroupLongDescription;
    
    // The current pushed view controller
    UIViewController *pushedViewController;
}
@end

@implementation GroupHomeViewController

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass(self.class)
                          bundle:[NSBundle bundleForClass:self.class]];
}

+ (instancetype)groupHomeViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass(self.class)
                                          bundle:[NSBundle bundleForClass:self.class]];
}

#pragma mark -

- (void)finalizeInit
{
    [super finalizeInit];
    
    // Setup `MXKViewControllerHandling` properties
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    // Keep visible the status bar by default.
    isStatusBarHidden = NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.leftButton setTitle:NSLocalizedStringFromTable(@"decline", @"Vector", nil) forState:UIControlStateNormal];
    [self.leftButton setTitle:NSLocalizedStringFromTable(@"decline", @"Vector", nil) forState:UIControlStateHighlighted];
    [self.rightButton setTitle:NSLocalizedStringFromTable(@"join", @"Vector", nil) forState:UIControlStateNormal];
    [self.rightButton setTitle:NSLocalizedStringFromTable(@"join", @"Vector", nil) forState:UIControlStateHighlighted];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [tap setDelegate:self];
    [_groupNameMask addGestureRecognizer:tap];
    _groupNameMask.userInteractionEnabled = YES;
    
    // Add tap to show the group avatar in fullscreen
    tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [tap setDelegate:self];
    [_groupAvatarMask addGestureRecognizer:tap];
    _groupAvatarMask.userInteractionEnabled = YES;
    
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
    
    self.view.backgroundColor = kRiotPrimaryBgColor;
    self.mainHeaderContainer.backgroundColor = kRiotSecondaryBgColor;
    
    _groupName.textColor = kRiotPrimaryTextColor;
    
    _groupDescription.textColor = kRiotTopicTextColor;
    _groupDescription.numberOfLines = 0;
    
    self.inviteLabel.textColor = kRiotTopicTextColor;
    self.inviteLabel.numberOfLines = 0;
    
    self.separatorView.backgroundColor = kRiotSecondaryBgColor;
    
    [self.leftButton.layer setCornerRadius:5];
    self.leftButton.clipsToBounds = YES;
    self.leftButton.backgroundColor = kRiotColorBlue;
    
    [self.rightButton.layer setCornerRadius:5];
    self.rightButton.clipsToBounds = YES;
    self.rightButton.backgroundColor = kRiotColorBlue;
    
    if (_groupLongDescription)
    {
        _groupLongDescription.textColor = kRiotSecondaryTextColor;
        _groupLongDescription.tintColor = kRiotColorBlue;
        
        // Update HTML loading options
        NSUInteger bgColor = [MXKTools rgbValueWithColor:kRiotSecondaryBgColor];
        NSString *defaultCSS = [NSString stringWithFormat:@" \
                      pre,code { \
                      background-color: #%06lX; \
                      display: inline; \
                      font-family: monospace; \
                      white-space: pre; \
                      -coretext-fontname: Menlo-Regular; \
                      font-size: small; \
                      }", (unsigned long)bgColor];
        
        // Apply the css style
        options = @{
                    DTUseiOS6Attributes: @(YES),              // Enable it to be able to display the attributed string in a UITextView
                    DTDefaultFontFamily: _groupLongDescription.font.familyName,
                    DTDefaultFontName: _groupLongDescription.font.fontName,
                    DTDefaultFontSize: @(_groupLongDescription.font.pointSize),
                    DTDefaultTextColor: _groupLongDescription.textColor,
                    DTDefaultLinkDecoration: @(NO),
                    DTDefaultStyleSheet: [[DTCSSStylesheet alloc] initWithStyleBlock:defaultCSS]
                    };
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return kRiotDesignStatusBarStyle;
}

- (BOOL)prefersStatusBarHidden
{
    // Return the current status bar visibility.
    return isStatusBarHidden;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Screen tracking
    [[Analytics sharedInstance] trackScreen:@"GroupDetailsHome"];
    
    // Release the potential pushed view controller
    [self releasePushedViewController];
    
    if (_group)
    {
        // Restore the listeners on the group update.
        [self registerOnGroupChangeNotifications];
        
        // Check whether the selected group is stored in the user's session, or if it is a group preview.
        // Replace the displayed group instance with the one stored in the session (if any).
        MXGroup *storedGroup = [_mxSession groupWithGroupId:_group.groupId];
        BOOL isPreview = (!storedGroup);
        
        // Force refresh
        [self refreshDisplayWithGroup:(isPreview ? _group : storedGroup)];
        
        // Prepare a block called on successful update in case of a group preview.
        // Indeed the group update notifications are triggered by the matrix session only for the user's groups.
        void (^success)(void) = ^void(void)
        {
            [self refreshDisplayWithGroup:_group];
        };
        
        // Trigger a refresh on the group summary.
        [self.mxSession updateGroupSummary:_group success:(isPreview ? success : nil) failure:^(NSError *error) {
            
            NSLog(@"[GroupHomeViewController] viewWillAppear: group summary update failed %@", _group.groupId);
            
        }];
        // Trigger a refresh on the group members (ignore here the invited users).
        [self.mxSession updateGroupUsers:_group success:(isPreview ? success : nil) failure:^(NSError *error) {
            
            NSLog(@"[GroupHomeViewController] viewWillAppear: group members update failed %@", _group.groupId);
            
        }];
        // Trigger a refresh on the group rooms.
        [self.mxSession updateGroupRooms:_group success:(isPreview ? success : nil) failure:^(NSError *error) {
            
            NSLog(@"[GroupHomeViewController] viewWillAppear: group rooms update failed %@", _group.groupId);
            
        }];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self cancelRegistrationOnGroupChangeNotifications];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    // Scroll to the top the long group description.
    _groupLongDescription.contentOffset = CGPointZero;
}

- (void)destroy
{
    // Release the potential pushed view controller
    [self releasePushedViewController];
    
    // Note: all observers are removed during super call.
    [super destroy];
    
    _group = nil;
    _mxSession = nil;
    
    [currentRequest cancel];
    currentRequest = nil;
    
    if (kRiotDesignValuesDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kRiotDesignValuesDidChangeThemeNotificationObserver];
        kRiotDesignValuesDidChangeThemeNotificationObserver = nil;
    }
}

- (void)setGroup:(MXGroup*)group withMatrixSession:(MXSession*)mxSession
{
    if (_mxSession != mxSession)
    {
        [self cancelRegistrationOnGroupChangeNotifications];
        _mxSession = mxSession;
        
        [self registerOnGroupChangeNotifications];
    }
    
    [self addMatrixSession:mxSession];
    
    [self refreshDisplayWithGroup:group];
}

#pragma mark -

- (void)pushViewController:(UIViewController*)viewController
{
    // Keep ref on pushed view controller
    pushedViewController = viewController;
    
    // Check whether the view controller is displayed inside a segmented one.
    if (self.parentViewController.navigationController)
    {
        // Hide back button title
        self.parentViewController.navigationItem.backBarButtonItem =[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
        
        [self.parentViewController.navigationController pushViewController:viewController animated:YES];
    }
    else
    {
        // Hide back button title
        self.navigationItem.backBarButtonItem =[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
        
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

- (void)releasePushedViewController
{
    if (pushedViewController)
    {
        if ([pushedViewController isKindOfClass:[UINavigationController class]])
        {
            UINavigationController *navigationController = (UINavigationController*)pushedViewController;
            for (id subViewController in navigationController.viewControllers)
            {
                if ([subViewController respondsToSelector:@selector(destroy)])
                {
                    [subViewController destroy];
                }
            }
        }
        else if ([pushedViewController respondsToSelector:@selector(destroy)])
        {
            [(id)pushedViewController destroy];
        }
        
        pushedViewController = nil;
    }
}

- (void)registerOnGroupChangeNotifications
{
    if (_mxSession)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateGroupDetails:) name:kMXSessionDidUpdateGroupSummaryNotification object:_mxSession];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateGroupDetails:) name:kMXSessionDidUpdateGroupUsersNotification object:_mxSession];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateGroupDetails:) name:kMXSessionDidUpdateGroupRoomsNotification object:_mxSession];
    }
}

- (void)cancelRegistrationOnGroupChangeNotifications
{
    // Remove any pending observers
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXSessionDidUpdateGroupSummaryNotification object:_mxSession];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXSessionDidUpdateGroupUsersNotification object:_mxSession];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXSessionDidUpdateGroupRoomsNotification object:_mxSession];
}

- (void)didUpdateGroupDetails:(NSNotification *)notif
{
    MXGroup *group = notif.userInfo[kMXSessionNotificationGroupKey];
    if (group && [group.groupId isEqualToString:_group.groupId])
    {
        // Update the current displayed group instance with the one stored in the session
        [self refreshDisplayWithGroup:group];
    }
}

- (void)refreshDisplayWithGroup:(MXGroup*)group
{
    _group = group;
    
    // Check whether the view controller has been loaded
    if (!self.isViewLoaded)
    {
        return;
    }
    
    if (_group)
    {
        [_group setGroupAvatarImageIn:_groupAvatar matrixSession:self.mxSession];
        
        _groupName.text = _group.summary.profile.name;
        if (!_groupName.text.length)
        {
            _groupName.text = _group.groupId;
        }
        
        _groupDescription.text = _group.summary.profile.shortDescription;
        
        if (_group.users.totalUserCountEstimate == 1)
        {
            _membersCountLabel.text = NSLocalizedStringFromTable(@"group_home_one_member_format", @"Vector", nil);
            _membersCountContainer.hidden = NO;
        }
        else if (_group.users.totalUserCountEstimate > 1)
        {
            _membersCountLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"group_home_multi_members_format", @"Vector", nil), _group.users.totalUserCountEstimate];
            _membersCountContainer.hidden = NO;
        }
        else
        {
            _membersCountLabel.text = nil;
            _membersCountContainer.hidden = YES;
        }
        
        if (_group.rooms.totalRoomCountEstimate == 1)
        {
            _roomsCountLabel.text = NSLocalizedStringFromTable(@"group_home_one_room_format", @"Vector", nil);
            _roomsCountContainer.hidden = NO;
        }
        else if (_group.rooms.totalRoomCountEstimate > 1)
        {
            _roomsCountLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"group_home_multi_rooms_format", @"Vector", nil), _group.rooms.totalRoomCountEstimate];
            _roomsCountContainer.hidden = NO;
        }
        else
        {
            _roomsCountLabel.text = nil;
            _roomsCountContainer.hidden = YES;
        }
        
        _countsContainer.hidden = (_membersCountContainer.isHidden && _roomsCountContainer.isHidden);
        
        if (_group.membership == MXMembershipInvite)
        {
            self.inviteContainer.hidden = NO;
            
            if (_group.inviter)
            {
                NSString *inviter = _group.inviter;
                
                if ([MXTools isMatrixUserIdentifier:inviter])
                {
                    // Get the user that corresponds to this member
                    MXUser *user = [self.mxSession userWithUserId:inviter];
                    if (user.displayname.length)
                    {
                        inviter = user.displayname;
                    }
                }
                
                self.inviteLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"group_invitation_format", @"Vector", nil), inviter];
            }
            else
            {
                self.inviteLabel.text = nil;
            }
            
            [self.inviteContainer layoutIfNeeded];
            
            if (_separatorViewTopConstraint.constant != self.inviteContainer.frame.size.height)
            {
                _separatorViewTopConstraint.constant = self.inviteContainer.frame.size.height;
                [self.view setNeedsLayout];
            }
        }
        else
        {
            self.inviteContainer.hidden = YES;
            if (_separatorViewTopConstraint.constant != 0)
            {
                _separatorViewTopConstraint.constant = 0;
                [self.view setNeedsLayout];
            }
        }
        
        [self refreshGroupLongDescription];
    }
    else
    {
        _groupAvatar.image = nil;
        
        _groupName.text = nil;
        _groupDescription.text = nil;
        
        self.inviteLabel.text = nil;
        _groupLongDescription.text = nil;
        
        self.inviteContainer.hidden = YES;
        
        _separatorViewTopConstraint.constant = 0;
        
        _membersCountLabel.text = nil;
        _roomsCountLabel.text = nil;
        _countsContainer.hidden = YES;
    }
    
    // Round image view for thumbnail
    _groupAvatar.layer.cornerRadius = _groupAvatar.frame.size.width / 2;
    _groupAvatar.clipsToBounds = YES;
    
    _groupAvatar.defaultBackgroundColor = kRiotSecondaryBgColor;
}

- (void)refreshGroupLongDescription
{
    if (_group.summary.profile.longDescription.length)
    {
        // Render this html content in a text view.
        NSArray <NSString*>* allowedHTMLTags = @[
                                                 @"font", // custom to matrix for IRC-style font coloring
                                                 @"del", // for markdown
                                                 @"h1", @"h2", @"h3", @"h4", @"h5", @"h6", @"blockquote", @"p", @"a", @"ul", @"ol",
                                                 @"nl", @"li", @"b", @"i", @"u", @"strong", @"em", @"strike", @"code", @"hr", @"br", @"div",
                                                 @"table", @"thead", @"caption", @"tbody", @"tr", @"th", @"td", @"pre",
                                                 @"img"
                                                 ];
        
        // Do some sanitisation by handling the potential image
        sanitisedGroupLongDescription = [MXKTools sanitiseHTML:_group.summary.profile.longDescription withAllowedHTMLTags:allowedHTMLTags imageHandler:^NSString *(NSString *sourceURL, CGFloat width, CGFloat height) {
            
            NSString *imageURL;
            
            if (width != -1 && height != -1)
            {
                CGSize size = CGSizeMake(width, height);
                imageURL = [self.mxSession.matrixRestClient urlOfContentThumbnail:sourceURL toFitViewSize:size withMethod:MXThumbnailingMethodScale];
            }
            else
            {
                imageURL = [self.mxSession.matrixRestClient urlOfContent:sourceURL];
            }
            
            NSString *mimeType = nil;
            // Check if the extension could not be deduced from url
            if (![imageURL pathExtension].length)
            {
                // Set default mime type if no information is available
                mimeType = @"image/jpeg";
            }
            
            NSString *cacheFilePath = [MXMediaManager cachePathForMediaWithURL:imageURL andType:mimeType inFolder:kMXMediaManagerDefaultCacheFolder];
            if (![[NSFileManager defaultManager] fileExistsAtPath:cacheFilePath])
            {
                [MXMediaManager downloadMediaFromURL:imageURL andSaveAtFilePath:cacheFilePath success:^{
                    
                    [self renderGroupLongDescription];
                    
                } failure:nil];
            }
            
            return [NSString stringWithFormat:@"file://%@", cacheFilePath];
        }];
    }
    else
    {
        sanitisedGroupLongDescription = nil;
    }
    
    [self renderGroupLongDescription];
}

- (void)renderGroupLongDescription
{
    if (sanitisedGroupLongDescription)
    {
        // Using DTCoreText, which renders static string, helps to avoid code injection attacks
        // that could happen with the default HTML renderer of NSAttributedString which is a
        // webview.
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithHTMLData:[sanitisedGroupLongDescription dataUsingEncoding:NSUTF8StringEncoding] options:options documentAttributes:NULL];
        
        // Apply additional treatments
        NSInteger mxIdsBitMask = (MXKTOOLS_USER_IDENTIFIER_BITWISE | MXKTOOLS_ROOM_IDENTIFIER_BITWISE | MXKTOOLS_ROOM_ALIAS_BITWISE | MXKTOOLS_EVENT_IDENTIFIER_BITWISE | MXKTOOLS_GROUP_IDENTIFIER_BITWISE);
        attributedString = [MXKTools createLinksInAttributedString:attributedString forEnabledMatrixIds:mxIdsBitMask];
        
        // Finalize the attributed string by removing DTCoreText artifacts (Trim trailing newlines, replace DTImageTextAttachments...)
        _groupLongDescription.attributedText = [MXKTools removeDTCoreTextArtifacts:attributedString];
        _groupLongDescription.contentOffset = CGPointZero;
    }
    else
    {
        _groupLongDescription.text = nil;
    }
}

- (void)didSelectRoomId:(NSString*)roomId
{
    // Check first if the user already joined this room.
    if ([self.mxSession roomWithRoomId:roomId])
    {
        MXKRoomDataSourceManager *roomDataSourceManager = [MXKRoomDataSourceManager sharedManagerForMatrixSession:self.mxSession];
        [roomDataSourceManager roomDataSourceForRoom:roomId create:YES onComplete:^(MXKRoomDataSource *roomDataSource) {
            // Open this room
            RoomViewController *roomViewController = [RoomViewController roomViewController];
            roomViewController.showMissedDiscussionsBadge = NO;
            [roomViewController displayRoom:roomDataSource];
            [self pushViewController:roomViewController];
        }];
    }
    else
    {
        // Prepare a preview
        RoomPreviewData *roomPreviewData = [[RoomPreviewData alloc] initWithRoomId:roomId andSession:self.mxSession];
        __weak typeof(self) weakSelf = self;
        [self startActivityIndicator];
        
        // Try to get more information about the room before opening its preview
        [roomPreviewData peekInRoom:^(BOOL succeeded) {
            
            if (weakSelf)
            {
                typeof(self) self = weakSelf;
                [self stopActivityIndicator];
                
                // Display the room preview
                RoomViewController *roomViewController = [RoomViewController roomViewController];
                roomViewController.showMissedDiscussionsBadge = NO;
                [roomViewController displayRoomPreview:roomPreviewData];
                [self pushViewController:roomViewController];
            }
            
        }];
    }
}

#pragma mark - Action

- (IBAction)onButtonPressed:(id)sender
{
    if (!currentRequest)
    {
        if (sender == self.rightButton)
        {
            // Accept the invite
            __weak typeof(self) weakSelf = self;
            [self startActivityIndicator];
            
            currentRequest = [self.mxSession acceptGroupInvite:_group.groupId success:^{
                
                if (weakSelf)
                {
                    typeof(self) self = weakSelf;
                    self->currentRequest = nil;
                    [self stopActivityIndicator];
                    
                    [self refreshDisplayWithGroup:[_mxSession groupWithGroupId:_group.groupId]];
                }
                
            } failure:^(NSError *error) {
                
                NSLog(@"[GroupDetailsViewController] join group (%@) failed", _group.groupId);
                
                if (weakSelf)
                {
                    typeof(self) self = weakSelf;
                    self->currentRequest = nil;
                    [self stopActivityIndicator];
                }
                
                // Alert user
                [[AppDelegate theDelegate] showErrorAsAlert:error];
                
            }];
        }
        else if (sender == self.leftButton)
        {
            // Decline the invite
            __weak typeof(self) weakSelf = self;
            [self startActivityIndicator];
            
            currentRequest = [self.mxSession leaveGroup:_group.groupId success:^{
                
                if (weakSelf)
                {
                    typeof(self) self = weakSelf;
                    self->currentRequest = nil;
                    [self stopActivityIndicator];
                    
                    [self withdrawViewControllerAnimated:YES completion:nil];
                }
                
            } failure:^(NSError *error) {
                
                NSLog(@"[GroupDetailsViewController] leave group (%@) failed", _group.groupId);
                
                if (weakSelf)
                {
                    typeof(self) self = weakSelf;
                    self->currentRequest = nil;
                    [self stopActivityIndicator];
                }
                
                // Alert user
                [[AppDelegate theDelegate] showErrorAsAlert:error];
                
            }];
        }
    }
}

- (void)handleTapGesture:(UITapGestureRecognizer*)tapGestureRecognizer
{
    UIView *view = tapGestureRecognizer.view;
    
    if (view == _groupNameMask && _group.summary.profile.name)
    {
        if ([_groupName.text isEqualToString:_group.summary.profile.name])
        {
            // Display group's matrix id
            _groupName.text = _group.groupId;
        }
        else
        {
            // Restore display name
            _groupName.text = _group.summary.profile.name;
        }
    }
    else if (view == _groupAvatarMask)
    {
        // Show the avatar in full screen
        __block MXKImageView * avatarFullScreenView = [[MXKImageView alloc] initWithFrame:CGRectZero];
        avatarFullScreenView.stretchable = YES;
        
        [avatarFullScreenView setRightButtonTitle:[NSBundle mxk_localizedStringForKey:@"ok"] handler:^(MXKImageView* imageView, NSString* buttonTitle) {
            [avatarFullScreenView dismissSelection];
            [avatarFullScreenView removeFromSuperview];
            
            avatarFullScreenView = nil;
            
            isStatusBarHidden = NO;
            // Trigger status bar update
            [self setNeedsStatusBarAppearanceUpdate];
        }];
        
        NSString *avatarURL = [self.mainSession.matrixRestClient urlOfContent:_group.summary.profile.avatarUrl];
        [avatarFullScreenView setImageURL:avatarURL
                                 withType:nil
                      andImageOrientation:UIImageOrientationUp
                             previewImage:self.groupAvatar.image];
        
        [avatarFullScreenView showFullScreen];
        isStatusBarHidden = YES;
        
        // Trigger status bar update
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

#pragma mark - UITextView delegate

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange
{
    BOOL shouldInteractWithURL = YES;
    // Try to catch universal link supported by the app
    
    // When a link refers to a room alias/id, a user id or an event id, the non-ASCII characters (like '#' in room alias) has been escaped
    // to be able to convert it into a legal URL string.
    NSString *absoluteURLString = [URL.absoluteString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    // If the link can be open it by the app, let it do
    if ([Tools isUniversalLink:URL])
    {
        shouldInteractWithURL = NO;
        
        // iOS Patch: fix vector.im urls before using it
        NSURL *fixedURL = [Tools fixURLWithSeveralHashKeys:URL];
        
        [[AppDelegate theDelegate] handleUniversalLinkFragment:fixedURL.fragment];
    }
    // Open a detail screen about the clicked user
    else if ([MXTools isMatrixUserIdentifier:absoluteURLString])
    {
        shouldInteractWithURL = NO;
        
        NSString *userId = absoluteURLString;
        MXKContact *contact;
        // Use the contact detail VC for other users
        MXUser *user = [self.mxSession userWithUserId:userId];
        if (user)
        {
            contact = [[MXKContact alloc] initMatrixContactWithDisplayName:((user.displayname.length > 0) ? user.displayname : user.userId) andMatrixID:user.userId];
        }
        else
        {
            contact = [[MXKContact alloc] initMatrixContactWithDisplayName:userId andMatrixID:userId];
        }
        
        ContactDetailsViewController *contactDetailsViewController = [ContactDetailsViewController contactDetailsViewController];
        contactDetailsViewController.enableVoipCall = NO;
        contactDetailsViewController.contact = contact;
        
        [self pushViewController:contactDetailsViewController];
    }
    // Open the clicked room
    else if ([MXTools isMatrixRoomIdentifier:absoluteURLString] || [MXTools isMatrixRoomAlias:absoluteURLString])
    {
        shouldInteractWithURL = NO;
        
        NSString *roomIdOrAlias = absoluteURLString;
        NSString *roomId;
        
        if ([roomIdOrAlias hasPrefix:@"#"])
        {
            // Check whether the room alias can be translated locally into the room id.
            MXRoom *room = [self.mxSession roomWithAlias:roomIdOrAlias];
            if (room)
            {
                roomId = room.roomId;
            }
        }
        else
        {
            roomId = roomIdOrAlias;
        }
        
        if (roomId)
        {
            [self didSelectRoomId:roomId];
        }
        else
        {
            // The alias may be not part of user's rooms states
            // Ask the HS to resolve the room alias into a room id and then retry
            __weak typeof(self) weakSelf = self;
            [self startActivityIndicator];
            
            [self.mxSession.matrixRestClient roomIDForRoomAlias:roomIdOrAlias success:^(NSString *roomId) {
                
                if (roomId && weakSelf)
                {
                    typeof(self) self = weakSelf;
                    
                    [self stopActivityIndicator];
                    [self didSelectRoomId:roomId];
                }
                
            } failure:^(NSError *error) {
                NSLog(@"[GroupHomeViewController] Error: The home server failed to resolve the room alias (%@)", roomIdOrAlias);
            }];
        }
    }
    // Preview the clicked group
    else if ([MXTools isMatrixGroupIdentifier:absoluteURLString])
    {
        shouldInteractWithURL = NO;
        
        // Open the group or preview it
        NSString *fragment = [NSString stringWithFormat:@"/group/%@", [absoluteURLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        [[AppDelegate theDelegate] handleUniversalLinkFragment:fragment];
    }
    
    return shouldInteractWithURL;
}

@end
