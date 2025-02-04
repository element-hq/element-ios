// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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

- (void)registerVoiceBroadcastCellsForTableView:(UITableView*)tableView;

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

- (NSDictionary<NSNumber*, Class>*)voiceBroadcastPlaybackCellsMapping;

- (NSDictionary<NSNumber*, Class>*)voiceBroadcastRecorderCellsMapping;

@end

NS_ASSUME_NONNULL_END
