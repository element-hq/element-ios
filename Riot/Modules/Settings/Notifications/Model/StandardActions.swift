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

enum NotificationAction {
    case notify(Bool)
    case highlight(Bool)
    case sound(String)
}

enum NotificationStandardActions {
    case notify
    case notifyDefaultSound
    case notifyRingSound
    case highlight
    case highlightDefaultSound
    case dontNotify
    case disabled
    
    var actions: [NotificationAction]? {
        switch self {
        case .notify:
            return [.notify(true)]
        case .notifyDefaultSound:
            return [.notify(true), .sound("default")]
        case .notifyRingSound:
            return [.notify(true), .sound("ring")]
        case .highlight:
            return [.notify(true), .highlight(true)]
        case .highlightDefaultSound:
            return [.notify(true), .highlight(true), .sound("default")]
        case .dontNotify:
            return [.notify(false)]
        case .disabled:
            return nil
        }
    }
}
