//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct UserOtherSessionsToolbar: ToolbarContent {
    @Environment(\.theme) private var theme
    
    @Binding var isEditModeEnabled: Bool
    @Binding var filter: UserOtherSessionsFilter
    @Binding var isShowLocationEnabled: Bool
    let allItemsSelected: Bool
    let sessionCount: Int
    let showDeviceLogout: Bool
    let onToggleSelection: () -> Void
    let onSignOut: () -> Void
    
    var body: some ToolbarContent {
        navigationBarLeading()
        navigationBarTrailing()
    }
    
    private func navigationBarLeading() -> some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarLeading) {
            if isEditModeEnabled {
                Button(allItemsSelected ? VectorL10n.deselectAll : VectorL10n.selectAll, action: {
                    onToggleSelection()
                })
            }
        }
    }
    
    private func navigationBarTrailing() -> some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            if isEditModeEnabled {
                cancelButton()
            } else {
                filterMenuButton()
                    .offset(x: 12)
                optionsMenu()
            }
        }
    }
    
    private func cancelButton() -> some View {
        Button(VectorL10n.cancel) {
            isEditModeEnabled = false
        }
        .font(theme.fonts.bodySB)
        .foregroundColor(theme.colors.accent)
    }
    
    private func filterMenuButton() -> some View {
        Button { } label: {
            Menu {
                Picker("", selection: $filter) {
                    ForEach(UserOtherSessionsFilter.allCases) { filter in
                        Text(filter.menuLocalizedName).tag(filter)
                    }
                }
                .labelsHidden()
            } label: {
                Image(filter == .all ? Asset.Images.userOtherSessionsFilter.name : Asset.Images.userOtherSessionsFilterSelected.name)
            }
            .accessibilityLabel(VectorL10n.userOtherSessionFilter)
        }
    }
    
    private func optionsMenu() -> some View {
        Menu {
            if showDeviceLogout { // As you can only sign out the selected sessions, we don't allow selection when you're unable to sign out devices.
                Button {
                    isEditModeEnabled = true
                } label: {
                    Label(VectorL10n.userOtherSessionMenuSelectSessions, systemImage: "checkmark.circle")
                }
                .disabled(sessionCount == 0)
            }
            
            Button {
                isShowLocationEnabled.toggle()
            } label: {
                Label(showLocationInfo: isShowLocationEnabled)
            }
            
            if sessionCount > 0, showDeviceLogout {
                DestructiveButton {
                    onSignOut()
                } label: {
                    Label(VectorL10n.userOtherSessionMenuSignOutSessions(String(sessionCount)), systemImage: "rectangle.portrait.and.arrow.forward.fill")
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .padding(.horizontal, 4)
                .padding(.vertical, 12)
        }
        .accessibilityIdentifier("More")
    }
}
