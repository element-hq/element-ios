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
    @State private var selectedTab = 0
    
    // MARK: Public
    
    @ObservedObject var viewModel: AllChatsOnboardingViewModel.Context
    
    var body: some View {
        VStack {
            Text(VectorL10n.allChatsOnboardingTitle)
                .font(theme.fonts.title3SB)
                .foregroundColor(theme.colors.primaryContent)
                .padding()
            TabView(selection: $selectedTab) {
                ForEach(viewModel.viewState.pages.indices, id: \.self) { index in
                    let page = viewModel.viewState.pages[index]
                    AllChatsOnboardingPage(image: page.image,
                                           title: page.title,
                                           message: page.message)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button { onCallToAction() } label: {
                Text(selectedTab == viewModel.viewState.pages.count - 1 ? VectorL10n.allChatsOnboardingTryIt : VectorL10n.next)
                    .animation(nil)
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .padding()
        }
        .background(theme.colors.background.ignoresSafeArea())
        .frame(maxHeight: .infinity)
    }

    // MARK: - Private
    
    private func onCallToAction() {
        if selectedTab == viewModel.viewState.pages.count - 1 {
            viewModel.send(viewAction: .cancel)
        } else {
            withAnimation {
                selectedTab += 1
            }
        }
    }
}

// MARK: - Previews

struct AllChatsOnboarding_Previews: PreviewProvider {
    static var previews: some View {
        AllChatsOnboarding(viewModel: AllChatsOnboardingViewModel.makeAllChatsOnboardingViewModel().context).theme(.light).preferredColorScheme(.light)
        AllChatsOnboarding(viewModel: AllChatsOnboardingViewModel.makeAllChatsOnboardingViewModel().context).theme(.dark).preferredColorScheme(.dark)
    }
}
