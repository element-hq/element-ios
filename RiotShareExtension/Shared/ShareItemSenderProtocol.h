// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

@protocol ShareItemSenderProtocol;

@class MXRoom;

NS_ASSUME_NONNULL_BEGIN

@protocol ShareItemSenderDelegate

- (void)shareItemSenderDidStartSending:(id<ShareItemSenderProtocol>)shareItemSender;

- (void)shareItemSender:(id<ShareItemSenderProtocol>)shareItemSender didUpdateProgress:(CGFloat)progress;

@end

@protocol ShareItemSenderProtocol <NSObject>

@property (nonatomic, weak) id<ShareItemSenderDelegate> delegate;

- (void)sendItemsToRooms:(NSArray<MXRoom *> *)rooms
                 success:(void(^)(void))success
                 failure:(void(^)(NSArray<NSError *> *))failure;

@end

NS_ASSUME_NONNULL_END
