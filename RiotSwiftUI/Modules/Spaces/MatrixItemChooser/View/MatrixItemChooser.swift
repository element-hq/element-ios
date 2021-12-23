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
    @State var searchText: String = ""
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    @ViewBuilder
    var body: some View {
        listContent
            .background(Color.clear)
            .modifier(WaitOverlay(isLoading: .constant(viewModel.viewState.loading)))
            .alert(isPresented: .constant(viewModel.viewState.error != nil), content: {
                Alert(title: Text(MatrixKitL10n.error), message: Text(viewModel.viewState.error ?? ""), dismissButton: .cancel(Text(MatrixKitL10n.ok)))
            })
    }
    
    // MARK: Private

    @ViewBuilder
    private var listContent: some View {
        ScrollView{
            headerView
            if viewModel.viewState.items.isEmpty {
                Text(viewModel.viewState.emptyListMessage)
                    .font(theme.fonts.body)
                    .foregroundColor(theme.colors.secondaryContent)
                    .accessibility(identifier: "emptyListMessage")
                Spacer()
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.viewState.items) { item in
                        MatrixItemChooserListRow(
                            avatar: item.avatar,
                            displayName: item.displayName,
                            detailText: item.detailText,
                            isSelected: viewModel.viewState.selectedItemIds.contains(item.id)
                        )
                        .onTapGesture {
                            viewModel.send(viewAction: .itemTapped(item.id))
                        }
                    }
                }
                .accessibility(identifier: "itemsList")
                .frame(maxHeight: .infinity, alignment: .top)
                .animation(nil)
            }
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
            if viewModel.viewState.title != nil || viewModel.viewState.message != nil {
                Spacer().frame(height: 24)
            } else {
                Spacer().frame(height: 8)
            }
            SearchBar(placeholder: VectorL10n.searchDefaultPlaceholder, text: $searchText)
                .onChange(of: searchText, perform: { value in
                    viewModel.send(viewAction: .searchTextChanged(searchText))
                })
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
