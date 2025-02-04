//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct UserSessionOverview: View {
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    @ObservedObject var viewModel: UserSessionOverviewViewModel.Context
    
    var body: some View {
        ScrollView {
            UserSessionCardView(
                viewData: viewModel.viewState.cardViewData,
                onVerifyAction: { _ in
                    viewModel.send(viewAction: .verifySession)
                },
                onViewDetailsAction: { _ in
                    viewModel.send(viewAction: .viewSessionDetails)
                },
                onLearnMoreAction: {
                    viewModel.send(viewAction: .viewSessionInfo)
                },
                showLocationInformations: viewModel.viewState.showLocationInfo,
                displayMode: .extended
            )
            .padding(16)
            
            SwiftUI.Section {
                VStack(spacing: 24) {
                    UserSessionOverviewItem(title: VectorL10n.userSessionOverviewSessionDetailsButtonTitle,
                                            showsChevron: true) {
                        viewModel.send(viewAction: .viewSessionDetails)
                    }
                    
                    if let enabled = viewModel.viewState.isPusherEnabled {
                        UserSessionOverviewToggleCell(title: VectorL10n.userSessionPushNotifications,
                                                      message: VectorL10n.userSessionPushNotificationsMessage,
                                                      isOn: enabled, isEnabled: viewModel.viewState.remotelyTogglingPushersAvailable) {
                            viewModel.send(viewAction: .togglePushNotifications)
                        }
                    }
                }
            }
            
            SwiftUI.Section {
                UserSessionOverviewItem(title: VectorL10n.manageSessionSignOut,
                                        alignment: .center,
                                        isDestructive: true) {
                    viewModel.send(viewAction: .logoutOfSession)
                }
            }
        }
        .background(theme.colors.system.ignoresSafeArea())
        .frame(maxHeight: .infinity)
        .waitOverlay(show: viewModel.viewState.showLoadingIndicator, allowUserInteraction: false)
        .navigationTitle(viewModel.viewState.isCurrentSession ?
            VectorL10n.userSessionOverviewCurrentSessionTitle :
            VectorL10n.userSessionOverviewSessionTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    SwiftUI.Section {
                        Button { viewModel.send(viewAction: .renameSession) } label: {
                            Label(VectorL10n.manageSessionRename, systemImage: "pencil")
                        }
                        .accessibilityIdentifier(VectorL10n.manageSessionRename)
                        
                        Button {
                            viewModel.send(viewAction: .showLocationInfo)
                        } label: {
                            Label(showLocationInfo: viewModel.viewState.showLocationInfo)
                        }
                    }
                    DestructiveButton {
                        viewModel.send(viewAction: .logoutOfSession)
                    } label: {
                        Label(VectorL10n.signOut, systemImage: "rectangle.portrait.and.arrow.right.fill")
                    }
                    .accessibilityIdentifier(VectorL10n.signOut)
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(theme.colors.accent)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 12)
                }
                .offset(x: 4) // Re-align the symbol after applying padding.
                .accessibilityIdentifier("Menu")
            }
        }
        .accentColor(theme.colors.accent)
    }
}

// MARK: - Previews

struct UserSessionOverview_Previews: PreviewProvider {
    static let stateRenderer = MockUserSessionOverviewScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup(addNavigation: true).theme(.light).preferredColorScheme(.light)
        stateRenderer.screenGroup(addNavigation: true).theme(.dark).preferredColorScheme(.dark)
    }
}
