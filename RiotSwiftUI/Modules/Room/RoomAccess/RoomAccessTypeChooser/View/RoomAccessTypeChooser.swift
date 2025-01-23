//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct RoomAccessTypeChooser: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    @ObservedObject var viewModel: RoomAccessTypeChooserViewModelType.Context
    let roomName: String
    
    var body: some View {
        listContent
            .waitOverlay(show: viewModel.isLoading, message: viewModel.waitingMessage, allowUserInteraction: false)
            .navigationTitle(VectorL10n.roomAccessSettingsScreenNavTitle)
            .background(theme.colors.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(VectorL10n.cancel) {
                        viewModel.send(viewAction: .cancel)
                    }
                    .disabled(viewModel.isLoading)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(VectorL10n.done) {
                        viewModel.send(viewAction: .done)
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .accentColor(theme.colors.accent)
    }
    
    // MARK: Private
    
    @ViewBuilder
    private var listContent: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text(VectorL10n.roomAccessSettingsScreenTitle)
                    .foregroundColor(theme.colors.primaryContent)
                    .font(theme.fonts.bodySB)
                    .padding(.top, 24)
                Text(VectorL10n.roomAccessSettingsScreenMessage(roomName))
                    .foregroundColor(theme.colors.secondaryContent)
                    .font(theme.fonts.callout)
                    .padding(.top, 8)
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.viewState.accessItems) { item in
                        RoomAccessTypeChooserRow(isSelected: item.isSelected, title: item.title, message: item.detail, badgeText: item.badgeText)
                            .onTapGesture {
                                viewModel.send(viewAction: .didSelectAccessType(item.id))
                            }
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, 30)
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Previews

struct RoomAccessTypeChooser_Previews: PreviewProvider {
    static let stateRenderer = MockRoomAccessTypeChooserScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup(addNavigation: true)
            .theme(.light).preferredColorScheme(.light)
        stateRenderer.screenGroup(addNavigation: true)
            .theme(.dark).preferredColorScheme(.dark)
    }
}
