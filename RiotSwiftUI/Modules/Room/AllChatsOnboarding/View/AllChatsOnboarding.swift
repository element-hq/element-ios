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

struct AllChatsOnboarding: View {

    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    @ObservedObject var viewModel: AllChatsOnboardingViewModel.Context
    
    var body: some View {
        VStack {
            Text(VectorL10n.allChatsOnboardingTitle)
                .font(theme.fonts.title3SB)
                .foregroundColor(theme.colors.primaryContent)
                .padding()
            TabView {
                ForEach(viewModel.viewState.pages) { page in
                    pageView(image: page.image,
                             title: page.title,
                             message: page.message)
                }
            }
            .tabViewStyle(PageTabViewStyle())

            Button { viewModel.send(viewAction: .cancel) } label: {
                Text(VectorL10n.allChatsOnboardingTryIt)
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .padding()
        }
        .background(theme.colors.background.ignoresSafeArea())
        .frame(maxHeight: .infinity)
        .onAppear {
            self.setupAppearance()
        }
    }
    
    @ViewBuilder
    private func pageView(image: UIImage, title: String, message: String) -> some View {
        VStack {
            Spacer()
            Image(uiImage: image)
            Spacer()
            Text(title)
                .font(theme.fonts.title2B)
                .foregroundColor(theme.colors.primaryContent)
                .padding(.bottom, 16)
            Text(message)
                .multilineTextAlignment(.center)
                .font(theme.fonts.callout)
                .foregroundColor(theme.colors.primaryContent)
            Spacer()
        }
        .padding(.horizontal)
    }
    
    private func setupAppearance() {
        let tintColor: UIColor = theme.isDark ? .white : .black
        UIPageControl.appearance().currentPageIndicatorTintColor = tintColor
        UIPageControl.appearance().pageIndicatorTintColor = tintColor.withAlphaComponent(0.2)
    }
}

// MARK: - Previews

struct AllChatsOnboarding_Previews: PreviewProvider {
    static var previews: some View {
        AllChatsOnboarding(viewModel: AllChatsOnboardingViewModel.makeAllChatsOnboardingViewModel().context).theme(.light).preferredColorScheme(.light)
        AllChatsOnboarding(viewModel: AllChatsOnboardingViewModel.makeAllChatsOnboardingViewModel().context).theme(.dark).preferredColorScheme(.dark)
    }
}
