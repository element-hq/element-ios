// 
// Copyright 2022 New Vector Ltd
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

/// Dedicated listener object for a user Presence status.
class PresenceIndicatorListener {
    // MARK: - Properties
    private let userId: String
    private var presence: MXPresence
    private let onUpdate: (MXPresence) -> Void
    private var presenceObserver: Any?

    // MARK: - Setup
    /// Init.
    ///
    /// - Parameters:
    ///   - userId: the user id
    ///   - presence: initial presence of the user
    ///   - onUpdate: callback for Presence updates
    init(userId: String, presence: MXPresence, onUpdate: @escaping (MXPresence) -> Void) {
        self.userId = userId
        self.presence = presence
        self.onUpdate = onUpdate

        NotificationCenter.default.addObserver(forName: .mxkContactManagerMatrixUserPresenceChange,
                                               object: nil,
                                               queue: .main) { [weak self] notif in
            guard let self = self,
                  self.userId == notif.object as? String,
                  let presenceString = notif.userInfo?[kMXKContactManagerMatrixPresenceKey] as? String else {
                return
            }

            let newPresence = MXTools.presence(presenceString)

            guard self.presence != newPresence else { return }

            self.presence = newPresence
            self.onUpdate(newPresence)
        }
    }

    deinit {
        if let presenceObserver = presenceObserver {
            NotificationCenter.default.removeObserver(presenceObserver)
            self.presenceObserver = nil
        }
    }
}
