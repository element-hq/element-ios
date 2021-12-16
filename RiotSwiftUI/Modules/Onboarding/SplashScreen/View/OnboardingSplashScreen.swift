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
struct OnboardingSplashScreen: View {

    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    @State private var overlayFrame: CGRect = .zero
    @State private var pageTimer: Timer?
    
    // MARK: Public
    
    @ObservedObject var viewModel: OnboardingSplashScreenViewModel.Context
    
    var buttons: some View {
        VStack {
            Button { viewModel.send(viewAction: .register) } label: {
                Text(VectorL10n.onboardingSplashLoginButtonTitle)
            }
            .buttonStyle(PrimaryActionButtonStyle())
            
            Button { viewModel.send(viewAction: .login) } label: {
                Text(VectorL10n.onboardingSplashRegisterButtonTitle)
                    .padding(12)
            }
        }
    }
    
    var overlay: some View {
        VStack {
            OnboardingSplashScreenPageIndicator(pageCount: viewModel.viewState.content.count,
                                                pageIndex: viewModel.pageIndex)
                .padding(.vertical, 20)
            
            buttons
                .padding(.horizontal, 16)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            // FIXME: The PageTabViewStyle breaks the safe area - replace with ScrollView or custom offsets
            TabView(selection: $viewModel.pageIndex) {
                OnboardingSplashScreenPage(content: viewModel.viewState.content[viewModel.viewState.content.count - 1],
                                           overlayHeight: overlayFrame.height + geometry.safeAreaInsets.bottom)
                    .tag(-1)
                
                ForEach(0..<viewModel.viewState.content.count, id:\.self) { index in
                    let pageContent = viewModel.viewState.content[index]
                    OnboardingSplashScreenPage(content: pageContent,
                                               overlayHeight: overlayFrame.height + geometry.safeAreaInsets.bottom)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .ignoresSafeArea()
            .overlay(overlay
                        .background(ViewFrameReader(frame: $overlayFrame))
                        .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 16),
                     alignment: .bottom)
            .accentColor(theme.colors.accent)
            .onAppear {
                pageTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { timer in
                    if viewModel.pageIndex == viewModel.viewState.content.count - 1 {
                        viewModel.send(viewAction: .hiddenPage)
                        
                        withAnimation {
                            viewModel.send(viewAction: .nextPage)
                        }
                    } else {
                        withAnimation {
                            viewModel.send(viewAction: .nextPage)
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .background(theme.colors.background.ignoresSafeArea())
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct OnboardingSplashScreen_Previews: PreviewProvider {
    static let stateRenderer = MockOnboardingSplashScreenScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
