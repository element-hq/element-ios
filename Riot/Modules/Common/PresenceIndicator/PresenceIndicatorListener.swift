// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
