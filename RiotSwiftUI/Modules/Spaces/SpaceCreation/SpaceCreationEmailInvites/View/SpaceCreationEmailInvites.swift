// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationEmailInvites SpaceCreationEmailInvites
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

struct SpaceCreationEmailInvites: View {
    // MARK: - Properties
    
    @ObservedObject var viewModel: SpaceCreationEmailInvitesViewModel.Context
    
    // MARK: - Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: - Public
    
    @ViewBuilder
    var body: some View {
        VStack {
            ThemableNavigationBar(title: nil, showBackButton: true) {
                viewModel.send(viewAction: .back)
            } closeAction: {
                viewModel.send(viewAction: .cancel)
            }
            mainView
                .animation(.easeInOut(duration: 0.2), value: viewModel.viewState.loading)
                .waitOverlay(show: viewModel.viewState.loading)
        }
        .background(theme.colors.background.ignoresSafeArea())
        .navigationBarHidden(true)
    }
    
    // MARK: - Private
    
    @ViewBuilder
    private var mainView: some View {
        VStack {
            GeometryReader { reader in
                ScrollView {
                    VStack {
                        headerView
                        Spacer()
                        formView
                    }
                    .frame(minHeight: reader.size.height - 2)
                }
            }
            footerView
        }
        .padding(EdgeInsets(top: 0, leading: 16, bottom: 24, trailing: 16))
    }

    @ViewBuilder
    private var headerView: some View {
        VStack {
            Text(VectorL10n.spacesCreationEmailInvitesTitle)
                .multilineTextAlignment(.center)
                .font(theme.fonts.title3SB)
                .foregroundColor(theme.colors.primaryContent)
            Spacer().frame(height: 20)
            Text(VectorL10n.spacesCreationEmailInvitesMessage)
                .multilineTextAlignment(.center)
                .font(theme.fonts.body)
                .foregroundColor(theme.colors.secondaryContent)
        }
    }
    
    @ViewBuilder
    private var formView: some View {
        VStack {
            VStack(spacing: 20) {
                ForEach(viewModel.emailInvites.indices, id: \.self) { index in
                    RoundedBorderTextField(title: VectorL10n.spacesCreationEmailInvitesEmailTitle, placeHolder: VectorL10n.spacesCreationEmailInvitesEmailTitle, text: $viewModel.emailInvites[index], footerText: viewModel.viewState.emailAddressesValid[index] ? nil : VectorL10n.authInvalidEmail, isError: !viewModel.viewState.emailAddressesValid[index], configuration: UIKitTextInputConfiguration(keyboardType: .emailAddress, returnKeyType: index < viewModel.emailInvites.endIndex - 1 ? .next : .done, autocapitalizationType: .none, autocorrectionType: .no))
                        .accessibility(identifier: "emailTextField")
                }
            }
            .padding(.horizontal, 2)
            .padding(.bottom)
            Text(VectorL10n.or)
                .font(theme.fonts.caption1)
                .foregroundColor(theme.colors.secondaryContent)
                .padding(.bottom)
            OptionButton(icon: Asset.Images.spacesInviteUsers.image, title: VectorL10n.spacesCreationInviteByUsername, detailMessage: nil) {
                viewModel.send(viewAction: .inviteByUsername)
            }
            .padding(.bottom)
        }
    }
    
    @ViewBuilder
    private var footerView: some View {
        ThemableButton(icon: nil, title: VectorL10n.next) {
            viewModel.send(viewAction: .done)
        }
    }
}

// MARK: - Previews

struct SpaceCreationEmailInvites_Previews: PreviewProvider {
    static let stateRenderer = MockSpaceCreationEmailInvitesScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup(addNavigation: true).theme(.light).preferredColorScheme(.light)
        stateRenderer.screenGroup(addNavigation: true).theme(.dark).preferredColorScheme(.dark)
    }
}
