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

/// A prompt that asks the user whether they would like to enable Analytics or not.
struct AnalyticsPrompt: View {

    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 50 : 16
    }
    
    // MARK: Public
    
    @ObservedObject var viewModel: AnalyticsPromptViewModel.Context
    
    // MARK: Views
    
    /// The text that explains what analytics will do.
    private var messageText: some View {
        VStack {
            Text("\(viewModel.viewState.promptType.message)\n")
            
            InlineTextButton(viewModel.viewState.promptType.mainTermsString,
                             tappableText: viewModel.viewState.promptType.termsLinkString) {
                viewModel.send(viewAction: .openTermsURL)
            }
        }
    }
    
    /// The list of re-assurances about analytics.
    private var checkmarkList: some View {
        VStack(alignment: .leading) {
            AnalyticsPromptCheckmarkItem(attributedString: viewModel.viewState.strings.point1)
                .accessibilityLabel(Text(viewModel.viewState.strings.point1.string))
            
            AnalyticsPromptCheckmarkItem(attributedString: viewModel.viewState.strings.point2)
                .accessibilityLabel(Text(viewModel.viewState.strings.point2.string))
            
            AnalyticsPromptCheckmarkItem(string: VectorL10n.analyticsPromptPoint3)
        }
        .fixedSize(horizontal: false, vertical: true)
        .font(theme.fonts.body)
        .frame(maxWidth: .infinity)
    }
    
    private var mainContent: some View {
        VStack {
            Image(uiImage: Asset.Images.analyticsLogo.image)
                .padding(.bottom, 25)
            
            Text(VectorL10n.analyticsPromptTitle(AppInfo.current.displayName))
                .font(theme.fonts.title2B)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.primaryContent)
                .padding(.bottom, 2)
            
            messageText
                .font(theme.fonts.body)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.secondaryContent)
            
            Divider()
                .background(theme.colors.quinaryContent)
                .padding(.vertical, 28)
            
            checkmarkList
                .foregroundColor(theme.colors.secondaryContent)
                .padding(.bottom, 16)
        }
    }
    
    /// The stack of enable/disable buttons.
    private var buttons: some View {
        VStack {
            Button { viewModel.send(viewAction: .enable) } label: {
                Text(viewModel.viewState.promptType.enableButtonTitle)
                    .font(theme.fonts.bodySB)
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .accessibilityIdentifier("enableButton")
            
            Button { viewModel.send(viewAction: .disable) } label: {
                Text(viewModel.viewState.promptType.disableButtonTitle)
                    .font(theme.fonts.bodySB)
                    .foregroundColor(theme.colors.accent)
                    .padding(12)
            }
            .accessibilityIdentifier("disableButton")
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                ScrollView(showsIndicators: false) {
                    Spacer()
                        .frame(height: OnboardingMetrics.spacerHeight(in: geometry))
                    
                    mainContent
                        .readableFrame()
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, OnboardingMetrics.breakerScreenTopPadding)
                }
                
                buttons
                    .readableFrame()
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, OnboardingMetrics.actionButtonBottomPadding)
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 16)
                
                Spacer()
                    .frame(height: OnboardingMetrics.spacerHeight(in: geometry))
            }
            .background(theme.colors.background.ignoresSafeArea())
            .accentColor(theme.colors.accent)
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Previews

@available(iOS 15.0, *)
struct AnalyticsPrompt_Previews: PreviewProvider {
    static let stateRenderer = MockAnalyticsPromptScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
            .theme(.light).preferredColorScheme(.light)
        stateRenderer.screenGroup()
            .theme(.dark).preferredColorScheme(.dark)
    }
}
