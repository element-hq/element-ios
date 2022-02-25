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
/// The screen shown to a new user to select their use case for the app.
struct OnboardingUseCaseSelectionScreen: View {

    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme
    
    // MARK: Public
    
    @ObservedObject var viewModel: OnboardingUseCaseViewModel.Context
    
    /// The screen's title and instructions.
    var titleContent: some View {
        VStack(spacing: 8) {
            Image(Asset.Images.onboardingUseCaseIcon.name)
                .padding(.bottom, 8)
                .accessibilityHidden(true)
            
            Text(VectorL10n.onboardingUseCaseTitle)
                .font(theme.fonts.title2B)
                .foregroundColor(theme.colors.primaryContent)
            
            Text(VectorL10n.onboardingUseCaseMessage)
                .font(theme.fonts.body)
                .foregroundColor(theme.colors.secondaryContent)
        }
    }
    
    /// The buttons used to select a use case for the app.
    var useCaseButtons: some View {
        VStack(spacing: 8) {
            OnboardingUseCaseButton(title: VectorL10n.onboardingUseCasePersonalMessaging,
                                    image: theme.isDark ? Asset.Images.onboardingUseCasePersonalDark : Asset.Images.onboardingUseCasePersonal) {
                viewModel.send(viewAction: .answer(.personalMessaging))
            }
            
            OnboardingUseCaseButton(title: VectorL10n.onboardingUseCaseWorkMessaging,
                                    image: theme.isDark ? Asset.Images.onboardingUseCaseWorkDark : Asset.Images.onboardingUseCaseWork) {
                viewModel.send(viewAction: .answer(.workMessaging))
            }
            
            OnboardingUseCaseButton(title: VectorL10n.onboardingUseCaseCommunityMessaging,
                                    image: theme.isDark ? Asset.Images.onboardingUseCaseCommunityDark : Asset.Images.onboardingUseCaseCommunity) {
                viewModel.send(viewAction: .answer(.communityMessaging))
            }
            
            InlineTextButton(VectorL10n.onboardingUseCaseNotSureYet("%@"),
                             tappableText: VectorL10n.onboardingUseCaseSkipButton) {
                viewModel.send(viewAction: .answer(.skipped))
            }
            .font(theme.fonts.subheadline)
            .foregroundColor(theme.colors.tertiaryContent)
            .padding(.top, 8)
        }
    }
    
    /// A footer showing a button to connect to a server.
    var serverFooter: some View {
        VStack(spacing: 14) {
            Text(VectorL10n.onboardingUseCaseExistingServerMessage)
                .font(theme.fonts.subheadline)
                .foregroundColor(theme.colors.tertiaryContent)
            
            Button { viewModel.send(viewAction: .answer(.customServer)) } label: {
                Text(VectorL10n.onboardingUseCaseExistingServerButton)
                    .font(theme.fonts.body)
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                ScrollView {
                    VStack(spacing: 0) {
                        titleContent
                            .padding(.bottom, 36)
                        
                        useCaseButtons
                    }
                    .frame(maxWidth: OnboardingConstants.maxContentWidth,
                           maxHeight: OnboardingConstants.maxContentHeight)
                    .padding(16)
                }
                .frame(maxWidth: .infinity)
                
                serverFooter
                    .padding(.horizontal, 16)
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 20 : 36)
            }
        }
        .background(theme.colors.background.ignoresSafeArea())
        .accentColor(theme.colors.accent)
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct OnboardingUseCase_Previews: PreviewProvider {
    static let stateRenderer = MockOnboardingUseCaseSelectionScreenState.stateRenderer
    static var previews: some View {
        NavigationView {
            stateRenderer.screenGroup()
                .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
