/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <Foundation/Foundation.h>
#import <MatrixSDK/MatrixSDK.h>

#import "MXKAttachment.h"

@class MXKSearchDataSource;

/**
 `MXKSearchCellDataStoring` defines a protocol a class must conform in order to store 
 a search result in a cell data managed by `MXKSearchDataSource`.
 */
@protocol MXKSearchCellDataStoring <NSObject>

/**
 The room id
 */
@property (nonatomic) NSString *roomId;

@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *message;
@property (nonatomic, readonly) NSString *date;

// Bulk result returned by MatrixSDK
@property (nonatomic, readonly) MXSearchResult *searchResult;

/**
 Tell whether the room display name should be displayed in the cell. NO by default.
 */
@property (nonatomic) BOOL shouldShowRoomDisplayName;

/**
 The room display name.
 */
@property (nonatomic) NSString *roomDisplayName;

/**
 The sender display name.
 */
@property (nonatomic) NSString *senderDisplayName;

/**
 The bubble attachment (if any).
 */
@property (nonatomic) MXKAttachment *attachment;

/**
 YES when the bubble correspond to an attachment displayed with a thumbnail (see image, video).
 */
@property (nonatomic, readonly) BOOL isAttachmentWithThumbnail;

/**
 The default icon relative to the attachment (if any).
 */
@property (nonatomic, readonly) UIImage* attachmentIcon;


#pragma mark - Public methods
/**
 Create a new `MXKCellData` object for a new search result cell.

 @param searchResult Bulk result returned by MatrixSDK.
 @param searchDataSource the `MXKSearchDataSource` object that will use this instance.
 @param onComplete a block providing the newly created instance.
 */
+ (void)cellDataWithSearchResult:(MXSearchResult*)searchResult andSearchDataSource:(MXKSearchDataSource*)searchDataSource onComplete:(void (^)(id<MXKSearchCellDataStoring> cellData))onComplete;

@end
