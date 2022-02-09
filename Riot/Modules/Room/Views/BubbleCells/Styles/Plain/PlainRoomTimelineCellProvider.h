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

#import "RoomTimelineCellProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface PlainRoomTimelineCellProvider: NSObject<RoomTimelineCellProvider>

#pragma mark - Registration

- (void)registerIncomingTextMessageCellsForTableView:(UITableView*)tableView;

- (void)registerOutgoingTextMessageCellsForTableView:(UITableView*)tableView;

- (void)registerVoiceMessageCellsForTableView:(UITableView*)tableView;

- (void)registerPollCellsForTableView:(UITableView*)tableView;

- (void)registerLocationCellsForTableView:(UITableView*)tableView;

#pragma mark - Mapping

- (NSDictionary<NSNumber*, Class>*)incomingTextMessageCellsMapping;

- (NSDictionary<NSNumber*, Class>*)outgoingTextMessageCellsMapping;

- (NSDictionary<NSNumber*, Class>*)incomingEmoteCellsMapping;

- (NSDictionary<NSNumber*, Class>*)outgoingEmoteCellsMapping;

- (NSDictionary<NSNumber*, Class>*)outgoingAttachmentCellsMapping;

- (NSDictionary<NSNumber*, Class>*)incomingAttachmentWithoutThumbnailCellsMapping;

- (NSDictionary<NSNumber*, Class>*)outgoingAttachmentWithoutThumbnailCellsMapping;

- (NSDictionary<NSNumber*, Class>*)voiceMessageCellsMapping;

- (NSDictionary<NSNumber*, Class>*)pollCellsMapping;

- (NSDictionary<NSNumber*, Class>*)locationCellsMapping;

@end

NS_ASSUME_NONNULL_END
