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
