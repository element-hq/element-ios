//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct UserOtherSessions: View {
    @Environment(\.theme) private var theme
    
    @ObservedObject var viewModel: UserOtherSessionsViewModel.Context
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                SwiftUI.Section {
                    if viewModel.viewState.sessionItems.isEmpty {
                        noItemsView()
                    } else {
                        itemsView()
                    }
                } header: {
                    UserOtherSessionsHeaderView(
                        viewData: viewModel.viewState.header,
                        onLearnMoreAction: {
                            viewModel.send(viewAction: .viewSessionInfo)
                        }
                    )
                    .padding(.vertical, 24)
                }
            }
            if viewModel.isEditModeEnabled {
                bottomToolbar()
            }
        }
        .onChange(of: viewModel.isEditModeEnabled) { _ in
            viewModel.send(viewAction: .editModeWasToggled)
        }
        .onChange(of: viewModel.filter) { _ in
            viewModel.send(viewAction: .filterWasChanged)
        }
        .background(theme.colors.system.ignoresSafeArea())
        .frame(maxHeight: .infinity)
        .navigationTitle(viewModel.viewState.title)
        .toolbar {
            UserOtherSessionsToolbar(isEditModeEnabled: $viewModel.isEditModeEnabled,
                                     filter: $viewModel.filter,
                                     isShowLocationEnabled: .init(get: { viewModel.viewState.showLocationInfo },
                                                                  set: { _ in withAnimation { viewModel.send(viewAction: .showLocationInfo) } }),
                                     allItemsSelected: viewModel.viewState.allItemsSelected,
                                     sessionCount: viewModel.viewState.sessionItems.count,
                                     showDeviceLogout: viewModel.viewState.showDeviceLogout,
                                     onToggleSelection: { viewModel.send(viewAction: .toggleAllSelection) },
                                     onSignOut: { viewModel.send(viewAction: .logoutAllUserSessions) })
        }
        .navigationBarBackButtonHidden(viewModel.isEditModeEnabled)
        .accentColor(theme.colors.accent)
    }
    
    private func noItemsView() -> some View {
        VStack {
            Text(viewModel.viewState.emptyItemsTitle)
                .font(theme.fonts.footnote)
                .foregroundColor(theme.colors.primaryContent)
                .padding(.bottom, 20)
                .accessibilityIdentifier("UserOtherSessions.noItemsText")
            Button {
                viewModel.send(viewAction: .clearFilter)
            } label: {
                VStack(spacing: 0) {
                    SeparatorLine()
                    Text(VectorL10n.userOtherSessionClearFilter)
                        .font(theme.fonts.body)
                        .foregroundColor(theme.colors.accent)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 11)
                    SeparatorLine()
                }
                .background(theme.colors.background)
            }
            .accessibilityIdentifier("UserOtherSessions.clearFilter")
        }
    }
    
    private func itemsView() -> some View {
        LazyVStack(spacing: 0) {
            ForEach(viewModel.viewState.sessionItems) { viewData in
                UserSessionListItem(viewData: viewData,
                                    showsLocationInfo: viewModel.viewState.showLocationInfo,
                                    isSeparatorHidden: viewData == viewModel.viewState.sessionItems.last,
                                    isEditModeEnabled: viewModel.isEditModeEnabled,
                                    onBackgroundTap: { sessionId in viewModel.send(viewAction: .userOtherSessionSelected(sessionId: sessionId)) },
                                    onBackgroundLongPress: { _ in })
            }
        }
        .background(theme.colors.background)
    }
    
    private func bottomToolbar() -> some View {
        VStack(spacing: 0) {
            SeparatorLine()
            HStack {
                Spacer()
                Button {
                    viewModel.send(viewAction: .logoutSelectedUserSessions)
                } label: {
                    Text(VectorL10n.signOut)
                        .foregroundColor(viewModel.viewState.enableSignOutButton ? theme.colors.alert : theme.colors.tertiaryContent)
                }
                .padding(.trailing, 16)
                .padding(.vertical, 12)
                .disabled(!viewModel.viewState.enableSignOutButton)
            }
        }
    }
}

// MARK: - Previews

struct UserOtherSessions_Previews: PreviewProvider {
    static let stateRenderer = MockUserOtherSessionsScreenState.stateRenderer
    
    static var previews: some View {
        stateRenderer.screenGroup(addNavigation: true).theme(.light).preferredColorScheme(.light)
        stateRenderer.screenGroup(addNavigation: true).theme(.dark).preferredColorScheme(.dark)
    }
}
