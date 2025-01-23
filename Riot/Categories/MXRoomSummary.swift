//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

extension Notification.Name {
    static let roomSummaryDidRemoveExpiredDataFromStore = Notification.Name(MXRoomSummary.roomSummaryDidRemoveExpiredDataFromStore)
}

extension MXRoomSummary {
    @objc static let roomSummaryDidRemoveExpiredDataFromStore = "roomSummaryDidRemoveExpiredDataFromStore"
    @objc static let roomRetentionStateEventType = "m.room.retention"
    @objc static let roomRetentionEventMaxLifetimeKey = "max_lifetime"
    @objc static let roomRetentionMaxLifetime = "roomRetentionMaxLifetime"
    
    /// Get the room messages retention period in days
    private func roomRetentionPeriodInMillis() -> UInt64 {
        if let period = self.others[MXRoomSummary.roomRetentionMaxLifetime] as? UInt64 {
            return period
        } else {
            return Tools.durationInMs(fromDays: 365)
        }
    }
    
    /// Get the timestamp below which the received messages must be removed from the store, and the display
    @objc func minimumTimestamp() -> UInt64 {
        let periodInMs = self.roomRetentionPeriodInMillis()
        let currentTs = (UInt64)(Date().timeIntervalSince1970 * 1000)
        return (currentTs - periodInMs)
    }
    
    /// Remove the expired messages from the store.
    /// If some data are removed, this operation posts the notification: roomSummaryDidRemoveExpiredDataFromStore.
    /// This operation does not commit the potential change. We let the caller trigger the commit when this is the more suitable.
    ///
    /// Provide a boolean telling whether some data have been removed.
    @objc func removeExpiredRoomContentsFromStore() -> Bool {
        let ret = self.mxSession.store.removeAllMessagesSent(before: self.minimumTimestamp(), inRoom: roomId)
        if ret {
            NotificationCenter.default.post(name: .roomSummaryDidRemoveExpiredDataFromStore, object: self)
        }
        return ret
    }
}
