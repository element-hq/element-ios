//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct RoomUpgrade: View {
    // MARK: - Properties
    
    @State var autoInviteUsers = true
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    @ObservedObject var viewModel: RoomUpgradeViewModel.Context
    
    // MARK: - Public
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
            alertContent
                .waitOverlay(show: viewModel.viewState.isLoading, message: viewModel.viewState.waitingMessage, allowUserInteraction: false)
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    // MARK: - Private
    
    @ViewBuilder
    private var alertContent: some View {
        ZStack {
            VStack(alignment: .center) {
                Text(VectorL10n.roomAccessSettingsScreenUpgradeAlertTitle)
                    .font(theme.fonts.title3SB)
                    .foregroundColor(theme.colors.primaryContent)
                    .padding(.bottom, 24)
                if let spaceName = viewModel.viewState.parentSpaceName {
                    noteText(VectorL10n.roomAccessSettingsScreenUpgradeAlertMessage(spaceName))
                        .padding(.bottom)
                } else {
                    noteText(VectorL10n.roomAccessSettingsScreenUpgradeAlertMessageNoParam)
                        .padding(.bottom)
                }
                noteText(VectorL10n.roomAccessSettingsScreenUpgradeAlertNote)
                    .padding(.bottom, 35)
                Toggle(isOn: $autoInviteUsers) {
                    Text(VectorL10n.roomAccessSettingsScreenUpgradeAlertAutoInviteSwitch)
                        .font(theme.fonts.body)
                        .foregroundColor(theme.colors.secondaryContent)
                }
                .toggleStyle(SwitchToggleStyle(tint: theme.colors.accent))
                Divider()
                Button {
                    viewModel.send(viewAction: .done(autoInviteUsers))
                } label: {
                    Text(VectorL10n.roomAccessSettingsScreenUpgradeAlertUpgradeButton)
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .accessibilityIdentifier("upgradeButton")
                .padding(.top, 16)
                Button {
                    viewModel.send(viewAction: .cancel)
                } label: {
                    Text(VectorL10n.cancel)
                }
                .buttonStyle(SecondaryActionButtonStyle())
                .accessibilityIdentifier("cancelButton")
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .background(RoundedRectangle(cornerRadius: 8).foregroundColor(theme.colors.background))
        .padding(.horizontal, 20)
        .frame(minWidth: 0, maxWidth: 500)
    }
    
    private func noteText(_ message: String) -> some View {
        Text(message)
            .multilineTextAlignment(.center)
            .font(theme.fonts.subheadline)
            .foregroundColor(theme.colors.secondaryContent)
    }
}

// MARK: - Previews

struct RoomUpgrade_Previews: PreviewProvider {
    static let stateRenderer = MockRoomUpgradeScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
