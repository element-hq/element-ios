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

struct UserOtherSessions: View {
    
    @Environment(\.theme) private var theme
    
    @ObservedObject var viewModel: UserOtherSessionsViewModel.Context
    
    var body: some View {
        ScrollView {
            ForEach(viewModel.viewState.sections) { section in
                switch section {
                case let .sessionItems(header: header, items: items):
                    createSessionItemsSection(header: header, items: items)
                }
            }
        }
        .background(theme.colors.system.ignoresSafeArea())
        .frame(maxHeight: .infinity)
        .navigationTitle(viewModel.viewState.title)
    }
    
    private func createSessionItemsSection(header: UserOtherSessionsHeaderViewData, items: [UserSessionListItemViewData]) -> some View {
        SwiftUI.Section {
            LazyVStack(spacing: 0) {
                ForEach(items) { viewData in
                    UserSessionListItem(viewData: viewData, onBackgroundTap: { sessionId in
                        viewModel.send(viewAction: .userOtherSessionSelected(sessionId: sessionId))
                    })
                }
            }
            .background(theme.colors.background)
        } header: {
            UserOtherSessionsHeaderView(viewData: header)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 24.0)
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
