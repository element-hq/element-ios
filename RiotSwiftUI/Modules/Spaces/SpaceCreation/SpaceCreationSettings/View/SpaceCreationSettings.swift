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

import Combine
import SwiftUI

struct SpaceCreationSettings: View {
    // MARK: - Properties
    
    @ObservedObject var viewModel: SpaceCreationSettingsViewModel.Context
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    @ViewBuilder
    var body: some View {
        VStack {
            ThemableNavigationBar(title: nil, showBackButton: true) {
                viewModel.send(viewAction: .back)
            } closeAction: {
                viewModel.send(viewAction: .cancel)
            }
            mainView
        }
        .background(theme.colors.background.ignoresSafeArea())
        .navigationBarHidden(true)
    }
    
    // MARK: - Private
    
    @ViewBuilder
    private var mainView: some View {
        VStack(alignment: .center) {
            formView
            footerView
        }
        .padding(EdgeInsets(top: 0, leading: 16, bottom: 24, trailing: 16))
    }
    
    @ViewBuilder
    private var headerView: some View {
        VStack(alignment: .center, spacing: nil) {
            Text(VectorL10n.spacesCreationSettingsMessage).multilineTextAlignment(.center)
            Spacer().frame(height: 22)
        }
    }
    
    @ViewBuilder
    private var avatarView: some View {
        ZStack(alignment: .bottomTrailing) {
            GeometryReader { reader in
                ZStack {
                    SpaceAvatarImage(mxContentUri: viewModel.viewState.avatar.mxContentUri, matrixItemId: viewModel.viewState.avatar.matrixItemId, displayName: viewModel.viewState.avatar.displayName, size: .xxLarge)
                        .padding(6)
                    if let image = viewModel.viewState.avatarImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80, alignment: .center)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }.padding(10)
                    .gesture(TapGesture().onEnded { _ in
                        ResponderManager.resignFirstResponder()
                        viewModel.send(viewAction: .pickImage(reader.frame(in: .global)))
                    })
            }
            Image(uiImage: Asset.Images.spaceCreationCamera.image)
                .renderingMode(.template)
                .foregroundColor(theme.colors.secondaryContent)
                .frame(width: 32, height: 32, alignment: .center)
                .background(theme.colors.background)
                .clipShape(Circle())
        }.frame(width: 104, height: 104)
    }
    
    @ViewBuilder
    private var formView: some View {
        GeometryReader { _ in
            ScrollView {
                ScrollViewReader { scrollViewReader in
                    VStack {
                        headerView
                        Spacer()
                        avatarView
                        Spacer().frame(height: 40)
                        RoundedBorderTextField(title: VectorL10n.createRoomPlaceholderName, placeHolder: "", text: $viewModel.roomName, footerText: viewModel.viewState.roomNameError, isError: true, isFirstResponder: false, configuration: UIKitTextInputConfiguration(returnKeyType: .next), onTextChanged: { newText in
                            viewModel.send(viewAction: .nameChanged(newText))
                        })
                        .id("nameTextField")
                        .padding(.horizontal, 2)
                        .padding(.bottom, 20)
                        RoundedBorderTextEditor(title: nil, placeHolder: VectorL10n.spaceTopic, text: $viewModel.topic, textMaxHeight: 72, error: nil, onTextChanged: {
                            newText in
                            viewModel.send(viewAction: .topicChanged(newText))
                        }, onEditingChanged: { editing in
                            if editing {
                                scrollDown(reader: scrollViewReader)
                            }
                        })
                        .id("topicTextEditor")
                        .padding(.horizontal, 2)
                        .padding(.bottom, viewModel.viewState.showRoomAddress ? 20 : 3)
                        if viewModel.viewState.showRoomAddress {
                            RoundedBorderTextField(title: VectorL10n.spacesCreationAddress, placeHolder: "# \(viewModel.viewState.defaultAddress)", text: $viewModel.address, footerText: viewModel.viewState.addressMessage, isError: !viewModel.viewState.isAddressValid, configuration: UIKitTextInputConfiguration(keyboardType: .URL, returnKeyType: .done, autocapitalizationType: .none), onTextChanged: {
                                newText in
                                viewModel.send(viewAction: .addressChanged(newText))
                            })
                            .id("addressTextField")
                            .accessibility(identifier: "addressTextField")
                            .padding(.horizontal, 2)
                            .padding(.bottom, 3)
                        }
                        Spacer()
                    }
                    .animation(.easeOut(duration: 0.2))
                }
            }
        }
    }
    
    @ViewBuilder
    private var footerView: some View {
        ThemableButton(icon: nil, title: VectorL10n.next) {
            ResponderManager.resignFirstResponder()
            viewModel.send(viewAction: .done)
        }
    }
    
    private func scrollDown(reader: ScrollViewProxy) {
        let identifier = viewModel.viewState.showRoomAddress ? "addressTextField" : "topicTextEditor"
        DispatchQueue.main.async {
            withAnimation {
                reader.scrollTo(identifier, anchor: .bottom)
            }
        }
    }
}

// MARK: - Previews

struct SpaceCreationSettings_Previews: PreviewProvider {
    static let stateRenderer = MockSpaceCreationSettingsScreenState.stateRenderer
    static var previews: some View {
        Group {
            stateRenderer.screenGroup(addNavigation: true)
                .theme(.light).preferredColorScheme(.light)
            stateRenderer.screenGroup(addNavigation: true)
                .theme(.dark).preferredColorScheme(.dark)
        }
    }
}
