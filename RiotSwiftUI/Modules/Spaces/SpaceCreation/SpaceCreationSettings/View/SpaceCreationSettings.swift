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
import Combine

@available(iOS 14.0, *)
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
        .background(theme.colors.background)
        .navigationBarHidden(true)
        .onTapGesture {
            ResponderManager.resignFirstResponder()
        }
    }
    
    // MARK: - Private
    
    @ViewBuilder
    private var mainView: some View {
        GeometryReader { geometryReader in
            ZStack(alignment: .center) {
                VStack(alignment: .center) {
                    if geometryReader.size.height > 650 {
                        Spacer().frame(height: 10)
                    }
                    headerView
                    if !viewModel.viewState.showRoomAddress {
                        Spacer().frame(height: geometryReader.size.height / 20)
                    } else {
                        Spacer().frame(height: geometryReader.size.height / 30)
                    }
                    avatarView
                    Spacer()
                }
                .background(theme.colors.background)
                VStack(alignment: .center) {
                    if viewModel.viewState.showRoomAddress && geometryReader.size.height > 650 {
                        Spacer()
                    }
                    Spacer()
                    formView
                    if !viewModel.viewState.showRoomAddress {
                        if geometryReader.size.height > 650 {
                            Spacer().frame(height:geometryReader.size.height / 4)
                        } else {
                            Spacer().frame(height:geometryReader.size.height / 4)
                        }
                    } else {
                        if geometryReader.size.height > 650 {
                            Spacer().frame(height:geometryReader.size.height / 10)
                        }
                    }
                    footerView
                }
            }
        }
        .padding(EdgeInsets(top: 0, leading: 16, bottom: 24, trailing: 16))
    }
    
    @ViewBuilder
    private var headerView: some View {
        VStack(alignment: .center, spacing: nil) {
            Text(VectorL10n.spacesCreationSettingsMessage).multilineTextAlignment(.center)
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
        VStack{
            RoundedBorderTextField(
                title: VectorL10n.createRoomPlaceholderName,
                placeHolder: "",
                text: $viewModel.roomName,
                footerText: .constant(viewModel.viewState.roomNameError),
                isError: .constant(true),
                isFirstResponder: true,
                configuration: UIKitTextInputConfiguration( returnKeyType: .next),
                onTextChanged: { newText in
                    viewModel.send(viewAction: .nameChanged(newText))
                })
            .padding(.horizontal, 2)
            .padding(.bottom, 20)
            RoundedBorderTextEditor(
                title: nil,
                placeHolder: VectorL10n.spaceTopic,
                text: $viewModel.topic,
                textMaxHeight: 72,
                error: .constant(nil),
                onTextChanged:  { newText in
                    viewModel.send(viewAction: .topicChanged(newText))
                })
            .padding(.horizontal, 2)
            .padding(.bottom, viewModel.viewState.showRoomAddress ? 20 : 3)
            if viewModel.viewState.showRoomAddress {
                RoundedBorderTextField(
                    title: VectorL10n.spacesCreationAddress,
                    placeHolder: "# \(viewModel.viewState.defaultAddress)",
                    text: $viewModel.address,
                    footerText: .constant(viewModel.viewState.addressMessage),
                    isError: .constant(!viewModel.viewState.isAddressValid),
                    configuration: UIKitTextInputConfiguration(keyboardType: .URL, returnKeyType: .done, autocapitalizationType: .none),
                    onTextChanged:  { newText in
                        viewModel.send(viewAction: .addressChanged(newText))
                    })
                .padding(.horizontal, 2)
                .padding(.bottom, 3)
                .accessibility(identifier: "addressTextField")
            }
        }
        .background(theme.colors.background)
    }
    
    @ViewBuilder
    private var footerView: some View {
        ThemableButton(icon: nil, title: VectorL10n.next) {
            ResponderManager.resignFirstResponder()
            viewModel.send(viewAction: .done)
        }
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
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
