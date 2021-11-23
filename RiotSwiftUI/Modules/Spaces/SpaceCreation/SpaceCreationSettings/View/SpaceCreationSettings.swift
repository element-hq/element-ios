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
        VStack(alignment: .center) {
            headerView
            formView
            footerView
        }
        .padding(EdgeInsets(top: 24, leading: 16, bottom: 24, trailing: 16))
        .background(theme.colors.background)
        .navigationTitle(viewModel.viewState.title)
        .configureNavigationBar{
            $0.navigationBar.shadowImage = UIImage()
            $0.navigationBar.barTintColor = UIColor(theme.colors.background)
            $0.navigationBar.tintColor = UIColor(theme.colors.secondaryContent)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    viewModel.send(viewAction: .cancel)
                }) {
                    Image(uiImage: Asset.Images.spacesModalClose.image).renderingMode(.template)
                }
            }
        }
    }
    
    // MARK: - Private
    
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
                ZStack {
                    GeometryReader { reader in
                        SpaceAvatarImage(mxContentUri: viewModel.viewState.avatar.mxContentUri, matrixItemId: viewModel.viewState.avatar.matrixItemId, displayName: viewModel.viewState.avatar.displayName, size: .xxLarge)
                        .gesture(TapGesture().onEnded { _ in
                            viewModel.send(viewAction: .pickImage(reader.frame(in: .global)))
                        })
                    }
                    .padding(6)
                    if let image = viewModel.viewState.avatarImage {
                        Image(uiImage: image)
                            .resizable()
                            .frame(width: 80, height: 80, alignment: .center)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .aspectRatio(contentMode: .fill)
                    }
                }.padding(10)
            Image(systemName: "camera.fill")
                .renderingMode(.template)
                .foregroundColor(theme.colors.secondaryContent)
                .frame(width: 32, height: 32, alignment: .center)
                .background(theme.colors.background)
                .clipShape(Circle())
        }.frame(width: 112, height: 112)
    }
    
    @ViewBuilder
    private var formView: some View {
        GeometryReader { geometryReader in
            ScrollView {
                ScrollViewReader { value in
                    VStack {
                        avatarView
                        Spacer()
                        VStack(alignment: .leading, spacing: 20) {
                            RoundedBorderTextField(title: VectorL10n.createRoomPlaceholderName, placeHolder: "", text: $viewModel.roomName, footerText: .constant(viewModel.viewState.roomNameError), isError: .constant(true), configuration: UIKitTextInputConfiguration( returnKeyType: .next)) { newText in
                                viewModel.send(viewAction: .nameChanged(newText))
                            }
                            RoundedBorderTextEditor(title: nil, placeHolder: VectorL10n.roomDetailsTopic, text: $viewModel.topic, textMaxHeight: 72, error: .constant(nil), onTextChanged:  {
                                newText in
                                viewModel.send(viewAction: .topicChanged(newText))
                            }, onEditingChanged: { editing in
                                if editing {
                                    value.scrollTo("topicTextEditor", anchor: .center)
                                }
                            })
                            .id("topicTextEditor")
                            if viewModel.viewState.showRoomAddress {
                                RoundedBorderTextField(title: VectorL10n.spacesCreationAddress, placeHolder: "# \(viewModel.viewState.defaultAddress)", text: $viewModel.address, footerText: .constant(viewModel.viewState.addressMessage), isError: .constant(!viewModel.viewState.isAddressValid), configuration: UIKitTextInputConfiguration(keyboardType: .URL, returnKeyType: .done, autocapitalizationType: .none), onTextChanged:  {
                                    newText in
                                    viewModel.send(viewAction: .addressChanged(newText))
                                }, onEditingChanged: { editing in
                                    if editing {
                                        value.scrollTo("addressTextField", anchor: .bottom)
                                    }
                                })
                                .id("addressTextField")
                                .accessibility(identifier: "addressTextField")
                            }
                        }
                        .padding(EdgeInsets(top: 0, leading: 2, bottom: 3, trailing: 2))
                    }
                    .animation(.easeOut(duration: 0.2))
                    .frame(minHeight: geometryReader.size.height - 2)
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
