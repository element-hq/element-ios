/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKRoomSettingsViewController.h"

#import "NSBundle+MatrixKit.h"

#import "MXKSwiftHeader.h"

@interface MXKRoomSettingsViewController()
{    
    // the room events listener
    id roomListener;
    
    // Observe kMXSessionWillLeaveRoomNotification to be notified if the user leaves the current room.
    id leaveRoomNotificationObserver;
    
    // Observe kMXRoomDidFlushDataNotification to take into account the updated room state when the room history is flushed.
    id roomDidFlushDataNotificationObserver;
}
@end

@implementation MXKRoomSettingsViewController

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([MXKRoomSettingsViewController class])
                          bundle:[NSBundle bundleForClass:[MXKRoomSettingsViewController class]]];
}

+ (instancetype)roomSettingsViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass([MXKRoomSettingsViewController class])
                                          bundle:[NSBundle bundleForClass:[MXKRoomSettingsViewController class]]];
}

#pragma mark -

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self refreshRoomSettings];
}

#pragma mark - Override MXKTableViewController

- (void)finalizeInit
{
    [super finalizeInit];
}

- (void)destroy
{
    if (roomListener)
    {
        MXWeakify(self);
        [mxRoom liveTimeline:^(id<MXEventTimeline> liveTimeline) {
            MXStrongifyAndReturnIfNil(self);

            [liveTimeline removeListener:self->roomListener];
            self->roomListener = nil;
        }];
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
    
    mxRoom = nil;
    mxRoomState = nil;
    
    [super destroy];
}

- (void)onMatrixSessionStateDidChange:(NSNotification *)notif;
{
    // Check this is our Matrix session that has changed
    if (notif.object == self.mainSession)
    {
        [super onMatrixSessionStateDidChange:notif];
        
        // refresh when the session sync is done.
        if (MXSessionStateRunning == self.mainSession.state)
        {
            [self refreshRoomSettings];
        }
    }
}

#pragma mark - Public API

/**
 Set the dedicated session and the room Id
 */
- (void)initWithSession:(MXSession*)mxSession andRoomId:(NSString*)roomId
{
    // Update the matrix session
    if (self.mainSession)
    {
        [self removeMatrixSession:self.mainSession];
    }
    mxRoom = nil;
    
    // Sanity checks
    if (mxSession && roomId)
    {
        [self addMatrixSession:mxSession];
        
        // Report the room identifier
        _roomId = roomId;
        mxRoom = [mxSession roomWithRoomId:roomId];
    }
    
    if (mxRoom)
    {
        // Register a listener to handle messages related to room name, topic...
        MXWeakify(self);
        [mxRoom liveTimeline:^(id<MXEventTimeline> liveTimeline) {
            MXStrongifyAndReturnIfNil(self);

            self->roomListener = [liveTimeline listenToEventsOfTypes:@[kMXEventTypeStringRoomName, kMXEventTypeStringRoomTopic, kMXEventTypeStringRoomAliases, kMXEventTypeStringRoomAvatar, kMXEventTypeStringRoomPowerLevels, kMXEventTypeStringRoomCanonicalAlias, kMXEventTypeStringRoomJoinRules, kMXEventTypeStringRoomGuestAccess, kMXEventTypeStringRoomHistoryVisibility] onEvent:^(MXEvent *event, MXTimelineDirection direction, MXRoomState *roomState) {

                // Consider only live events
                if (direction == MXTimelineDirectionForwards)
                {
                    [self updateRoomState:liveTimeline.state];
                }
            }];
        
            // Observe kMXSessionWillLeaveRoomNotification to be notified if the user leaves the current room.
            self->leaveRoomNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXSessionWillLeaveRoomNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {

                // Check whether the user will leave the room related to the displayed participants
                if (notif.object == self.mainSession)
                {
                    NSString *roomId = notif.userInfo[kMXSessionNotificationRoomIdKey];
                    if (roomId && [roomId isEqualToString:self.roomId])
                    {
                        // We remove the current view controller.
                        [self withdrawViewControllerAnimated:YES completion:nil];
                    }
                }
            }];

            // Observe room history flush (sync with limited timeline, or state event redaction)
            self->roomDidFlushDataNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXRoomDidFlushDataNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {

                MXRoom *room = notif.object;
                if (self.mainSession == room.mxSession && [self.roomId isEqualToString:room.roomId])
                {
                    // The existing room history has been flushed during server sync. Take into account the updated room state.
                    [self updateRoomState:liveTimeline.state];
                }

            }];

            [self updateRoomState:liveTimeline.state];
        }];
    }
    
    self.title = [VectorL10n roomDetailsTitle];
}

- (void)refreshRoomSettings
{
    [self.tableView reloadData];
}

- (void)updateRoomState:(MXRoomState*)newRoomState
{
    mxRoomState = newRoomState.copy;
    
    [self refreshRoomSettings];
}

#pragma mark - UITableViewDataSource

// empty by default

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return a fake cell to prevent app from crashing.
    return [[UITableViewCell alloc] init];
}

@end
