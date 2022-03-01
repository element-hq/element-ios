// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationMatrixItemChooser SpaceCreationMatrixItemChooser
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

@available(iOS 14.0, *)
struct MatrixItemChooser: View {
    
    // MARK: Properties
    
    @ObservedObject var viewModel: MatrixItemChooserViewModel.Context
    let listBottomPadding: CGFloat?
    @State var searchText: String = ""
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    private var spacerHeight: CGFloat {
        if viewModel.viewState.title != nil || viewModel.viewState.message != nil {
            return 24
        } else {
            return 8
        }
    }

    // MARK: Public
    
    var body: some View {
        listContent
            .background(Color.clear)
            .waitOverlay(show: viewModel.viewState.loading)
            .alert(isPresented: .constant(viewModel.viewState.error != nil)) {
                Alert(title: Text(VectorL10n.error), message: Text(viewModel.viewState.error ?? ""), dismissButton: .cancel(Text(VectorL10n.ok)))
            }
    }
    
    // MARK: Private

    @ViewBuilder
    private var listContent: some View {
        ScrollView {
            headerView
            LazyVStack(spacing: 0) {
                ForEach(viewModel.viewState.sections) { section in
                    if section.title != nil || section.infoText != nil {
                        MatrixItemChooserSectionHeader(title: section.title, infoText: section.infoText)
                    }
                    
                    if section.items.isEmpty {
                        Text(viewModel.viewState.emptyListMessage)
                            .font(theme.fonts.body)
                            .foregroundColor(theme.colors.secondaryContent)
                            .accessibility(identifier: "emptyListMessage")
                    } else {
                        ForEach(section.items) { item in
                            MatrixItemChooserListRow(
                                avatar: item.avatar,
                                type: item.type,
                                displayName: item.displayName,
                                detailText: item.detailText,
                                isSelected: viewModel.viewState.selectedItemIds.contains(item.id)
                            )
                            .onTapGesture {
                                viewModel.send(viewAction: .itemTapped(item.id))
                            }
                        }
                    }
                }
                if let listBottomPadding = listBottomPadding {
                    Spacer().frame(height: listBottomPadding)
                }
            }
            .accessibility(identifier: "sectionsList")
            .frame(maxHeight: .infinity, alignment: .top)
            .animation(nil)
        }
    }

    @ViewBuilder
    private var headerView: some View {
        VStack {
            if let title = viewModel.viewState.title {
                Text(title)
                    .font(theme.fonts.bodySB)
                    .foregroundColor(theme.colors.primaryContent)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .accessibility(identifier: "titleText")
            }
            if let message = viewModel.viewState.message {
                Text(message)
                    .font(theme.fonts.callout)
                    .foregroundColor(theme.colors.secondaryContent)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .accessibility(identifier: "messageText")
            }
            Spacer().frame(height: spacerHeight)
            SearchBar(placeholder: VectorL10n.searchDefaultPlaceholder, text: $searchText)
                .onChange(of: searchText) { value in
                    viewModel.send(viewAction: .searchTextChanged(searchText))
                }
        }
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct MatrixItemChooser_Previews: PreviewProvider {
    
    static let stateRenderer = MockMatrixItemChooserScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup(addNavigation: true)
            .theme(.light).preferredColorScheme(.light)
        stateRenderer.screenGroup(addNavigation: true)
            .theme(.dark).preferredColorScheme(.dark)
    }
}
