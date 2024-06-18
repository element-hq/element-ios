//
// Copyright 2024 New Vector Ltd
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
