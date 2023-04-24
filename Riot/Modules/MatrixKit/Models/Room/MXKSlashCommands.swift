// 
// Copyright 2023 New Vector Ltd
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

@objc final class MXKSlashCommandsHelper: NSObject {
    @objc static func commandNameFor(_ slashCommand: MXKSlashCommand) -> String {
        slashCommand.cmd
    }

    @objc static func commandUsageFor(_ slashCommand: MXKSlashCommand) -> String {
        "Usage: \(slashCommand.cmd) \(slashCommand.parametersFormat)"
    }
}

@objc enum MXKSlashCommand: Int, CaseIterable {
    case changeDisplayName
    case emote
    case joinRoom
    case partRoom
    case inviteUser
    case kickUser
    case banUser
    case unbanUser
    case setUserPowerLevel
    case resetUserPowerLevel
    case changeRoomTopic
    case discardSession

    var cmd: String {
        switch self {
        case .changeDisplayName:
            return "/nick"
        case .emote:
            return "/me"
        case .joinRoom:
            return "/join"
        case .partRoom:
            return "/part"
        case .inviteUser:
            return "/invite"
        case .kickUser:
            return "/kick"
        case .banUser:
            return "/ban"
        case .unbanUser:
            return "/unban"
        case .setUserPowerLevel:
            return "/op"
        case .resetUserPowerLevel:
            return "/deop"
        case .changeRoomTopic:
            return "/topic"
        case .discardSession:
            return "/discardsession"
        }
    }

    // Note: not localized for consistency, as commands are in english
    // also translating these parameters could lead to inconsistency in
    // the UI in case of languages with overlength translation.
    var parametersFormat: String {
        switch self {
        case .changeDisplayName:
            return "<display_name>"
        case .emote:
            return "<message>"
        case .joinRoom:
            return "<room-address>"
        case .partRoom:
            return "[<room-address>]"
        case .inviteUser:
            return "<user-id>"
        case .kickUser:
            return "<user-id> [<reason>]"
        case .banUser:
            return "<user-id> [<reason>]"
        case .unbanUser:
            return "<user-id>"
        case .setUserPowerLevel:
            return "<user-id> <power-level>"
        case .resetUserPowerLevel:
            return "<user-id>"
        case .changeRoomTopic:
            return "<topic>"
        case .discardSession:
            return ""
        }
    }
}
