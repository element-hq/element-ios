/*
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

#import "GroupHomeViewController.h"

#import "GeneratedInterface-Swift.h"

#import "ThemeService.h"
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
    
    // Observe kThemeServiceDidChangeThemeNotification to handle user interface theme change.
    id kThemeServiceDidChangeThemeNotificationObserver;
    
    // The options used to load long description html content.
    NSDictionary *options;
    NSString *groupLongDescriptionString;
    
    // The current pushed view controller
    UIViewController *pushedViewController;
}

@property (nonatomic, readonly) DTHTMLAttributedStringBuilderWillFlushCallback longDescriptionSanitizationCallback;

@property (nonatomic) AnalyticsScreenTracker *screenTracker;

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
    
    // Set up sanitization for the long description
    NSArray<NSString *> *allowedHTMLTags = @[
        @"font", // custom to matrix for IRC-style font coloring
        @"del", // for markdown
        @"body", // added internally by DTCoreText
        @"h1", @"h2", @"h3", @"h4", @"h5", @"h6", @"blockquote", @"p", @"a", @"ul", @"ol",
        @"nl", @"li", @"b", @"i", @"u", @"strong", @"em", @"strike", @"code", @"hr", @"br", @"div",
        @"table", @"thead", @"caption", @"tbody", @"tr", @"th", @"td", @"pre",
        @"img"
    ];
    
    MXWeakify(self);
    _longDescriptionSanitizationCallback = ^(DTHTMLElement *element) {
        MXStrongifyAndReturnIfNil(self);
        [element sanitizeWith:allowedHTMLTags bodyFont:self->_groupLongDescription.font imageHandler:[self groupLongDescriptionImageHandler]];
    };
    
    self.screenTracker = [[AnalyticsScreenTracker alloc] initWithScreen:AnalyticsScreenGroup];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.leftButton setTitle:[VectorL10n decline] forState:UIControlStateNormal];
    [self.leftButton setTitle:[VectorL10n decline] forState:UIControlStateHighlighted];
    [self.rightButton setTitle:[VectorL10n join] forState:UIControlStateNormal];
    [self.rightButton setTitle:[VectorL10n join] forState:UIControlStateHighlighted];
    
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
    kThemeServiceDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kThemeServiceDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self userInterfaceThemeDidChange];
        
    }];
    [self userInterfaceThemeDidChange];
}

- (void)userInterfaceThemeDidChange
{
    [ThemeService.shared.theme applyStyleOnNavigationBar:self.navigationController.navigationBar];

    self.activityIndicator.backgroundColor = ThemeService.shared.theme.overlayBackgroundColor;
    
    self.view.backgroundColor = ThemeService.shared.theme.backgroundColor;
    self.mainHeaderContainer.backgroundColor = ThemeService.shared.theme.headerBackgroundColor;
    
    _groupName.textColor = ThemeService.shared.theme.textPrimaryColor;
    
    _groupDescription.textColor = ThemeService.shared.theme.baseTextSecondaryColor;
    _groupDescription.numberOfLines = 0;
    
    self.inviteLabel.textColor = ThemeService.shared.theme.baseTextSecondaryColor;
    self.inviteLabel.numberOfLines = 0;
    
    self.separatorView.backgroundColor = ThemeService.shared.theme.lineBreakColor;
    
    [self.leftButton.layer setCornerRadius:5];
    self.leftButton.clipsToBounds = YES;
    self.leftButton.backgroundColor = ThemeService.shared.theme.tintColor;
    
    [self.rightButton.layer setCornerRadius:5];
    self.rightButton.clipsToBounds = YES;
    self.rightButton.backgroundColor = ThemeService.shared.theme.tintColor;
    
    if (_groupLongDescription)
    {
        _groupLongDescription.textColor = ThemeService.shared.theme.textSecondaryColor;
        _groupLongDescription.tintColor = ThemeService.shared.theme.tintColor;
        
        // Update HTML loading options
        NSUInteger bgColor = [MXKTools rgbValueWithColor:ThemeService.shared.theme.headerBackgroundColor];
        NSString *defaultCSS = [NSString stringWithFormat:@" \
                      pre,code { \
                      background-color: #%06lX; \
                      display: inline; \
                      font-family: monospace; \
                      white-space: pre; \
                      -coretext-fontname: Menlo-Regular; \
                      font-size: small; \
                      }", (unsigned long)bgColor];
        
        // Apply the css style with some sanitisation.
        options = @{
                    DTUseiOS6Attributes: @(YES),              // Enable it to be able to display the attributed string in a UITextView
                    DTDefaultFontFamily: _groupLongDescription.font.familyName,
                    DTDefaultFontName: _groupLongDescription.font.fontName,
                    DTDefaultFontSize: @(_groupLongDescription.font.pointSize),
                    DTDefaultTextColor: _groupLongDescription.textColor,
                    DTDefaultLinkDecoration: @(NO),
                    DTDefaultStyleSheet: [[DTCSSStylesheet alloc] initWithStyleBlock:defaultCSS],
                    DTWillFlushBlockCallBack: self.longDescriptionSanitizationCallback
                    };
    }

    [self setNeedsStatusBarAppearanceUpdate];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return ThemeService.shared.theme.statusBarStyle;
}

- (BOOL)prefersStatusBarHidden
{
    // Return the current status bar visibility.
    return isStatusBarHidden;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.screenTracker trackScreen];

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
            [self refreshDisplayWithGroup:self->_group];
        };
        
        // Trigger a refresh on the group summary.
        [self.mxSession updateGroupSummary:self->_group success:(isPreview ? success : nil) failure:^(NSError *error) {
            
            MXLogDebug(@"[GroupHomeViewController] viewWillAppear: group summary update failed %@", self->_group.groupId);
            
        }];
        // Trigger a refresh on the group members (ignore here the invited users).
        [self.mxSession updateGroupUsers:self->_group success:(isPreview ? success : nil) failure:^(NSError *error) {
            
            MXLogDebug(@"[GroupHomeViewController] viewWillAppear: group members update failed %@", self->_group.groupId);
            
        }];
        // Trigger a refresh on the group rooms.
        [self.mxSession updateGroupRooms:self->_group success:(isPreview ? success : nil) failure:^(NSError *error) {
            
            MXLogDebug(@"[GroupHomeViewController] viewWillAppear: group rooms update failed %@", self->_group.groupId);
            
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
    
    if (kThemeServiceDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kThemeServiceDidChangeThemeNotificationObserver];
        kThemeServiceDidChangeThemeNotificationObserver = nil;
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
            _membersCountLabel.text = [VectorL10n groupHomeOneMemberFormat];
            _membersCountContainer.hidden = NO;
        }
        else if (_group.users.totalUserCountEstimate > 1)
        {
            _membersCountLabel.text = [VectorL10n groupHomeMultiMembersFormat:_group.users.totalUserCountEstimate];
            _membersCountContainer.hidden = NO;
        }
        else
        {
            _membersCountLabel.text = nil;
            _membersCountContainer.hidden = YES;
        }
        
        if (_group.rooms.totalRoomCountEstimate == 1)
        {
            _roomsCountLabel.text = [VectorL10n groupHomeOneRoomFormat];
            _roomsCountContainer.hidden = NO;
        }
        else if (_group.rooms.totalRoomCountEstimate > 1)
        {
            _roomsCountLabel.text = [VectorL10n groupHomeMultiRoomsFormat:_group.rooms.totalRoomCountEstimate];
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
                
                self.inviteLabel.text = [VectorL10n groupInvitationFormat:inviter];
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
    
    _groupAvatar.defaultBackgroundColor = ThemeService.shared.theme.headerBackgroundColor;
}

- (void)refreshGroupLongDescription
{
    if (_group.summary.profile.longDescription.length)
    {
        groupLongDescriptionString = _group.summary.profile.longDescription;
    }
    else
    {
        groupLongDescriptionString = nil;
    }
    
    [self renderGroupLongDescription];
}

- (void)renderGroupLongDescription
{
    if (groupLongDescriptionString)
    {
        // Using DTCoreText, which renders static string, helps to avoid code injection attacks
        // that could happen with the default HTML renderer of NSAttributedString which is a
        // webview.
        // The supplied options include a callback to sanitize html tags and load image data.
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithHTMLData:[groupLongDescriptionString dataUsingEncoding:NSUTF8StringEncoding] options:options documentAttributes:NULL];
        
        // Apply additional treatments
        NSInteger mxIdsBitMask = (MXKTOOLS_USER_IDENTIFIER_BITWISE | MXKTOOLS_ROOM_IDENTIFIER_BITWISE | MXKTOOLS_ROOM_ALIAS_BITWISE | MXKTOOLS_EVENT_IDENTIFIER_BITWISE | MXKTOOLS_GROUP_IDENTIFIER_BITWISE);

        NSMutableAttributedString *mutableStr = [[NSMutableAttributedString alloc] initWithAttributedString:attributedString];
        [MXKTools createLinksInMutableAttributedString:mutableStr forEnabledMatrixIds:mxIdsBitMask];
        [MXKTools removeDTCoreTextArtifacts:mutableStr];
        
        // Finalize the attributed string by removing DTCoreText artifacts (Trim trailing newlines, replace DTImageTextAttachments...)
        _groupLongDescription.attributedText = mutableStr;
        _groupLongDescription.contentOffset = CGPointZero;
    }
    else
    {
        _groupLongDescription.text = nil;
    }
}

- (NSURL *(^)(NSString *sourceURL, CGFloat width, CGFloat height))groupLongDescriptionImageHandler
{
    MXWeakify(self);
    return ^NSURL *(NSString *sourceURL, CGFloat width, CGFloat height) {
        
        MXStrongifyAndReturnValueIfNil(self, nil);
        NSURL *localSourceURL;
        
        if (width != -1 && height != -1)
        {
            CGSize size = CGSizeMake(width, height);
            // Build the cache path for the a thumbnail of this image.
            NSString *cacheFilePath = [MXMediaManager thumbnailCachePathForMatrixContentURI:sourceURL
                                                                          andType:nil
                                                                         inFolder:kMXMediaManagerDefaultCacheFolder
                                                                    toFitViewSize:size
                                                                       withMethod:MXThumbnailingMethodScale];
            // Check whether the provided URL is a valid Matrix Content URI.
            if (cacheFilePath)
            {
                // Download the thumbnail if it is not already stored in the cache.
                if (![[NSFileManager defaultManager] fileExistsAtPath:cacheFilePath])
                {
                    MXWeakify(self);
                    [self.mxSession.mediaManager downloadThumbnailFromMatrixContentURI:sourceURL
                                                                              withType:nil
                                                                              inFolder:kMXMediaManagerDefaultCacheFolder
                                                                         toFitViewSize:size
                                                                            withMethod:MXThumbnailingMethodScale
                                                                               success:^(NSString *outputFilePath) {
                                                                                   MXStrongifyAndReturnIfNil(self);
                                                                                   [self refreshGroupLongDescription];
                                                                               }
                                                                               failure:nil];
                }
                else
                {
                    // Update the local url
                    localSourceURL = [NSURL fileURLWithPath:cacheFilePath];
                }
            }
        }
        else
        {
            // Build the cache path for this image.
            NSString* cacheFilePath = [MXMediaManager cachePathForMatrixContentURI:sourceURL
                                                             andType:nil
                                                            inFolder:kMXMediaManagerDefaultCacheFolder];
            
            // Check whether the provided URL is a valid Matrix Content URI.
            if (cacheFilePath)
            {
                // Download the image if it is not already stored in the cache.
                if (![[NSFileManager defaultManager] fileExistsAtPath:cacheFilePath])
                {
                    MXWeakify(self);
                    [self.mxSession.mediaManager downloadMediaFromMatrixContentURI:sourceURL
                                                                          withType:nil
                                                                          inFolder:kMXMediaManagerDefaultCacheFolder
                                                                           success:^(NSString *outputFilePath) {
                                                                               MXStrongifyAndReturnIfNil(self);
                                                                               [self refreshGroupLongDescription];
                                                                           }
                                                                           failure:nil];
                }
                else
                {
                    // Update the local path
                    localSourceURL = [NSURL fileURLWithPath:cacheFilePath];
                }
            }
        }
        return localSourceURL;
        
    };
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
                    
                    [self refreshDisplayWithGroup:[self->_mxSession groupWithGroupId:self->_group.groupId]];
                }
                
            } failure:^(NSError *error) {
                
                MXLogDebug(@"[GroupDetailsViewController] join group (%@) failed", self->_group.groupId);
                
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
                
                MXLogDebug(@"[GroupDetailsViewController] leave group (%@) failed", self->_group.groupId);
                
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
        
        MXWeakify(self);
        [avatarFullScreenView setRightButtonTitle:[VectorL10n ok] handler:^(MXKImageView* imageView, NSString* buttonTitle) {
            
            MXStrongifyAndReturnIfNil(self);
            [avatarFullScreenView dismissSelection];
            [avatarFullScreenView removeFromSuperview];
            
            avatarFullScreenView = nil;
            
            self->isStatusBarHidden = NO;
            // Trigger status bar update
            [self setNeedsStatusBarAppearanceUpdate];
        }];
        
        [avatarFullScreenView setImageURI:_group.summary.profile.avatarUrl
                                 withType:nil
                      andImageOrientation:UIImageOrientationUp
                             previewImage:self.groupAvatar.image
                             mediaManager:_mxSession.mediaManager];
        
        [avatarFullScreenView showFullScreen];
        isStatusBarHidden = YES;
        
        // Trigger status bar update
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

#pragma mark - UITextView delegate

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange
{
    BOOL shouldInteractWithURL = YES;
    // Try to catch universal link supported by the app
    
    // When a link refers to a room alias/id, a user id or an event id, the non-ASCII characters (like '#' in room alias) has been escaped
    // to be able to convert it into a legal URL string.
    NSString *absoluteURLString = [URL.absoluteString stringByRemovingPercentEncoding];
    
    // If the link can be open it by the app, let it do
    if ([Tools isUniversalLink:URL])
    {
        shouldInteractWithURL = NO;
                        
        [[AppDelegate theDelegate] handleUniversalLinkURL:URL];
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
        
        ContactDetailsViewController *contactDetailsViewController = [ContactDetailsViewController instantiate];
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
            
            [self.mxSession.matrixRestClient resolveRoomAlias:roomIdOrAlias success:^(MXRoomAliasResolution *resolution) {
                if (roomId && weakSelf)
                {
                    typeof(self) self = weakSelf;
                    
                    [self stopActivityIndicator];
                    [self didSelectRoomId:resolution.roomId];
                }
                
            } failure:^(NSError *error) {
                MXLogDebug(@"[GroupHomeViewController] Error: The homeserver failed to resolve the room alias (%@)", roomIdOrAlias);
            }];
        }
    }
    // Preview the clicked group
    else if ([MXTools isMatrixGroupIdentifier:absoluteURLString])
    {
        shouldInteractWithURL = NO;
        
        // Open the group or preview it
        NSString *fragment = [NSString stringWithFormat:@"/group/%@",
                        [MXTools encodeURIComponent:absoluteURLString]];
        [[AppDelegate theDelegate] handleUniversalLinkFragment:fragment fromURL:URL];
    }
    
    return shouldInteractWithURL;
}
#pragma clang diagnostic pop

@end
