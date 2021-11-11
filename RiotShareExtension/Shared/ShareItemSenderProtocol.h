// 
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
