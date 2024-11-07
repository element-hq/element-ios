/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <Foundation/Foundation.h>
#import <MatrixSDK/MatrixSDK.h>

#import "MXKCellData.h"

@class MXKDataSource;
@class MXSpaceChildInfo;

/**
 `MXKRecentCellDataStoring` defines a protocol a class must conform in order to store recent cell data
 managed by `MXKSessionRecentsDataSource`.
 */
@protocol MXKRecentCellDataStoring <NSObject>

#pragma mark - Data displayed by a room recent cell

/**
 The original data source of the recent displayed by the cell.
 */
@property (nonatomic, weak, readonly) MXKDataSource *dataSource;

/**
 The `MXRoomSummaryProtocol` instance of the room for the recent displayed by the cell.
 */
@property (nonatomic, readonly) id<MXRoomSummaryProtocol> roomSummary;

@property (nonatomic, readonly) NSString *roomIdentifier;
@property (nonatomic, readonly) NSString *roomDisplayname;
@property (nonatomic, readonly) NSString *avatarUrl;
@property (nonatomic, readonly) NSString *directUserId;
@property (nonatomic, readonly) MXPresence presence;
@property (nonatomic, readonly) NSString *lastEventTextMessage;
@property (nonatomic, readonly) NSString *lastEventDate;

@property (nonatomic, readonly) BOOL hasUnread;
@property (nonatomic, readonly) BOOL isRoomMarkedAsUnread;
@property (nonatomic, readonly) NSUInteger notificationCount;
@property (nonatomic, readonly) NSUInteger highlightCount;
@property (nonatomic, readonly) NSString *notificationCountStringValue;
@property (nonatomic, readonly) BOOL isSuggestedRoom;

@property (nonatomic, readonly) MXSession *mxSession;

#pragma mark - Public methods
/**
 Create a new `MXKCellData` object for a new recent cell.

 @param roomSummary the `id<MXRoomSummaryProtocol>` object that has data about the room.
 @param dataSource the `MXKDataSource` object that will use this instance.
 @return the newly created instance.
 */
- (instancetype)initWithRoomSummary:(id<MXRoomSummaryProtocol>)roomSummary
                         dataSource:(MXKDataSource*)dataSource;

@optional
/**
 The `lastEventTextMessage` with sets of attributes.
 */
@property (nonatomic, readonly) NSAttributedString *lastEventAttributedTextMessage;

@end
