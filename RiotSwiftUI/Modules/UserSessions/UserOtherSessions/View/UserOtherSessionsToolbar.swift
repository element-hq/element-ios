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
    var allItemsSelected: Bool
    let onToggleSelection: () -> Void
    
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
                kebabMenu()
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
    
    private func kebabMenu() -> some View {
        Button { } label: {
            Menu {
                Button {
                    isEditModeEnabled = true
                } label: {
                    Label(VectorL10n.userOtherSessionMenuSelectSessions, systemImage: "checkmark.circle")
                }
                
            } label: {
                Image(systemName: "ellipsis")
                    .padding(.horizontal, 4)
                    .padding(.vertical, 12)
            }
        }
    }
}
