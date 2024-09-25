/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <Foundation/Foundation.h>

#import "MXKRoomDataSource.h"

/**
 `MXKRoomDataSourceManagerReleasePolicy` defines how a `MXKRoomDataSource` instance must be released
 when [MXKRoomDataSourceManager closeRoomDataSourceWithRoomId:] is called.
 
 Once released, the in-memory data (messages that are outgoing, failed sending, ...) of room data source
 is lost.
 */
typedef enum : NSUInteger {

    /**
     Created `MXKRoomDataSource` instances are never released when they are closed.
     */
    MXKRoomDataSourceManagerReleasePolicyNeverRelease,

    /**
     Created `MXKRoomDataSource` instances are released when they are closed.
     */
    MXKRoomDataSourceManagerReleasePolicyReleaseOnClose,

} MXKRoomDataSourceManagerReleasePolicy;


/**
 `MXKRoomDataSourceManager` manages a pool of `MXKRoomDataSource` instances for a given Matrix session.
 
 It makes the `MXKRoomDataSource` instances reusable so that their data (messages that are outgoing, failed sending, ...)
 is not lost when the view controller that displays them is gone.
 */
@interface MXKRoomDataSourceManager : NSObject

/**
 Retrieve the MXKRoomDataSources manager for a particular Matrix session.
 
 @param mxSession the Matrix session,
 @return the MXKRoomDataSources manager to use for this session.
 */
+ (MXKRoomDataSourceManager*)sharedManagerForMatrixSession:(MXSession*)mxSession;

/**
 Remove the MXKRoomDataSources manager for a particular Matrix session.
 
 @param mxSession the Matrix session.
 */
+ (void)removeSharedManagerForMatrixSession:(MXSession*)mxSession;

/**
 Register the MXKRoomDataSource-inherited class that will be used to instantiate all room data source.
 By default MXKRoomDataSource class is considered.
 
 CAUTION: All existing room data source instances are reset in case of class change.
 
 @param roomDataSourceClass a MXKRoomDataSource-inherited class.
 */
+ (void)registerRoomDataSourceClass:(Class)roomDataSourceClass;

/**
 Force close all the current room data source instances.
 */
- (void)reset;

/**
 Flag indicating the manager has a room data source for a given room id.

 @param roomId the room id to check.
 */
- (BOOL)hasRoomDataSourceForRoom:(NSString*)roomId;

/**
 Get a room data source corresponding to a room id.
 
 If a room data source already exists for this room, its reference will be returned. Else,
 if requested, the method will instantiate it.
 
 @param roomId the room id of the room.
 @param create if YES, the MXKRoomDataSourceManager will create the room data source if it does not exist yet.
 @param onComplete blocked with the room data source (instance of MXKRoomDataSource-inherited class).
 */
- (void)roomDataSourceForRoom:(NSString*)roomId create:(BOOL)create onComplete:(void (^)(MXKRoomDataSource *roomDataSource))onComplete;

/**
 Make a room data source be managed by the manager.

 Use this method to add a MXKRoomDataSource-inherited instance that cannot be automatically created by
 [MXKRoomDataSourceManager roomDataSourceForRoom: create:].
 
 @param roomDataSource the MXKRoomDataSource-inherited object to the manager scope.
 */
- (void)addRoomDataSource:(MXKRoomDataSource*)roomDataSource;

/**
 Close the roomDataSource.
 
 The roomDataSource instance will be actually destroyed according to the current release policy.

 @param roomId the room if of the data source to release.
 @param forceRelease if yes the room data source instance will be destroyed whatever the policy is.
 */
- (void)closeRoomDataSourceWithRoomId:(NSString*)roomId forceClose:(BOOL)forceRelease;

/**
 The release policy to apply when `MXKRoomDataSource` instances are closed.
 Default is MXKRoomDataSourceManagerReleasePolicyNeverRelease.
 */
@property (nonatomic) MXKRoomDataSourceManagerReleasePolicy releasePolicy;

/**
 Tells whether a server sync is in progress in the matrix session.
 */
@property (nonatomic, readonly) BOOL isServerSyncInProgress;

@end
