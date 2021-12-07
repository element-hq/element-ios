// File created from SimpleUserProfileExample
// $ createScreen.sh AnalyticsPrompt AnalyticsPrompt
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
/// A prompt that asks the user whether they would like to enable Analytics or not.
struct AnalyticsPrompt: View {

    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme
    
    // MARK: Public
    
    @ObservedObject var viewModel: AnalyticsPromptViewModel.Context
    
    // MARK: Views
    
    /// The text that explains what analytics will do.
    private var descriptionText: some View {
        VStack {
            Text("\(viewModel.viewState.promptType.description)\n")
            
            AnalyticsPromptTermsText(attributedString: viewModel.viewState.promptType.termsStrings)
                .onTapGesture {
                    viewModel.send(viewAction: .openTermsURL)
                }
        }
    }
    
    /// The list of re-assurances about analytics.
    private var checkmarkList: some View {
        VStack(alignment: .leading) {
            AnalyticsPromptCheckmarkItem(attributedString: viewModel.viewState.strings.point1)
            AnalyticsPromptCheckmarkItem(attributedString: viewModel.viewState.strings.point2)
            AnalyticsPromptCheckmarkItem(string: VectorL10n.analyticsPromptPoint3)
        }
        .font(theme.fonts.body)
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
            }
            .buttonStyle(PrimaryActionButtonStyle(customColor: .clear))
            .accessibilityIdentifier("disableButton")
        }
    }
    
    var body: some View {
        VStack {
            ScrollView(showsIndicators: false) {
                VStack {
                    Image(uiImage: Asset.Images.analyticsLogo.image)
                        .padding(.bottom, 25)
                    
                    Text(VectorL10n.analyticsPromptTitle(viewModel.viewState.strings.appDisplayName))
                        .font(theme.fonts.title2B)
                        .foregroundColor(theme.colors.primaryContent)
                        .padding(.bottom, 2)
                    
                    descriptionText
                        .foregroundColor(theme.colors.secondaryContent)
                        .multilineTextAlignment(.center)
                    
                    Divider()
                        .background(theme.colors.quinaryContent)
                        .padding(.vertical, 28)
                    
                    checkmarkList
                        .foregroundColor(theme.colors.secondaryContent)
                        .padding(.bottom, 16)
                }
                .padding(.top, 50)
                .padding(.horizontal, 16)
            }
            
            buttons
                .padding(.horizontal, 16)
        }
        .background(theme.colors.background.ignoresSafeArea())
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct AnalyticsPrompt_Previews: PreviewProvider {
    static let stateRenderer = MockAnalyticsPromptScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
