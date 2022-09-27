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

import DesignKit
import SwiftUI

struct OnboardingAvatarScreen: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme
    
    @State private var isPresentingPickerSelection = false
    
    // MARK: Public
    
    @ObservedObject var viewModel: OnboardingAvatarViewModel.Context
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                avatar
                    .padding(.horizontal, 2)
                    .padding(.bottom, 40)
                
                header
                    .padding(.bottom, 40)
                
                buttons
            }
            .readableFrame()
            .padding(.horizontal)
            .padding(.top, OnboardingMetrics.topPaddingToNavigationBar)
        }
        .frame(maxHeight: .infinity)
        .background(theme.colors.background.ignoresSafeArea())
        .alert(item: $viewModel.alertInfo) { $0.alert }
        .accentColor(theme.colors.accent)
    }
    
    /// The user's avatar along with a picker button
    var avatar: some View {
        Group {
            if let avatarImage = viewModel.viewState.avatar {
                Image(uiImage: avatarImage)
                    .resizable()
                    .scaledToFill()
                    .accessibilityIdentifier("avatarImage")
            } else {
                PlaceholderAvatarImage(firstCharacter: viewModel.viewState.placeholderAvatarLetter,
                                       colorIndex: viewModel.viewState.placeholderAvatarColorIndex)
                    .accessibilityIdentifier("placeholderAvatar")
            }
        }
        .clipShape(Circle())
        .frame(width: 120, height: 120)
        .overlay(cameraButton, alignment: .bottomTrailing)
        .onTapGesture { isPresentingPickerSelection = true }
        .actionSheet(isPresented: $isPresentingPickerSelection) { pickerSelectionActionSheet }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(VectorL10n.onboardingAvatarAccessibilityLabel)
        .accessibilityValue(VectorL10n.edit)
    }
    
    /// The button to indicate the user can tap to select an avatar
    /// Note: The whole avatar is tappable to make this easier.
    var cameraButton: some View {
        ZStack {
            Circle()
                .foregroundColor(theme.colors.background)
                .shadow(color: .black.opacity(0.15), radius: 2.4, y: 2.4)
            
            Image(viewModel.viewState.buttonImage.name)
                .renderingMode(.template)
                .foregroundColor(theme.colors.secondaryContent)
        }
        .frame(width: 40, height: 40)
    }
    
    /// The action sheet that asks how the user would like to set their avatar.
    var pickerSelectionActionSheet: ActionSheet {
        ActionSheet(title: Text(VectorL10n.onboardingAvatarTitle), buttons: [
            .default(Text(VectorL10n.imagePickerActionCamera)) {
                viewModel.send(viewAction: .takePhoto)
            },
            .default(Text(VectorL10n.imagePickerActionLibrary)) {
                viewModel.send(viewAction: .pickImage)
            },
            .cancel()
        ])
    }
    
    /// The screen's title and message views.
    var header: some View {
        VStack(spacing: 8) {
            Text(VectorL10n.onboardingAvatarTitle)
                .font(theme.fonts.title2B)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.primaryContent)
            
            Text(VectorL10n.onboardingAvatarMessage)
                .font(theme.fonts.body)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.secondaryContent)
        }
    }
    
    /// The main action buttons in the form.
    var buttons: some View {
        VStack(spacing: 8) {
            Button(VectorL10n.onboardingPersonalizationSave) {
                viewModel.send(viewAction: .save)
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .disabled(viewModel.viewState.avatar == nil)
            .accessibilityIdentifier("saveButton")
            
            Button { viewModel.send(viewAction: .skip) } label: {
                Text(VectorL10n.onboardingPersonalizationSkip)
                    .font(theme.fonts.body)
                    .padding(12)
            }
        }
    }
}

// MARK: - Previews

@available(iOS 15.0, *)
struct OnboardingAvatar_Previews: PreviewProvider {
    static let stateRenderer = MockOnboardingAvatarScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup(addNavigation: true)
            .navigationViewStyle(.stack)
            .theme(.light).preferredColorScheme(.light)
        stateRenderer.screenGroup(addNavigation: true)
            .navigationViewStyle(.stack)
            .theme(.dark).preferredColorScheme(.dark)
    }
}
