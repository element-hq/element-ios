/*
 Copyright 2020 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation

/// Riot Standard Room Member Power Level
enum RoomNotificationSetting: CaseIterable {
    case allMessages
    case dmsMentionsKeywords
    case mentionsKeywords
    case never
    
    var longTitle: String {
        switch self {
        case .allMessages:
            return "All Messages"
        case .dmsMentionsKeywords:
            return "DMs, mentions and keywords only"
        case .mentionsKeywords:
            return "Mentions and keywords only"
        case .never:
            return "Never"
        }
    }
    
    var shortTitle: String {
        switch self {
        case .allMessages:
            return "All Messages"
        case .dmsMentionsKeywords:
            return "DMs, Mentions & Keywords"
        case .mentionsKeywords:
            return "Mentions & Keywords"
        case .never:
            return "Never"
        }
    }
}
