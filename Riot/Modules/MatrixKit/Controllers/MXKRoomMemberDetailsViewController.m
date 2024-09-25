/*
Copyright 2018-2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKRoomMemberDetailsViewController.h"

@import MatrixSDK.MXMediaManager;

#import "MXKTableViewCellWithButtons.h"

#import "NSBundle+MatrixKit.h"

#import "MXKAppSettings.h"

#import "MXKConstants.h"

#import "MXKSwiftHeader.h"

@interface MXKRoomMemberDetailsViewController ()
{
    id membersListener;
    
    // mask view while processing a request
    UIActivityIndicatorView * pendingMaskSpinnerView;
    
    // Observe left rooms
    id leaveRoomNotificationObserver;
    
    // Observe kMXRoomDidFlushDataNotification to take into account the updated room members when the room history is flushed.
    id roomDidFlushDataNotificationObserver;

    // Cache for the room live timeline
    id<MXEventTimeline> mxRoomLiveTimeline;
}

@end

@implementation MXKRoomMemberDetailsViewController
@synthesize mxRoom;

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([MXKRoomMemberDetailsViewController class])
                          bundle:[NSBundle bundleForClass:[MXKRoomMemberDetailsViewController class]]];
}

+ (instancetype)roomMemberDetailsViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass([MXKRoomMemberDetailsViewController class])
                                          bundle:[NSBundle bundleForClass:[MXKRoomMemberDetailsViewController class]]];
}

- (void)finalizeInit
{
    [super finalizeInit];
    
    actionsArray = [[NSMutableArray alloc] init];
    _enableLeave = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Check whether the view controller has been pushed via storyboard
    if (!self.tableView)
    {
        // Instantiate view controller objects
        [[[self class] nib] instantiateWithOwner:self options:nil];
    }
    
    // ignore useless update
    if (_mxRoomMember)
    {
        [self initObservers];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self initObservers];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self removeObservers];
}

- (void)destroy
{
    // close any pending actionsheet
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
    
    [self removePendingActionMask];
    
    [self removeObservers];
    
    _delegate = nil;
    _mxRoomMember = nil;
    
    actionsArray = nil;
    
    [super destroy];
}

#pragma mark -

- (void)displayRoomMember:(MXRoomMember*)roomMember withMatrixRoom:(MXRoom*)room
{
    [self removeObservers];
    
    mxRoom = room;

    MXWeakify(self);
    [mxRoom liveTimeline:^(id<MXEventTimeline> liveTimeline) {
        MXStrongifyAndReturnIfNil(self);

        self->mxRoomLiveTimeline = liveTimeline;

        // Update matrix session associated to the view controller
        NSArray *mxSessions = self.mxSessions;
        for (MXSession *mxSession in mxSessions) {
            [self removeMatrixSession:mxSession];
        }
        [self addMatrixSession:room.mxSession];

        self->_mxRoomMember = roomMember;

        [self initObservers];
    }];
}

- (id<MXEventTimeline> )mxRoomLiveTimeline
{
    // @TODO(async-state): Just here for dev
    NSAssert(mxRoomLiveTimeline, @"[MXKRoomMemberDetailsViewController] Room live timeline must be preloaded before accessing to MXKRoomMemberDetailsViewController.mxRoomLiveTimeline");
    return mxRoomLiveTimeline;
}

- (UIImage*)picturePlaceholder
{
    return [NSBundle mxk_imageFromMXKAssetsBundleWithName:@"default-profile"];
}

- (void)setEnableMention:(BOOL)enableMention
{
    if (_enableMention != enableMention)
    {
        _enableMention = enableMention;
        
        [self updateMemberInfo];
    }
}

- (void)setEnableVoipCall:(BOOL)enableVoipCall
{
    if (_enableVoipCall != enableVoipCall)
    {
        _enableVoipCall = enableVoipCall;
        
        [self updateMemberInfo];
    }
}

- (void)setEnableLeave:(BOOL)enableLeave
{
    if (_enableLeave != enableLeave)
    {
        _enableLeave = enableLeave;
        
        [self updateMemberInfo];
    }
}

- (IBAction)onActionButtonPressed:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]])
    {
        // Check whether an action is already in progress
        if ([self hasPendingAction])
        {
            return;
        }
        
        UIButton *button = (UIButton*)sender;
        
        switch (button.tag)
        {
            case MXKRoomMemberDetailsActionInvite:
            {
                [self addPendingActionMask];
                [mxRoom inviteUser:_mxRoomMember.userId
                           success:^{
                               
                               [self removePendingActionMask];
                               
                           } failure:^(NSError *error) {
                               
                               [self removePendingActionMask];
                               MXLogDebug(@"[MXKRoomMemberDetailsVC] Invite %@ failed", self->_mxRoomMember.userId);
                               // Notify MatrixKit user
                               NSString *myUserId = self.mainSession.myUser.userId;
                               [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error userInfo:myUserId ? @{kMXKErrorUserIdKey: myUserId} : nil];
                               
                           }];
                break;
            }
            case MXKRoomMemberDetailsActionLeave:
            {
                [self addPendingActionMask];
                [self.mxRoom leave:^{
                    
                    [self removePendingActionMask];
                    [self withdrawViewControllerAnimated:YES completion:nil];
                    
                } failure:^(NSError *error) {
                    
                    [self removePendingActionMask];
                    MXLogDebug(@"[MXKRoomMemberDetailsVC] Leave room %@ failed", self->mxRoom.roomId);
                    // Notify MatrixKit user
                    NSString *myUserId = self.mainSession.myUser.userId;
                    [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error userInfo:myUserId ? @{kMXKErrorUserIdKey: myUserId} : nil];
                    
                }];
                break;
            }
            case MXKRoomMemberDetailsActionKick:
            {
                [self addPendingActionMask];
                [mxRoom kickUser:_mxRoomMember.userId
                          reason:nil
                         success:^{
                             
                             [self removePendingActionMask];
                             // Pop/Dismiss the current view controller if the left members are hidden
                             if (![[MXKAppSettings standardAppSettings] showLeftMembersInRoomMemberList])
                             {
                                 [self withdrawViewControllerAnimated:YES completion:nil];
                             }
                             
                         } failure:^(NSError *error) {
                             
                             [self removePendingActionMask];
                             MXLogDebug(@"[MXKRoomMemberDetailsVC] Kick %@ failed", self->_mxRoomMember.userId);
                             // Notify MatrixKit user
                             NSString *myUserId = self.mainSession.myUser.userId;
                             [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error userInfo:myUserId ? @{kMXKErrorUserIdKey: myUserId} : nil];
                             
                         }];
                break;
            }
            case MXKRoomMemberDetailsActionBan:
            {
                [self addPendingActionMask];
                [mxRoom banUser:_mxRoomMember.userId
                         reason:nil
                        success:^{
                            
                            [self removePendingActionMask];
                            
                        } failure:^(NSError *error) {
                            
                            [self removePendingActionMask];
                            MXLogDebug(@"[MXKRoomMemberDetailsVC] Ban %@ failed", self->_mxRoomMember.userId);
                            // Notify MatrixKit user
                            NSString *myUserId = self.mainSession.myUser.userId;
                            [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error userInfo:myUserId ? @{kMXKErrorUserIdKey: myUserId} : nil];
                            
                        }];
                break;
            }
            case MXKRoomMemberDetailsActionUnban:
            {
                [self addPendingActionMask];
                [mxRoom unbanUser:_mxRoomMember.userId
                          success:^{
                              
                              [self removePendingActionMask];
                              
                          } failure:^(NSError *error) {
                              
                              [self removePendingActionMask];
                              MXLogDebug(@"[MXKRoomMemberDetailsVC] Unban %@ failed", self->_mxRoomMember.userId);
                              // Notify MatrixKit user
                              NSString *myUserId = self.mainSession.myUser.userId;
                              [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error userInfo:myUserId ? @{kMXKErrorUserIdKey: myUserId} : nil];
                              
                          }];
                break;
            }
            case MXKRoomMemberDetailsActionIgnore:
            {
                // Prompt user to ignore content from this user
                MXWeakify(self);
                
                if (currentAlert)
                {
                    [currentAlert dismissViewControllerAnimated:NO completion:nil];
                }
                
                currentAlert = [UIAlertController alertControllerWithTitle:[VectorL10n roomMemberIgnorePrompt] message:nil preferredStyle:UIAlertControllerStyleAlert];
                
                [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n yes]
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {
                                                                   
                                                                   MXStrongifyAndReturnIfNil(self);
                                                                   
                                                                   self->currentAlert = nil;
                                                                   
                                                                   // Add the user to the blacklist: ignored users
                                                                   [self addPendingActionMask];
                                                                   
                                                                   MXWeakify(self);
                                                                   
                                                                   [self.mainSession ignoreUsers:@[self.mxRoomMember.userId]
                                                                                         success:^{
                                                                                             
                                                                                             MXStrongifyAndReturnIfNil(self);
                                                                                             
                                                                                             [self removePendingActionMask];
                                                                                             
                                                                                         } failure:^(NSError *error) {
                                                                                             
                                                                                             MXStrongifyAndReturnIfNil(self);
                                                                                             
                                                                                             [self removePendingActionMask];
                                                                                             MXLogDebug(@"[MXKRoomMemberDetailsVC] Ignore %@ failed", self.mxRoomMember.userId);
                                                                                             
                                                                                             // Notify MatrixKit user
                                                                                             NSString *myUserId = self.mainSession.myUser.userId;
                                                                                             [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error userInfo:myUserId ? @{kMXKErrorUserIdKey: myUserId} : nil];
                                                                                             
                                                                                         }];
                                                                   
                                                               }]];
                
                [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n no]
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {
                                                                   
                                                                   MXStrongifyAndReturnIfNil(self);
                                                                   
                                                                   self->currentAlert = nil;
                                                               }]];
                
                [self presentViewController:currentAlert animated:YES completion:nil];
                break;
            }
            case MXKRoomMemberDetailsActionUnignore:
            {
                // Remove the member from the ignored user list.
                [self addPendingActionMask];
                
                MXWeakify(self);
                
                [self.mainSession unIgnoreUsers:@[self.mxRoomMember.userId]
                                            success:^{
                                                
                                                MXStrongifyAndReturnIfNil(self);
                                                [self removePendingActionMask];

                                            } failure:^(NSError *error) {

                                                MXStrongifyAndReturnIfNil(self);
                                                
                                                [self removePendingActionMask];
                                                MXLogDebug(@"[MXKRoomMemberDetailsVC] Unignore %@ failed", self.mxRoomMember.userId);

                                                // Notify MatrixKit user
                                                NSString *myUserId = self.mainSession.myUser.userId;
                                                [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error userInfo:myUserId ? @{kMXKErrorUserIdKey: myUserId} : nil];

                                            }];
                break;
            }
            case MXKRoomMemberDetailsActionSetDefaultPowerLevel:
            {
                break;
            }
            case MXKRoomMemberDetailsActionSetModerator:
            {
                break;
            }
            case MXKRoomMemberDetailsActionSetAdmin:
            {
                break;
            }
            case MXKRoomMemberDetailsActionSetCustomPowerLevel:
            {
                [self updateUserPowerLevel];
                break;
            }
            case MXKRoomMemberDetailsActionStartChat:
            {
                if (self.delegate)
                {
                    [self addPendingActionMask];
                    
                    [self.delegate roomMemberDetailsViewController:self startChatWithMemberId:_mxRoomMember.userId completion:^{
                        
                        [self removePendingActionMask];
                    }];
                }
                break;
            }
            case MXKRoomMemberDetailsActionStartVoiceCall:
            case MXKRoomMemberDetailsActionStartVideoCall:
            {
                BOOL isVideoCall = (button.tag == MXKRoomMemberDetailsActionStartVideoCall);
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(roomMemberDetailsViewController:placeVoipCallWithMemberId:andVideo:)])
                {
                    [self addPendingActionMask];
                    
                    [self.delegate roomMemberDetailsViewController:self placeVoipCallWithMemberId:_mxRoomMember.userId andVideo:isVideoCall];
                    
                    [self removePendingActionMask];
                }
                else
                {
                    [self addPendingActionMask];
                    
                    MXRoom* directRoom = [self.mainSession directJoinedRoomWithUserId:_mxRoomMember.userId];
                    
                    // Place the call directly if the room exists
                    if (directRoom)
                    {
                        [directRoom placeCallWithVideo:isVideoCall success:nil failure:nil];
                        [self removePendingActionMask];
                    }
                    else
                    {
                        // Create a new room
                        MXRoomCreationParameters *roomCreationParameters = [MXRoomCreationParameters parametersForDirectRoomWithUser:_mxRoomMember.userId];
                        [self.mainSession createRoomWithParameters:roomCreationParameters success:^(MXRoom *room) {

                            // Delay the call in order to be sure that the room is ready
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [room placeCallWithVideo:isVideoCall success:nil failure:nil];
                                [self removePendingActionMask];
                            });

                        } failure:^(NSError *error) {

                            MXLogDebug(@"[MXKRoomMemberDetailsVC] Create room failed");
                            [self removePendingActionMask];
                            // Notify MatrixKit user
                            NSString *myUserId = self.mainSession.myUser.userId;
                            [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error userInfo:myUserId ? @{kMXKErrorUserIdKey: myUserId} : nil];

                        }];
                    }
                }
                break;
            }
            case MXKRoomMemberDetailsActionMention:
            {
                // Sanity check
                if (_delegate && [_delegate respondsToSelector:@selector(roomMemberDetailsViewController:mention:)])
                {
                    id<MXKRoomMemberDetailsViewControllerDelegate> delegate = _delegate;
                    MXRoomMember *member = _mxRoomMember;
                    
                    // Withdraw the current view controller, and let the delegate mention the member
                    [self withdrawViewControllerAnimated:YES completion:^{
                        
                        [delegate roomMemberDetailsViewController:self mention:member];

                    }];
                }
                break;
            }
            default:
                break;
        }
    }
}

#pragma mark - Internals

- (void)initObservers
{
    // Remove any pending observers
    [self removeObservers];
    
    if (mxRoom)
    {
        // Observe room's members update
        NSArray *mxMembersEvents = @[kMXEventTypeStringRoomMember, kMXEventTypeStringRoomPowerLevels];
        self->membersListener = [mxRoom listenToEventsOfTypes:mxMembersEvents onEvent:^(MXEvent *event, MXTimelineDirection direction, id customObject) {

            // consider only live event
            if (direction == MXTimelineDirectionForwards)
            {
                [self refreshRoomMember];
            }
        }];

        // Observe kMXSessionWillLeaveRoomNotification to be notified if the user leaves the current room.
        leaveRoomNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXSessionWillLeaveRoomNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
            
            // Check whether the user will leave the room related to the displayed member
            if (notif.object == self.mainSession)
            {
                NSString *roomId = notif.userInfo[kMXSessionNotificationRoomIdKey];
                if (roomId && [roomId isEqualToString:self->mxRoom.roomId])
                {
                    // We must remove the current view controller.
                    [self withdrawViewControllerAnimated:YES completion:nil];
                }
            }
        }];
        
        // Observe room history flush (sync with limited timeline, or state event redaction)
        roomDidFlushDataNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXRoomDidFlushDataNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
            
            MXRoom *room = notif.object;
            if (self.mainSession == room.mxSession && [self->mxRoom.roomId isEqualToString:room.roomId])
            {
                // The existing room history has been flushed during server sync.
                // Take into account the updated room members list by updating the room member instance
                [self refreshRoomMember];
            }
            
        }];
    }
    
    [self updateMemberInfo];
}

- (void)removeObservers
{
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
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (membersListener && mxRoom)
    {
        MXWeakify(self);
        [mxRoom liveTimeline:^(id<MXEventTimeline> liveTimeline) {
            MXStrongifyAndReturnIfNil(self);

            [liveTimeline removeListener:self->membersListener];
            self->membersListener = nil;
        }];
    }
}

- (void)refreshRoomMember
{
    // Hide potential action sheet
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
    
    MXRoomMember* nextRoomMember = nil;
    
    // get the updated memmber
    NSArray<MXRoomMember *> *membersList = self.mxRoomLiveTimeline.state.members.members;
    for (MXRoomMember* member in membersList)
    {
        if ([member.userId isEqualToString:_mxRoomMember.userId])
        {
            nextRoomMember = member;
            break;
        }
    }
    
    // does the member still exist ?
    if (nextRoomMember)
    {
        // Refresh member
        _mxRoomMember = nextRoomMember;
        [self updateMemberInfo];
    }
    else
    {
        [self withdrawViewControllerAnimated:YES completion:nil];
    }
}

- (void)updateMemberInfo
{
    self.title = _mxRoomMember.displayname ? _mxRoomMember.displayname : _mxRoomMember.userId;
    
    // set the thumbnail info
    self.memberThumbnail.contentMode = UIViewContentModeScaleAspectFill;
    self.memberThumbnail.defaultBackgroundColor = [UIColor clearColor];
    [self.memberThumbnail.layer setCornerRadius:self.memberThumbnail.frame.size.width / 2];
    [self.memberThumbnail setClipsToBounds:YES];
    
    self.memberThumbnail.mediaFolder = kMXMediaManagerAvatarThumbnailFolder;
    self.memberThumbnail.enableInMemoryCache = YES;
    [self.memberThumbnail setImageURI:_mxRoomMember.avatarUrl
                             withType:nil
                  andImageOrientation:UIImageOrientationUp
                        toFitViewSize:self.memberThumbnail.frame.size
                           withMethod:MXThumbnailingMethodCrop
                         previewImage:self.picturePlaceholder
                           mediaManager:self.mainSession.mediaManager];
    
    self.roomMemberMatrixInfo.text = _mxRoomMember.userId;
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Check user's power level before allowing an action (kick, ban, ...)
    MXRoomPowerLevels *powerLevels = [self.mxRoomLiveTimeline.state powerLevels];
    NSInteger memberPowerLevel = [powerLevels powerLevelOfUserWithUserID:_mxRoomMember.userId];
    NSInteger oneSelfPowerLevel = [powerLevels powerLevelOfUserWithUserID:self.mainSession.myUser.userId];
    
    [actionsArray removeAllObjects];
    
    // Consider the case of the user himself
    if ([_mxRoomMember.userId isEqualToString:self.mainSession.myUser.userId])
    {
        if (_enableLeave)
        {
            [actionsArray addObject:@(MXKRoomMemberDetailsActionLeave)];
        }
        
        if (oneSelfPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kMXEventTypeStringRoomPowerLevels])
        {
            [actionsArray addObject:@(MXKRoomMemberDetailsActionSetCustomPowerLevel)];
        }
    }
    else if (_mxRoomMember)
    {
        if (_enableVoipCall)
        {
            // Offer voip call options
            [actionsArray addObject:@(MXKRoomMemberDetailsActionStartVoiceCall)];
            [actionsArray addObject:@(MXKRoomMemberDetailsActionStartVideoCall)];
        }
        
        // Consider membership of the selected member
        switch (_mxRoomMember.membership)
        {
            case MXMembershipInvite:
            case MXMembershipJoin:
            {
                // Check conditions to be able to kick someone
                if (oneSelfPowerLevel >= [powerLevels kick] && oneSelfPowerLevel > memberPowerLevel)
                {
                    [actionsArray addObject:@(MXKRoomMemberDetailsActionKick)];
                }
                // Check conditions to be able to ban someone
                if (oneSelfPowerLevel >= [powerLevels ban] && oneSelfPowerLevel > memberPowerLevel)
                {
                    [actionsArray addObject:@(MXKRoomMemberDetailsActionBan)];
                }
                
                // Check whether the option Ignore may be presented
                if (_mxRoomMember.membership == MXMembershipJoin)
                {
                    // is he already ignored ?
                    if (![self.mainSession isUserIgnored:_mxRoomMember.userId])
                    {
                        [actionsArray addObject:@(MXKRoomMemberDetailsActionIgnore)];
                    }
                    else
                    {
                        [actionsArray addObject:@(MXKRoomMemberDetailsActionUnignore)];
                    }
                }
                break;
            }
            case MXMembershipLeave:
            {
                // Check conditions to be able to invite someone
                if (oneSelfPowerLevel >= [powerLevels invite])
                {
                    [actionsArray addObject:@(MXKRoomMemberDetailsActionInvite)];
                }
                // Check conditions to be able to ban someone
                if (oneSelfPowerLevel >= [powerLevels ban] && oneSelfPowerLevel > memberPowerLevel)
                {
                    [actionsArray addObject:@(MXKRoomMemberDetailsActionBan)];
                }
                break;
            }
            case MXMembershipBan:
            {
                // Check conditions to be able to unban someone
                if (oneSelfPowerLevel >= [powerLevels ban] && oneSelfPowerLevel > memberPowerLevel)
                {
                    [actionsArray addObject:@(MXKRoomMemberDetailsActionUnban)];
                }
                break;
            }
            default:
            {
                break;
            }
        }
        
        // update power level
        if (oneSelfPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kMXEventTypeStringRoomPowerLevels] && oneSelfPowerLevel > memberPowerLevel)
        {
            [actionsArray addObject:@(MXKRoomMemberDetailsActionSetCustomPowerLevel)];
        }
        
        // offer to start a new chat only if the room is not the first direct chat with this user
        // it does not make sense : it would open the same room
        MXRoom* directRoom = [self.mainSession directJoinedRoomWithUserId:_mxRoomMember.userId];
        if (!directRoom || (![directRoom.roomId isEqualToString:mxRoom.roomId]))
        {
            [actionsArray addObject:@(MXKRoomMemberDetailsActionStartChat)];
        }
    }
    
    if (_enableMention)
    {
        // Add mention option
        [actionsArray addObject:@(MXKRoomMemberDetailsActionMention)];
    }
    
    return (actionsArray.count + 1) / 2;
}

- (NSString*)actionButtonTitle:(MXKRoomMemberDetailsAction)action
{
    NSString *title;
    
    switch (action)
    {
        case MXKRoomMemberDetailsActionInvite:
            title = [VectorL10n invite];
            break;
        case MXKRoomMemberDetailsActionLeave:
            title = [VectorL10n leave];
            break;
        case MXKRoomMemberDetailsActionKick:
            title = [VectorL10n kick];
            break;
        case MXKRoomMemberDetailsActionBan:
            title = [VectorL10n ban];
            break;
        case MXKRoomMemberDetailsActionUnban:
            title = [VectorL10n unban];
            break;
        case MXKRoomMemberDetailsActionIgnore:
            title = [VectorL10n ignore];
            break;
        case MXKRoomMemberDetailsActionUnignore:
            title = [VectorL10n unignore];
            break;
        case MXKRoomMemberDetailsActionSetDefaultPowerLevel:
            title = [VectorL10n setDefaultPowerLevel];
            break;
        case MXKRoomMemberDetailsActionSetModerator:
            title = [VectorL10n setModerator];
            break;
        case MXKRoomMemberDetailsActionSetAdmin:
            title = [VectorL10n setAdmin];
            break;
        case MXKRoomMemberDetailsActionSetCustomPowerLevel:
            title = [VectorL10n setPowerLevel];
            break;
        case MXKRoomMemberDetailsActionStartChat:
            title = [VectorL10n startChat];
            break;
        case MXKRoomMemberDetailsActionStartVoiceCall:
            title = [VectorL10n startVoiceCall];
            break;
        case MXKRoomMemberDetailsActionStartVideoCall:
            title = [VectorL10n startVideoCall];
            break;
        case MXKRoomMemberDetailsActionMention:
            title = [VectorL10n mention];
            break;
        default:
            break;
    }
    
    return title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView == tableView)
    {
        NSInteger row = indexPath.row;
        
        MXKTableViewCellWithButtons *cell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithButtons defaultReuseIdentifier]];
        if (!cell)
        {
            cell = [[MXKTableViewCellWithButtons alloc] init];
        }
        
        cell.mxkButtonNumber = 2;
        NSArray *buttons = cell.mxkButtons;
        NSInteger index = row * 2;
        NSString *text = nil;
        for (UIButton *button in buttons)
        {
            NSNumber *actionNumber;
            if (index < actionsArray.count)
            {
                actionNumber = [actionsArray objectAtIndex:index];
            }
            
            text = (actionNumber ? [self actionButtonTitle:actionNumber.unsignedIntegerValue] : nil);
            
            button.hidden = (text.length == 0);
            
            button.layer.borderColor = button.tintColor.CGColor;
            button.layer.borderWidth = 1;
            button.layer.cornerRadius = 5;
            
            [button setTitle:text forState:UIControlStateNormal];
            [button setTitle:text forState:UIControlStateHighlighted];
            
            [button addTarget:self action:@selector(onActionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            
            button.tag = (actionNumber ? actionNumber.unsignedIntegerValue : -1);
            
            index ++;
        }
        
        return cell;
    }
    
    // Return a fake cell to prevent app from crashing.
    return [[UITableViewCell alloc] init];
}


#pragma mark - button management

- (BOOL)hasPendingAction
{
    return nil != pendingMaskSpinnerView;
}

- (void)addPendingActionMask
{
    // add a spinner above the tableview to avoid that the user tap on any other button
    pendingMaskSpinnerView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    pendingMaskSpinnerView.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5];
    pendingMaskSpinnerView.frame = self.tableView.frame;
    pendingMaskSpinnerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin;
    
    // append it
    [self.tableView.superview addSubview:pendingMaskSpinnerView];
    
    // animate it
    [pendingMaskSpinnerView startAnimating];
}

- (void)removePendingActionMask
{
    if (pendingMaskSpinnerView)
    {
        [pendingMaskSpinnerView removeFromSuperview];
        pendingMaskSpinnerView = nil;
        [self.tableView reloadData];
    }
}

- (void)setPowerLevel:(NSInteger)value promptUser:(BOOL)promptUser
{
    NSInteger currentPowerLevel = [self.mxRoomLiveTimeline.state.powerLevels powerLevelOfUserWithUserID:_mxRoomMember.userId];
    
    // check if the power level has not yet been set to 0
    if (value != currentPowerLevel)
    {
        __weak typeof(self) weakSelf = self;

        if (promptUser && value == [self.mxRoomLiveTimeline.state.powerLevels powerLevelOfUserWithUserID:self.mainSession.myUser.userId])
        {
            // If the user is setting the same power level as his to another user, ask him for a confirmation
            if (currentAlert)
            {
                [currentAlert dismissViewControllerAnimated:NO completion:nil];
            }
            
            currentAlert = [UIAlertController alertControllerWithTitle:[VectorL10n roomMemberPowerLevelPrompt] message:nil preferredStyle:UIAlertControllerStyleAlert];
            
            [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n no]
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               
                                                               if (weakSelf)
                                                               {
                                                                   typeof(self) self = weakSelf;
                                                                   self->currentAlert = nil;
                                                               }
                                                               
                                                           }]];
            
            [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n yes]
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               
                                                               if (weakSelf)
                                                               {
                                                                   typeof(self) self = weakSelf;
                                                                   self->currentAlert = nil;
                                                                   
                                                                   // The user confirms. Apply the power level
                                                                   [self setPowerLevel:value promptUser:NO];
                                                               }
                                                               
                                                           }]];
            
            [self presentViewController:currentAlert animated:YES completion:nil];
        }
        else
        {
            [self addPendingActionMask];

            // Reset user power level
            [self.mxRoom setPowerLevelOfUserWithUserID:_mxRoomMember.userId powerLevel:value success:^{

                __strong __typeof(weakSelf)strongSelf = weakSelf;
                [strongSelf removePendingActionMask];

            } failure:^(NSError *error) {

                __strong __typeof(weakSelf)strongSelf = weakSelf;
                [strongSelf removePendingActionMask];
                MXLogDebug(@"[MXKRoomMemberDetailsVC] Set user power (%@) failed", strongSelf.mxRoomMember.userId);

                // Notify MatrixKit user
                NSString *myUserId = strongSelf.mainSession.myUser.userId;
                [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error userInfo:myUserId ? @{kMXKErrorUserIdKey: myUserId} : nil];
                
            }];
        }
    }
}

- (void)updateUserPowerLevel
{
    __weak typeof(self) weakSelf = self;
    
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
    }
    
    currentAlert = [UIAlertController alertControllerWithTitle:[VectorL10n powerLevel] message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    
    if (![self.mainSession.myUser.userId isEqualToString:_mxRoomMember.userId])
    {
        [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n resetToDefault]
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {
                                                           
                                                           if (weakSelf)
                                                           {
                                                               typeof(self) self = weakSelf;
                                                               self->currentAlert = nil;
                                                               
                                                               [self setPowerLevel:self.mxRoomLiveTimeline.state.powerLevels.usersDefault promptUser:YES];
                                                           }
                                                           
                                                       }]];
    }
    
    [currentAlert addTextFieldWithConfigurationHandler:^(UITextField *textField)
    {
        typeof(self) self = weakSelf;
        
        textField.secureTextEntry = NO;
        textField.text = [NSString stringWithFormat:@"%ld", (long)[self.mxRoomLiveTimeline.state.powerLevels powerLevelOfUserWithUserID:self.mxRoomMember.userId]];
        textField.placeholder = nil;
        textField.keyboardType = UIKeyboardTypeDecimalPad;
    }];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n ok]
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           NSString *text = [self->currentAlert textFields].firstObject.text;
                                                           self->currentAlert = nil;
                                                           
                                                           if (text.length > 0)
                                                           {
                                                               [self setPowerLevel:[text integerValue] promptUser:YES];
                                                           }
                                                       }
                                                       
                                                   }]];
    
    [self presentViewController:currentAlert animated:YES completion:nil];
}

@end
