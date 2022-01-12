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

import Foundation

struct ThreadViewModel {
    var rootMessageSenderUserId: String?
    var rootMessageSenderAvatar: AvatarViewDataProtocol?
    var rootMessageSenderDisplayName: String?
    var rootMessageText: NSAttributedString?
    var lastMessageTime: String?
    var summaryViewModel: ThreadSummaryViewModel?
    var notificationStatus: ThreadNotificationStatus
}

enum ThreadNotificationStatus {
    case none
    case notified
    case highlighted
    
    init(withThread thread: MXThread) {
        if thread.highlightCount > 0 {
            self = .highlighted
        } else if thread.notificationCount > 0 {
            self = .notified
        } else {
            self = .none
        }
    }
}
