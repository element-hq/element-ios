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
    
    @Environment(\.theme) private var theme
    @Environment(\.layoutDirection) private var layoutDirection
    
    private var isLeftToRight: Bool { layoutDirection == .leftToRight }
    private var pageCount: Int { viewModel.viewState.content.count }
    
    @State private var overlayFrame: CGRect = .zero
    @State private var pageTimer: Timer?
    @State private var dragOffset: CGFloat = .zero
    
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
            OnboardingSplashScreenPageIndicator(pageCount: pageCount,
                                                pageIndex: viewModel.pageIndex)
                .padding(.vertical, 20)
            
            buttons
                .padding(.horizontal, 16)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                HStack(spacing: 0) {
                    OnboardingSplashScreenPage(content: viewModel.viewState.content[pageCount - 1],
                                               overlayHeight: overlayFrame.height + geometry.safeAreaInsets.bottom)
                        .frame(width: geometry.size.width)
                        .tag(-1)
                    
                    ForEach(0..<pageCount, id:\.self) { index in
                        let pageContent = viewModel.viewState.content[index]
                        OnboardingSplashScreenPage(content: pageContent,
                                                   overlayHeight: overlayFrame.height + geometry.safeAreaInsets.bottom)
                            .frame(width: geometry.size.width)
                            .tag(index)
                    }
                }
                .offset(x: (CGFloat(viewModel.pageIndex + 1) * -geometry.size.width) + dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged {
                            guard shouldSwipeForTranslation($0.translation.width) else { return }
                            
                            stopTimer()
                            dragOffset = isLeftToRight ? $0.translation.width : -$0.translation.width
                        }
                        .onEnded { value in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if dragOffset < -geometry.size.width / 3 {
                                    viewModel.send(viewAction: .nextPage)
                                } else if dragOffset > geometry.size.width / 3 {
                                    viewModel.send(viewAction: .previousPage)
                                }
                                
                                dragOffset = 0
                                startTimer()
                            }
                        }
                )
                
                overlay
                    .frame(width: geometry.size.width)
                    .background(ViewFrameReader(frame: $overlayFrame))
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 16)
            }
        }
        .background(theme.colors.background.ignoresSafeArea())  // whilst gradients are transparent
        .accentColor(theme.colors.accent)
        .navigationBarHidden(true)
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
    }
    
    private func shouldSwipeForTranslation(_ width: CGFloat) -> Bool {
        if viewModel.pageIndex == 0  {
            return isLeftToRight ? width < 0 : width > 0
        } else if viewModel.pageIndex == pageCount - 1 {
            return isLeftToRight ? width > 0 : width < 0
        }
        
        return true
    }
    
    private func startTimer() {
        guard pageTimer == nil else { return }
        
        pageTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { timer in
            if viewModel.pageIndex == pageCount - 1 {
                viewModel.send(viewAction: .hiddenPage)
                
                withAnimation(.easeInOut(duration: 0.7)) {
                    viewModel.send(viewAction: .nextPage)
                }
            } else {
                withAnimation(.easeInOut(duration: 0.7)) {
                    viewModel.send(viewAction: .nextPage)
                }
            }
        }
    }
    
    private func stopTimer() {
        guard let pageTimer = pageTimer else { return }
        
        self.pageTimer = nil
        pageTimer.invalidate()
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct OnboardingSplashScreen_Previews: PreviewProvider {
    static let stateRenderer = MockOnboardingSplashScreenScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
//            .environment(\.layoutDirection, .rightToLeft)
    }
}
