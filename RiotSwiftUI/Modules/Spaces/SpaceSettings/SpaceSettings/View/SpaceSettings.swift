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
struct SpaceSettings: View {

    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    @ObservedObject var viewModel: SpaceSettingsViewModel.Context
    
    var body: some View {
        ScrollView {
            VStack {
                avatarView
                Spacer().frame(height:32)
                formView
                roomAccess
                options
            }
        }
        .background(theme.colors.navigation)
        .modifier(WaitOverlay(allowUserInteraction: false, isLoading: .constant(viewModel.viewState.isLoading)))
        .ignoresSafeArea(.container, edges: .bottom)
        .frame(maxHeight: .infinity)
        .navigationBarBackButtonHidden(true)
        .navigationTitle(VectorL10n.settingsTitle)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(VectorL10n.done) {
                    updateSpace()
                }
                .disabled(!viewModel.viewState.isModified)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button(VectorL10n.cancel) {
                    viewModel.send(viewAction: .cancel)
                }
            }
        }
        .alert(isPresented: $viewModel.showPostProcessAlert, content: {
            Alert(title: Text(VectorL10n.settingsTitle),
                  message: Text(VectorL10n.spaceSettingsUpdateFailedMessage),
                  primaryButton: .default(Text(VectorL10n.retry), action: {
                    updateSpace()
                  }),
                  secondaryButton: .cancel())
        })
    }
    
    // MARK: - Private
    
    @ViewBuilder
    private var avatarView: some View {
        ZStack(alignment: .bottomTrailing) {
            GeometryReader { reader in
                ZStack {
                    SpaceAvatarImage(mxContentUri: viewModel.viewState.avatar.mxContentUri, matrixItemId: viewModel.viewState.avatar.matrixItemId, displayName: viewModel.viewState.avatar.displayName, size: .xxLarge)
                    .padding(6)
                    if let image = viewModel.viewState.userSelectedAvatar {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80, alignment: .center)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }.padding(10)
                .gesture(TapGesture().onEnded { _ in
                    guard viewModel.viewState.roomProperties?.isAvatarEditable == true else {
                        return
                    }
                    ResponderManager.resignFirstResponder()
                    viewModel.send(viewAction: .pickImage(reader.frame(in: .global)))
                })
            }
            if viewModel.viewState.roomProperties?.isAvatarEditable == true {
                Image(uiImage: Asset.Images.spaceCreationCamera.image)
                    .renderingMode(.template)
                    .foregroundColor(theme.colors.secondaryContent)
                    .frame(width: 32, height: 32, alignment: .center)
                    .background(theme.colors.background)
                    .clipShape(Circle())
            }
        }.frame(width: 104, height: 104)
    }
    
    @ViewBuilder
    private var formView: some View {
        VStack{
            RoundedBorderTextField(
                title: VectorL10n.createRoomPlaceholderName,
                placeHolder: "",
                text: $viewModel.name,
                isEnabled: viewModel.viewState.roomProperties?.isNameEditable == true,
                footerText: .constant(viewModel.viewState.roomNameError),
                isError: .constant(true),
                configuration: UIKitTextInputConfiguration( returnKeyType: .next))
                .padding(.horizontal, 2)
                .padding(.bottom, 20)
            RoundedBorderTextEditor(
                title: VectorL10n.spaceTopic,
                placeHolder: VectorL10n.spaceTopic,
                text: $viewModel.topic,
                isEnabled: viewModel.viewState.roomProperties?.isTopicEditable == true,
                textMaxHeight: 72,
                error: .constant(nil))
                .padding(.horizontal, 2)
                .padding(.bottom, viewModel.viewState.showRoomAddress ? 20 : 3)
            if viewModel.viewState.showRoomAddress {
                RoundedBorderTextField(
                    title: VectorL10n.spacesCreationAddress,
                    placeHolder: "# \(viewModel.viewState.defaultAddress)",
                    text: $viewModel.address,
                    isEnabled: viewModel.viewState.roomProperties?.isAddressEditable == true,
                    footerText: .constant(viewModel.viewState.addressMessage),
                    isError: .constant(!viewModel.viewState.isAddressValid),
                    configuration: UIKitTextInputConfiguration(keyboardType: .URL, returnKeyType: .done, autocapitalizationType: .none))
                    .padding(.horizontal, 2)
                    .padding(.bottom, 3)
                    .accessibility(identifier: "addressTextField")
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var roomAccess: some View {
        VStack(alignment:.leading) {
            Spacer().frame(height:24)
            Text(VectorL10n.spaceSettingsAccessSection)
                .font(theme.fonts.footnote)
                .foregroundColor(theme.colors.secondaryContent)
                .padding(.leading)
                .padding(.bottom, 4)
            SpaceSettingsOptionListItem(
                title: VectorL10n.roomDetailsAccessRowTitle,
                value: viewModel.viewState.visibilityString,
                isEnabled: viewModel.viewState.roomProperties?.isAccessEditable == true) {
                ResponderManager.resignFirstResponder()
                viewModel.send(viewAction: .optionSelected(.visibility))
            }
        }
    }
    
    @ViewBuilder
    private var options: some View {
        VStack(alignment:.leading, spacing:1) {
            Spacer().frame(height:50)
            Text(VectorL10n.settingsTitle.uppercased())
                .font(theme.fonts.footnote)
                .foregroundColor(theme.colors.secondaryContent)
                .padding(.leading)
                .padding(.bottom, 8)
            ForEach(viewModel.viewState.options) { option in
                SpaceSettingsOptionListItem(
                    icon: option.icon,
                    title: option.title,
                    value: option.value,
                    isEnabled: option.isEnabled) {
                    ResponderManager.resignFirstResponder()
                    viewModel.send(viewAction: .optionSelected(option.id))
                }
            }
        }
    }
    
    private func updateSpace() {
        viewModel.send(viewAction: .done(viewModel.name, viewModel.topic, viewModel.address, viewModel.viewState.userSelectedAvatar))
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct SpaceSettings_Previews: PreviewProvider {
    static let stateRenderer = MockSpaceSettingsScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
        stateRenderer.screenGroup().theme(.dark).preferredColorScheme(.dark)
    }
}
