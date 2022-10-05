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

struct UserSessionsOverview: View {
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    @ObservedObject var viewModel: UserSessionsOverviewViewModel.Context
    
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
        .frame(maxHeight: .infinity)
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
                    .padding(.bottom, 12.0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 24)
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
                })
            } header: {
                HStack(alignment: .firstTextBaseline) {
                    Text(VectorL10n.userSessionsOverviewCurrentSessionSectionTitle)
                        .textCase(.uppercase)
                        .font(theme.fonts.footnote)
                        .foregroundColor(theme.colors.secondaryContent)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 12.0)
                        .padding(.top, 24.0)
                    
                    currentSessionMenu
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private var currentSessionMenu: some View {
        Menu {
            Button { viewModel.send(viewAction: .renameCurrentSession) } label: {
                Label(VectorL10n.manageSessionRename, systemImage: "pencil")
            }
            
            if #available(iOS 15, *) {
                Button(role: .destructive) { viewModel.send(viewAction: .logoutOfCurrentSession) } label: {
                    Label(VectorL10n.signOut, systemImage: "rectangle.portrait.and.arrow.right.fill")
                }
            } else {
                Button { viewModel.send(viewAction: .logoutOfCurrentSession) } label: {
                    Label(VectorL10n.signOut, systemImage: "rectangle.righthalf.inset.fill.arrow.right")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
    
    private var otherSessionsSection: some View {
        SwiftUI.Section {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.viewState.otherSessionsViewData) { viewData in
                    UserSessionListItem(viewData: viewData, onBackgroundTap: { sessionId in
                        viewModel.send(viewAction: .tapUserSession(sessionId))
                    })
                }
            }
            .background(theme.colors.background)
        } header: {
            VStack(alignment: .leading) {
                Text(VectorL10n.userSessionsOverviewOtherSessionsSectionTitle)
                    .textCase(.uppercase)
                    .font(theme.fonts.footnote)
                    .foregroundColor(theme.colors.secondaryContent)
                    .padding(.bottom, 8.0)
                
                Text(VectorL10n.userSessionsOverviewOtherSessionsSectionInfo)
                    .font(theme.fonts.footnote)
                    .foregroundColor(theme.colors.secondaryContent)
                    .padding(.bottom, 12.0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16.0)
            .padding(.top, 24.0)
        }
        .accessibilityIdentifier("userSessionsOverviewOtherSection")
    }
}

// MARK: - Previews

struct UserSessionsOverview_Previews: PreviewProvider {
    static let stateRenderer = MockUserSessionsOverviewScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
