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

@available(iOS 14.0, *)
struct RoomAccessTypeChooserUpgradeRoomAlert: View {    
    
    // MARK: - Properties
    
    @ObservedObject var viewModel: RoomAccessTypeChooserViewModelType.Context
    @State var autoInviteUsers: Bool = true
    
    // MARK: - Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI

    // MARK: - Public
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
            alertContent
                .modifier(WaitOverlay(
                            allowUserInteraction: false,
                            message: $viewModel.waitingMessage,
                            isLoading: $viewModel.isLoading))
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    // MARK: - Private
    
    @ViewBuilder
    private var alertContent: some View {
        VStack(alignment: .center) {
            Text(VectorL10n.roomAccessSettingsScreenUpgradeAlertTitle)
                .font(theme.fonts.title3SB)
                .foregroundColor(theme.colors.primaryContent)
                .padding(.top, 16)
                .padding(.bottom, 24)
            Text(VectorL10n.roomAccessSettingsScreenUpgradeAlertMessage)
                .multilineTextAlignment(.center)
                .font(theme.fonts.subheadline)
                .foregroundColor(theme.colors.secondaryContent)
                .padding(.bottom, 35)
                .padding(.horizontal, 12)
            Toggle(isOn: $autoInviteUsers, label: {
                Text(VectorL10n.roomAccessSettingsScreenUpgradeAlertAutoInviteSwitch)
                    .font(theme.fonts.body)
                    .foregroundColor(theme.colors.secondaryContent)
            })
            .toggleStyle(SwitchToggleStyle(tint: theme.colors.accent))
            .padding(.horizontal, 28)
            Divider()
                .padding(.horizontal, 28)
            Button {
                viewModel.send(viewAction: .didAcceptRoomUpgrade(autoInviteUsers))
            } label: {
                Text(VectorL10n.roomAccessSettingsScreenUpgradeAlertUpgradeButton)
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .accessibilityIdentifier("upgradeButton")
            .padding(.horizontal, 24)
            .padding(.top, 16)
            Button {
                viewModel.send(viewAction: .didCancelRoomUpgrade)
            } label: {
                Text(VectorL10n.cancel)
            }
            .buttonStyle(SecondaryActionButtonStyle())
            .accessibilityIdentifier("cancelButton")
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .background(RoundedRectangle.init(cornerRadius: 8).foregroundColor(theme.colors.background))
        .padding(.horizontal, 20)
        .frame(minWidth: 0, maxWidth: 500)
    }
}

