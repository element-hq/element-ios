//
// Copyright 2022 New Vector Ltd
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

struct UserOtherSessionsToolbar: ToolbarContent {
    @Environment(\.theme) private var theme
    
    @Binding var isEditModeEnabled: Bool
    @Binding var filter: UserOtherSessionsFilter
    @Binding var isShowLocationEnabled: Bool
    let allItemsSelected: Bool
    let sessionCount: Int
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
        Button { } label: {
            Menu {
                Button {
                    isEditModeEnabled = true
                } label: {
                    Label(VectorL10n.userOtherSessionMenuSelectSessions, systemImage: "checkmark.circle")
                }
                .disabled(sessionCount == 0)
                
                Button {
                    isShowLocationEnabled.toggle()
                } label: {
                    Label(showLocationInfo: isShowLocationEnabled)
                }
                
                if sessionCount > 0 {
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
        }
    }
}
