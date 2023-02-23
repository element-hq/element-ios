// File created from TemplateAdvancedRoomsExample
// $ createSwiftUITwoScreen.sh Spaces/SpaceCreation SpaceCreation SpaceCreationMenu SpaceCreationSettings
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

struct SpaceCreationMenu: View {
    // MARK: - Properties
    
    @ObservedObject var viewModel: SpaceCreationMenuViewModelType.Context
    let showBackButton: Bool
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    var body: some View {
        mainScreen
            .navigationBarHidden(true)
    }
    
    // MARK: - Private
    
    @ViewBuilder
    private var mainScreen: some View {
        VStack {
            ThemableNavigationBar(title: nil, showBackButton: showBackButton) {
                viewModel.send(viewAction: .back)
            } closeAction: {
                viewModel.send(viewAction: .cancel)
            }
            GeometryReader { reader in
                ScrollView {
                    VStack {
                        headerView
                        Spacer()
                        optionsView
                    }
                    .frame(minHeight: reader.size.height - 2)
                }
            }
            .padding(EdgeInsets(top: 0, leading: 16, bottom: 24, trailing: 16))
        }
        .background(theme.colors.background.ignoresSafeArea())
    }
    
    @ViewBuilder
    private var headerView: some View {
        VStack {
            Text(viewModel.viewState.title)
                .multilineTextAlignment(.center)
                .font(theme.fonts.title3SB)
                .foregroundColor(theme.colors.primaryContent)
                .accessibility(identifier: "titleText")
                .padding(.bottom, 20)
            Text(viewModel.viewState.detail)
                .multilineTextAlignment(.center)
                .font(theme.fonts.body)
                .foregroundColor(theme.colors.secondaryContent)
                .accessibility(identifier: "detailText")
        }
    }
    
    @ViewBuilder
    private var optionsView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                ForEach(viewModel.viewState.options) { option in
                    OptionButton(icon: option.icon, title: option.title, detailMessage: option.detail) {
                        viewModel.send(viewAction: .didSelectOption(option.id))
                    }
                    .accessibility(identifier: "optionButton")
                }
            }
            Text(VectorL10n.spacesCreationFooter)
                .multilineTextAlignment(.center)
                .font(theme.fonts.footnote)
                .foregroundColor(theme.colors.secondaryContent)
        }
    }
}

// MARK: - Previews

struct SpaceCreationMenu_Previews: PreviewProvider {
    static let stateRenderer = MockSpaceCreationMenuScreenState.stateRenderer
    
    static var previews: some View {
        Group {
            stateRenderer.screenGroup()
                .theme(.light).preferredColorScheme(.light)
            stateRenderer.screenGroup()
                .theme(.dark).preferredColorScheme(.dark)
        }
    }
}

/// Using an enum for the screen allows you define the different state cases with
/// the relevant associated data for each case.
enum MockSpaceCreationMenuScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case options
    
    /// The associated screen
    var screenType: Any.Type {
        SpaceCreationMenu.self
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView) {
        let viewModel = SpaceCreationMenuViewModel(navTitle: VectorL10n.spacesCreateSpaceTitle, creationParams: SpaceCreationParameters(), title: "Some title", detail: "Some detail text", options: [
            SpaceCreationMenuRoomOption(id: .publicSpace, icon: Asset.Images.spaceTypeIcon.image, title: "Title of option 1", detail: "Detail of option 1"),
            SpaceCreationMenuRoomOption(id: .publicSpace, icon: Asset.Images.spaceTypeIcon.image, title: "Title of option 2", detail: "Detail of option 2")
        ])
        
        // can simulate service and viewModel actions here if needs be.
        
        return (
            [viewModel],
            AnyView(SpaceCreationMenu(viewModel: viewModel.context, showBackButton: true))
        )
    }
}
