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

struct UserSessionOverview: View {
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    @ObservedObject var viewModel: UserSessionOverviewViewModel.Context
    
    var body: some View {
        ScrollView {
            UserSessionCardView(viewData: viewModel.viewState.cardViewData, onVerifyAction: { _ in
                viewModel.send(viewAction: .verifyCurrentSession)
            },
            onViewDetailsAction: { _ in
                viewModel.send(viewAction: .viewSessionDetails)
            })
            .padding(16)
            SwiftUI.Section {
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
            
            SwiftUI.Section {
                UserSessionOverviewItem(title: VectorL10n.manageSessionSignOut,
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
                    Button { viewModel.send(viewAction: .renameSession) } label: {
                        Label(VectorL10n.manageSessionRename, systemImage: "pencil")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
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
