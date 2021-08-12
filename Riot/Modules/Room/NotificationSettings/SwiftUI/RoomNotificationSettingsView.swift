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

@available(iOS 14.0.0, *)
struct RoomNotificationSettingsView: View {
    
    @Environment(\.theme) var theme: Theme
    @ObservedObject var viewModel: RoomNotificationSettingsViewModel
    
    let presentedModally: Bool
    
    @ViewBuilder
    var leftButton: some View {
        if presentedModally {
            SwiftUI.Button(VectorL10n.cancel) {
                viewModel.process(viewAction: .cancel)
            }
        }
    }

    var rightButton: some View {
        Button(VectorL10n.save) {
            viewModel.process(viewAction: .save)
        }
    }
    
    var body: some View {
        VectorFormView {
            if let image = viewModel.viewState.avatar {
                RoomNotificationSettingsHeaderView(image: image, displayName: viewModel.viewState.displayName)
            }
            SwiftUI.Section(
                header: FormSectionHeaderView(text: VectorL10n.roomNotifsSettingsNotifyMeFor),
                footer: FormSectionFooterView(text: viewModel.viewState.roomEncryptedString)
            ) {
                ForEach(viewModel.viewState.notificationOptions) { option in
                    FormPickerItemView(title: option.title, selected: viewModel.viewState.notificationState == option) {
                        viewModel.process(viewAction: .selectNotificationState(option))
                    }
                }
            }
        }
        .navigationBarTitle(VectorL10n.roomDetailsNotifs)
        .navigationBarItems(
            leading: leftButton,
            trailing: rightButton
        ).onAppear {
            viewModel.process(viewAction: .load)
        }
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

@available(iOS 14.0, *)
struct RoomNotificationSettingsView_Previews: PreviewProvider {

    static let mockViewModel = RoomNotificationSettingsViewModel(
        roomNotificationService: MockRoomNotificationSettingsService.example,
        avatarService: MockAvatarService.example,
        avatarData: .swiftUI(AvatarInput(mxContentUri: nil, itemId: "", displayName: "Alice")),
        roomEncrypted: true
    )

    static var previews: some View {
        Group {
            NavigationView {
                RoomNotificationSettingsView(viewModel: mockViewModel, presentedModally: true)
                    .navigationBarTitleDisplayMode(.inline)
            }
            NavigationView {
                RoomNotificationSettingsView(viewModel: mockViewModel, presentedModally: true)
                    .navigationBarTitleDisplayMode(.inline)
                    .theme(ThemeIdentifier.dark.theme)
            }
        }
    }
}
