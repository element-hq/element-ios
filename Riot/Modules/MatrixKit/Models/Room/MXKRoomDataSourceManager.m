/*
 Copyright 2015 OpenMarket Ltd
 
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

#import "MXKRoomDataSourceManager.h"

@interface MXKRoomDataSourceManager()
{
    MXSession *mxSession;
    
    /**
     The list of running roomDataSources.
     Each key is a room ID. Each value, the MXKRoomDataSource instance.
     */
    NSMutableDictionary *roomDataSources;
    
    /**
     Observe UIApplicationDidReceiveMemoryWarningNotification to dispose of any resources that can be recreated.
     */
    id UIApplicationDidReceiveMemoryWarningNotificationObserver;
}

@end

static NSMutableDictionary *_roomDataSourceManagers = nil;
static Class _roomDataSourceClass;

@implementation MXKRoomDataSourceManager

+ (MXKRoomDataSourceManager *)sharedManagerForMatrixSession:(MXSession *)mxSession
{
    // Manage a pool of managers: one per Matrix session
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _roomDataSourceManagers = [NSMutableDictionary dictionary];
    });
    
    MXKRoomDataSourceManager *roomDataSourceManager;
    
    // Compute an id for this mxSession object: its pointer address as a string
    NSString *mxSessionId = [NSString stringWithFormat:@"%p", mxSession];
    
    @synchronized(_roomDataSourceManagers)
    {
        if (_roomDataSourceClass == nil)
        {
            // Set default class
            _roomDataSourceClass = MXKRoomDataSource.class;
        }
        // If not available yet, create the `MXKRoomDataSourceManager` for this Matrix session
        roomDataSourceManager = _roomDataSourceManagers[mxSessionId];
        if (!roomDataSourceManager)
        {
            roomDataSourceManager = [[MXKRoomDataSourceManager alloc]initWithMatrixSession:mxSession];
            _roomDataSourceManagers[mxSessionId] = roomDataSourceManager;
        }
    }
    
    return roomDataSourceManager;
}

+ (void)removeSharedManagerForMatrixSession:(MXSession*)mxSession
{
    // Compute the id for this mxSession object: its pointer address as a string
    NSString *mxSessionId = [NSString stringWithFormat:@"%p", mxSession];
    
    @synchronized(_roomDataSourceManagers)
    {
        MXKRoomDataSourceManager *roomDataSourceManager = [_roomDataSourceManagers objectForKey:mxSessionId];
        if (roomDataSourceManager)
        {
            [roomDataSourceManager destroy];
            [_roomDataSourceManagers removeObjectForKey:mxSessionId];
        }
    }
}

+ (void)registerRoomDataSourceClass:(Class)roomDataSourceClass
{
    // Sanity check: accept only MXKRoomDataSource classes or sub-classes
    NSParameterAssert([roomDataSourceClass isSubclassOfClass:MXKRoomDataSource.class]);
    
    @synchronized(_roomDataSourceManagers)
    {
        if (roomDataSourceClass !=_roomDataSourceClass)
        {
            _roomDataSourceClass = roomDataSourceClass;
            
            NSArray *mxSessionIds = _roomDataSourceManagers.allKeys;
            for (NSString *mxSessionId in mxSessionIds)
            {
                MXKRoomDataSourceManager *roomDataSourceManager = [_roomDataSourceManagers objectForKey:mxSessionId];
                if (roomDataSourceManager)
                {
                    [roomDataSourceManager destroy];
                    [_roomDataSourceManagers removeObjectForKey:mxSessionId];
                }
            }
        }
    }
}

- (instancetype)initWithMatrixSession:(MXSession *)matrixSession
{
    self = [super init];
    if (self)
    {
        mxSession = matrixSession;
        roomDataSources = [NSMutableDictionary dictionary];
        _releasePolicy = MXKRoomDataSourceManagerReleasePolicyNeverRelease;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didMXSessionDidLeaveRoom:) name:kMXSessionDidLeaveRoomNotification object:nil];
        
        // Observe UIApplicationDidReceiveMemoryWarningNotification
        UIApplicationDidReceiveMemoryWarningNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
            
            MXLogDebug(@"[MXKRoomDataSourceManager] %@: Received memory warning.", self);
            
            // Reload all data sources (except the current used ones) to reduce memory usage.
            for (MXKRoomDataSource *roomDataSource in self->roomDataSources.allValues)
            {
                if (!roomDataSource.delegate)
                {
                    [roomDataSource reload];
                }
            }
            
        }];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXSessionDidLeaveRoomNotification object:nil];
}

- (void)destroy
{
    [self reset];
    
    if (UIApplicationDidReceiveMemoryWarningNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:UIApplicationDidReceiveMemoryWarningNotificationObserver];
        UIApplicationDidReceiveMemoryWarningNotificationObserver = nil;
    }
}

#pragma mark

- (BOOL)isServerSyncInProgress
{
    // Check first the matrix session state
    if (mxSession.state == MXSessionStateSyncInProgress)
    {
        return YES;
    }
    
    // Check all data sources (events process is asynchronous, server sync may not be complete in data source).
    for (MXKRoomDataSource *roomDataSource in roomDataSources.allValues)
    {
        if (roomDataSource.serverSyncEventCount)
        {
            return YES;
        }
    }
    
    return NO;
}

#pragma mark

- (void)reset
{
    NSArray *roomIds =  roomDataSources.allKeys;
    for (NSString *roomId in roomIds)
    {
        [self closeRoomDataSourceWithRoomId:roomId forceClose:YES];
    }
}

- (BOOL)hasRoomDataSourceForRoom:(NSString *)roomId
{
    return roomDataSources[roomId] != nil;
}

- (void)roomDataSourceForRoom:(NSString *)roomId create:(BOOL)create onComplete:(void (^)(MXKRoomDataSource *roomDataSource))onComplete
{
    NSParameterAssert(roomId);

    // If not available yet, create the room data source
    MXKRoomDataSource *roomDataSource = roomDataSources[roomId];

    if (!roomDataSource && create && roomId)
    {
        [_roomDataSourceClass loadRoomDataSourceWithRoomId:roomId threadId:nil andMatrixSession:mxSession onComplete:^(id roomDataSource) {
            [self addRoomDataSource:roomDataSource];
            onComplete(roomDataSource);
        }];
    }
    else
    {
        onComplete(roomDataSource);
    }
}

- (void)addRoomDataSource:(MXKRoomDataSource *)roomDataSource
{
    roomDataSources[roomDataSource.roomId] = roomDataSource;
}

- (void)closeRoomDataSourceWithRoomId:(NSString*)roomId forceClose:(BOOL)forceRelease;
{
    // Check first whether this roomDataSource is well handled by this manager
    if (!roomId || !roomDataSources[roomId])
    {
        MXLogDebug(@"[MXKRoomDataSourceManager] Failed to close an unknown room id: %@", roomId);
        return;
    }

    MXKRoomDataSource *roomDataSource = roomDataSources[roomId];

    // According to the policy, it is interesting to keep the room data source in life: it can keep managing echo messages
    // in background for instance
    MXKRoomDataSourceManagerReleasePolicy releasePolicy = _releasePolicy;
    if (forceRelease)
    {
        // Act as ReleaseOnClose policy
        releasePolicy = MXKRoomDataSourceManagerReleasePolicyReleaseOnClose;
    }
    
    switch (releasePolicy)
    {
        case MXKRoomDataSourceManagerReleasePolicyReleaseOnClose:
            
            // Destroy and forget the instance
            [roomDataSource destroy];
            [roomDataSources removeObjectForKey:roomDataSource.roomId];
            break;
            
        case MXKRoomDataSourceManagerReleasePolicyNeverRelease:
            
            // The close here consists in no more sending actions to the current view controller, the room data source delegate
            roomDataSource.delegate = nil;
            
            // Keep the instance for life (reduce memory usage by flushing room data if the number of bubbles is over 30).
            [roomDataSource limitMemoryUsage:roomDataSource.maxBackgroundCachedBubblesCount];
            break;
            
        default:
            break;
    }
}

- (void)didMXSessionDidLeaveRoom:(NSNotification *)notif
{
    if (mxSession == notif.object)
    {
        // The room is no more available, remove it from the manager
        [self closeRoomDataSourceWithRoomId:notif.userInfo[kMXSessionNotificationRoomIdKey] forceClose:YES];
    }
}

@end
