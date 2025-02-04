// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct ThreadModel {
    let rootMessageSenderUserId: String?
    let rootMessageSenderAvatar: AvatarViewDataProtocol?
    let rootMessageSenderDisplayName: String?
    let rootMessageText: NSAttributedString?
    let rootMessageRedacted: Bool
    let lastMessageTime: String?
    let summaryModel: ThreadSummaryModel?
    let notificationStatus: ThreadNotificationStatus
}

enum ThreadNotificationStatus {
    case none
    case notified
    case highlighted

    init(withThread thread: MXThreadProtocol) {
        if thread.highlightCount > 0 {
            self = .highlighted
        } else if thread.notificationCount > 0 {
            self = .notified
        } else {
            self = .none
        }
    }
}
