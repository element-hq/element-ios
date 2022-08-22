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

struct SpaceSelector: View {

    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    @ObservedObject var viewModel: SpaceSelectorViewModel.Context
    
    var body: some View {
        VStack {
            if !viewModel.viewState.items.isEmpty {
                itemListView
            } else {
                emptyListPlaceholder
            }
        }
        .background(theme.colors.background.edgesIgnoringSafeArea(.all))
        .accentColor(theme.colors.accent)
    }
    
    private var itemListView: some View {
        ScrollView {
            LazyVStack {
                ForEach(viewModel.viewState.items) { item in
                    SpaceSelectorListRow(avatar: item.avatar,
                                         icon: item.icon,
                                         displayName: item.displayName,
                                         hasSubItems: item.hasSubItems,
                                         isJoined: item.isJoined,
                                         isSelected: item.id == viewModel.viewState.selectedSpaceId,
                                         notificationCount: item.notificationCount,
                                         highlightedNotificationCount: item.highlightedNotificationCount,
                                         disclosureAction: {
                                            viewModel.send(viewAction: .spaceDisclosure(item))
                                         }
                        )
                        .onTapGesture {
                            viewModel.send(viewAction: .spaceSelected(item))
                        }
                }
            }
        }
        .frame(maxHeight: .infinity)
        .navigationTitle(viewModel.viewState.navigationTitle)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(VectorL10n.create) {
                    viewModel.send(viewAction: .createSpace)
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                if viewModel.viewState.showCancel {
                    Button(VectorL10n.cancel) {
                        viewModel.send(viewAction: .cancel)
                    }
                }
            }
        }
    }
    
    private var emptyListPlaceholder: some View {
        VStack {
            Spacer()
            Text(VectorL10n.spaceSelectorEmptyViewTitle)
                .foregroundColor(theme.colors.primaryContent)
                .font(theme.fonts.title3SB)
                .accessibility(identifier: "emptyListPlaceholderTitle")
            Spacer()
                .frame(height: 24)
            Text(VectorL10n.spaceSelectorEmptyViewInformation)
                .foregroundColor(theme.colors.secondaryContent)
                .font(theme.fonts.callout)
                .multilineTextAlignment(.center)
                .accessibility(identifier: "emptyListPlaceholderMessage")
            Spacer()
            Button { viewModel.send(viewAction: .createSpace) } label: {
                Text(VectorL10n.spaceSelectorCreateSpace)
                    .font(theme.fonts.bodySB)
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .accessibility(identifier: "createSpaceButton")
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
}

// MARK: - Previews

struct SpaceSelector_Previews: PreviewProvider {
    static let stateRenderer = MockSpaceSelectorScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
