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

import SwiftUI

struct RoomNotificationSettingsView: View {
    
    var viewState: RoomNotificationSettingsViewState
    
    var didSelect: ((RoomNotificationState) -> Void)?
    var body: some View {
        List {
            SwiftUI.Section(
                header: Text(VectorL10n.roomNotifsSettingsNotifyMeFor),
                footer: Text(viewState.roomEncryptedString)) {
                ForEach(viewState.notificationOptions) { option in
                    HStack {
                        Text(option.title)
                        Spacer()
                        if viewState.notificationState == option {
                            Image("checkmark").foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                        }
                    }.onTapGesture {
                        didSelect?(option)
                    }
                }
            }
        }.listStyle(GroupedListStyle())
    }
}

struct RoomNotificationSettingsView_Previews: PreviewProvider {
    static let viewState = RoomNotificationSettingsViewState(
        roomEncrypted: true,
        saving: true,
        notificationState: .all,
        avatarData: nil)
    static var previews: some View {
        RoomNotificationSettingsView(viewState: viewState)
    }
}

fileprivate extension RoomNotificationState {
    var title: String {
        switch self {
        case .all:
            return VectorL10n.roomNotifsSettingsAllMessages
        case .mentionsAndKeywordsOnly:
            return VectorL10n.roomNotifsSettingsMentionsAndKeywords
        case .mute:
            return VectorL10n.roomNotifsSettingsNone
        }
    }
}

fileprivate extension RoomNotificationSettingsViewState {
    var roomEncryptedString: String {
        roomEncrypted ? VectorL10n.roomNotifsSettingsEncryptedRoomNotice : ""
    }
}



extension RoomNotificationState: Identifiable {
    var id: String { UUID().uuidString }
}
