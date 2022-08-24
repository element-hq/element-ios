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
            .waitOverlay(show: viewModel.viewState.loading, message: viewModel.viewState.loadingText, allowUserInteraction: false)
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
        .animation(nil)
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
            if let selectionHeader = viewModel.viewState.selectionHeader, searchText.isEmpty {
                Spacer().frame(height: spacerHeight)
                itemSelectionHeader(with: selectionHeader)
            }
        }
    }
    
    private func itemSelectionHeader(with selectionHeader: MatrixItemChooserSelectionHeader) -> some View {
        VStack(alignment:.leading) {
            HStack {
                Text(selectionHeader.title)
                    .font(theme.fonts.calloutSB)
                    .foregroundColor(theme.colors.primaryContent)
                Text("\(viewModel.viewState.itemCount)")
                    .font(theme.fonts.calloutSB)
                    .foregroundColor(theme.colors.tertiaryContent)
            }
            HStack {
                RadioButton(title: selectionHeader.selectAllTitle, selected: viewModel.viewState.itemCount > 0 && viewModel.viewState.selectedItemIds.count == viewModel.viewState.itemCount) {
                    viewModel.send(viewAction: .selectAll)
                }
                RadioButton(title: selectionHeader.selectNoneTitle, selected: viewModel.viewState.selectedItemIds.isEmpty) {
                    viewModel.send(viewAction: .selectNone)
                }
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal)
        .background(theme.colors.tile)
    }
}

// MARK: - Previews

struct MatrixItemChooser_Previews: PreviewProvider {
    
    static let stateRenderer = MockMatrixItemChooserScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup(addNavigation: false)
            .theme(.light).preferredColorScheme(.light)
        stateRenderer.screenGroup(addNavigation: false)
            .theme(.dark).preferredColorScheme(.dark)
    }
}
