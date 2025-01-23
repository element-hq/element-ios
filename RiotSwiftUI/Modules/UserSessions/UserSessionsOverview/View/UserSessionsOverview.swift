//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct UserSessionsOverview: View {
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    @ObservedObject var viewModel: UserSessionsOverviewViewModel.Context
    
    private let maxOtherSessionsToDisplay = 5
    
    var body: some View {
        ScrollView {
            if hasSecurityRecommendations {
                securityRecommendationsSection
            }
            
            currentSessionsSection
            
            if !viewModel.viewState.otherSessionsViewData.isEmpty {
                otherSessionsSection
            }
        }
        .background(theme.colors.system.ignoresSafeArea())
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(VectorL10n.userSessionsOverviewTitle)
        .navigationBarTitleDisplayMode(.inline)
        .activityIndicator(show: viewModel.viewState.showLoadingIndicator)
        .accentColor(theme.colors.accent)
        .onAppear {
            viewModel.send(viewAction: .viewAppeared)
        }
    }
    
    private var securityRecommendationsSection: some View {
        SwiftUI.Section {
            VStack(spacing: 16) {
                if !viewModel.viewState.unverifiedSessionsViewData.isEmpty {
                    SecurityRecommendationCard(style: .unverified,
                                               sessionCount: viewModel.viewState.unverifiedSessionsViewData.count) {
                        viewModel.send(viewAction: .viewAllUnverifiedSessions)
                    }
                }
                
                if !viewModel.viewState.inactiveSessionsViewData.isEmpty {
                    SecurityRecommendationCard(style: .inactive,
                                               sessionCount: viewModel.viewState.inactiveSessionsViewData.count) {
                        viewModel.send(viewAction: .viewAllInactiveSessions)
                    }
                }
            }
        } header: {
            VStack(alignment: .leading) {
                Text(VectorL10n.userSessionsOverviewSecurityRecommendationsSectionTitle)
                    .textCase(.uppercase)
                    .font(theme.fonts.footnote)
                    .foregroundColor(theme.colors.secondaryContent)
                    .padding(.bottom, 8.0)
                
                Text(VectorL10n.userSessionsOverviewSecurityRecommendationsSectionInfo)
                    .font(theme.fonts.footnote)
                    .foregroundColor(theme.colors.secondaryContent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 24)
            .padding(.bottom, 8.0)
        }
        .padding(.horizontal, 16)
        .accessibilityIdentifier("userSessionsOverviewSecurityRecommendationsSection")
    }
    
    var hasSecurityRecommendations: Bool {
        !viewModel.viewState.unverifiedSessionsViewData.isEmpty || !viewModel.viewState.inactiveSessionsViewData.isEmpty
    }
    
    @ViewBuilder
    private var currentSessionsSection: some View {
        if let currentSessionViewData = viewModel.viewState.currentSessionViewData {
            SwiftUI.Section {
                UserSessionCardView(viewData: currentSessionViewData, onVerifyAction: { _ in
                    viewModel.send(viewAction: .verifyCurrentSession)
                }, onViewDetailsAction: { _ in
                    viewModel.send(viewAction: .viewCurrentSessionDetails)
                }, showLocationInformations: viewModel.viewState.showLocationInfo, displayMode: .compact)
            } header: {
                HStack(alignment: .firstTextBaseline) {
                    Text(VectorL10n.userSessionsOverviewCurrentSessionSectionTitle)
                        .textCase(.uppercase)
                        .font(theme.fonts.footnote)
                        .foregroundColor(theme.colors.secondaryContent)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 24.0)
                    
                    currentSessionMenu
                }
                .padding(.bottom, 8.0)
            }
            .padding(.horizontal, 16)
        }
    }
    
    private var currentSessionMenu: some View {
        Menu {
            SwiftUI.Section {
                Button { viewModel.send(viewAction: .renameCurrentSession) } label: {
                    Label(VectorL10n.manageSessionRename, systemImage: "pencil")
                }
                DestructiveButton {
                    viewModel.send(viewAction: .logoutOfCurrentSession)
                } label: {
                    Label(VectorL10n.signOut, systemImage: "rectangle.portrait.and.arrow.right.fill")
                }
            }
            if viewModel.viewState.otherSessionsViewData.count > 0, viewModel.viewState.showDeviceLogout {
                DestructiveButton {
                    viewModel.send(viewAction: .logoutOtherSessions)
                } label: {
                    Label(VectorL10n.manageSessionSignOutOtherSessions, systemImage: "rectangle.portrait.and.arrow.forward.fill")
                }
            }
        } label: {
            menuImage
        }
        .accessibilityIdentifier("MoreOptionsMenu")
        .offset(x: 8) // Re-align the symbol after applying padding.
    }
    
    private var otherSessionsMenu: some View {
        Menu {
            Button {
                withAnimation {
                    viewModel.send(viewAction: .showLocationInfo)
                }
            } label: {
                Label(showLocationInfo: viewModel.viewState.showLocationInfo)
            }
            
            if viewModel.viewState.showDeviceLogout {
                DestructiveButton {
                    viewModel.send(viewAction: .logoutOtherSessions)
                } label: {
                    Label(VectorL10n.userOtherSessionMenuSignOutSessions(String(viewModel.viewState.otherSessionsViewData.count)), systemImage: "rectangle.portrait.and.arrow.forward.fill")
                }
            }
        } label: {
            menuImage
        }
    }
    
    private var menuImage: some View {
        Image(systemName: "ellipsis")
            .foregroundColor(theme.colors.secondaryContent)
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
    }
    
    private var otherSessionsSection: some View {
        SwiftUI.Section {
            LazyVStack(spacing: 0) {
                SeparatorLine(height: 0.5)
                ForEach(viewModel.viewState.otherSessionsViewData.prefix(maxOtherSessionsToDisplay)) { viewData in
                    UserSessionListItem(viewData: viewData,
                                        showsLocationInfo: viewModel.viewState.showLocationInfo,
                                        isSeparatorHidden: viewData == viewModel.viewState.otherSessionsViewData.last,
                                        onBackgroundTap: { sessionId in viewModel.send(viewAction: .tapUserSession(sessionId)) })
                }
                if viewModel.viewState.otherSessionsViewData.count > maxOtherSessionsToDisplay {
                    UserSessionsListViewAllView(count: viewModel.viewState.otherSessionsViewData.count) {
                        viewModel.send(viewAction: .viewAllOtherSessions)
                    }
                }
                SeparatorLine(height: 0.5)
            }
            .background(theme.colors.background)
        } header: {
            VStack(alignment: .leading) {
                HStack {
                    Text(VectorL10n.userSessionsOverviewOtherSessionsSectionTitle)
                        .textCase(.uppercase)
                        .font(theme.fonts.footnote)
                        .foregroundColor(theme.colors.secondaryContent)
                        .padding(.bottom, 8.0)
                    Spacer()
                    otherSessionsMenu
                }
                
                Text(VectorL10n.userSessionsOverviewOtherSessionsSectionInfo)
                    .font(theme.fonts.footnote)
                    .foregroundColor(theme.colors.secondaryContent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16.0)
            .padding(.top, 24.0)
            .padding(.bottom, 8.0)
        }
        .accessibilityIdentifier("userSessionsOverviewOtherSection")
    }

    /// The footer view containing link device button.
    var linkDeviceView: some View {
        VStack {
            Button {
                viewModel.send(viewAction: .linkDevice)
            } label: {
                Text(VectorL10n.userSessionsOverviewLinkDevice)
            }
            .buttonStyle(PrimaryActionButtonStyle(font: theme.fonts.bodySB))
            .padding(.top, 28)
            .padding(.bottom, 12)
            .padding(.horizontal, 16)
            .accessibilityIdentifier("linkDeviceButton")
        }
        .background(theme.colors.system.ignoresSafeArea())
    }
}

// MARK: - Previews

struct UserSessionsOverview_Previews: PreviewProvider {
    static let stateRenderer = MockUserSessionsOverviewScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
