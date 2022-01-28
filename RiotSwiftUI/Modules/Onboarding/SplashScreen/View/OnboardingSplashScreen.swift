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
/// The splash screen shown at the beginning of the onboarding flow.
struct OnboardingSplashScreen: View {

    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme
    @Environment(\.layoutDirection) private var layoutDirection
    
    private var isLeftToRight: Bool { layoutDirection == .leftToRight }
    private var pageCount: Int { viewModel.viewState.content.count }
    
    /// The dimensions of the stack with the action buttons and page indicator.
    @State private var overlayFrame: CGRect = .zero
    /// A timer to automatically animate the pages.
    @State private var pageTimer: Timer?
    /// The amount of offset to apply when a drag gesture is in progress.
    @State private var dragOffset: CGFloat = .zero
    
    // MARK: Public
    
    @ObservedObject var viewModel: OnboardingSplashScreenViewModel.Context
    
    /// The main action buttons.
    var buttons: some View {
        VStack(spacing: 12) {
            Button { viewModel.send(viewAction: .register) } label: {
                Text(VectorL10n.onboardingSplashRegisterButtonTitle)
            }
            .buttonStyle(PrimaryActionButtonStyle())
            
            Button { viewModel.send(viewAction: .login) } label: {
                Text(VectorL10n.onboardingSplashLoginButtonTitle)
                    .font(theme.fonts.body)
                    .padding(12)
            }
        }
    }
    
    /// The only part of the UI that isn't inside of the carousel.
    var overlay: some View {
        VStack(spacing: 50) {
            Color.clear
            Color.clear
            
            VStack {
                OnboardingSplashScreenPageIndicator(pageCount: pageCount,
                                                    pageIndex: viewModel.pageIndex)
                Spacer()
                
                buttons
                    .padding(.horizontal, 16)
                    .frame(maxWidth: OnboardingConstants.maxContentWidth)
                Spacer()
            }
            .background(ViewFrameReader(frame: $overlayFrame))
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                
                // The main content of the carousel
                HStack(spacing: 0) {
                    
                    // Add a hidden page at the start of the carousel duplicating the content of the last page
                    OnboardingSplashScreenPage(content: viewModel.viewState.content[pageCount - 1],
                                               overlayHeight: overlayFrame.height + geometry.safeAreaInsets.bottom)
                        .frame(width: geometry.size.width)
                        .tag(-1)
                    
                    ForEach(0..<pageCount) { index in
                        OnboardingSplashScreenPage(content: viewModel.viewState.content[index],
                                                   overlayHeight: overlayFrame.height + geometry.safeAreaInsets.bottom)
                            .frame(width: geometry.size.width)
                            .tag(index)
                    }
                    
                }
                .offset(x: (CGFloat(viewModel.pageIndex + 1) * -geometry.size.width) + dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged(handleDragGestureChange)
                        .onEnded { handleDragGestureEnded($0, viewSize: geometry.size) }
                )
                
                overlay
                    .frame(width: geometry.size.width)
            }
        }
        .background(theme.colors.background.ignoresSafeArea())
        .accentColor(theme.colors.accent)
        .navigationBarHidden(true)
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
    }
    
    // MARK: - Animation
    
    /// Starts the animation timer for an automatic carousel effect.
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
    
    /// Stops the animation timer for manual interaction.
    private func stopTimer() {
        guard let pageTimer = pageTimer else { return }
        
        self.pageTimer = nil
        pageTimer.invalidate()
    }
    
    // MARK: - Gestures
    
    /// Whether or not a drag gesture is valid or not.
    /// - Parameter width: The gesture's translation width.
    /// - Returns: `true` if there is another page to drag to.
    private func shouldSwipeForTranslation(_ width: CGFloat) -> Bool {
        if viewModel.pageIndex == 0  {
            return isLeftToRight ? width < 0 : width > 0
        } else if viewModel.pageIndex == pageCount - 1 {
            return isLeftToRight ? width > 0 : width < 0
        }
        
        return true
    }
    
    /// Updates the `dragOffset` based on the gesture's value.
    /// - Parameter drag: The drag gesture value to handle.
    private func handleDragGestureChange(_ drag: DragGesture.Value) {
        guard shouldSwipeForTranslation(drag.translation.width) else { return }
        
        stopTimer()
        
        // Animate the change over a few frames to smooth out any stuttering.
        withAnimation(.linear(duration: 0.05)) {
            dragOffset = isLeftToRight ? drag.translation.width : -drag.translation.width
        }
    }
    
    /// Clears the drag offset and informs the view model to switch to another page if necessary.
    /// - Parameter viewSize: The size of the view in which the gesture took place.
    private func handleDragGestureEnded(_ drag: DragGesture.Value, viewSize: CGSize) {
        guard shouldSwipeForTranslation(drag.predictedEndTranslation.width) else {
            // Reset the offset just in case.
            withAnimation { dragOffset = 0 }
            return
        }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            if drag.predictedEndTranslation.width < -viewSize.width / 2 {
                viewModel.send(viewAction: .nextPage)
            } else if drag.predictedEndTranslation.width > viewSize.width / 2 {
                viewModel.send(viewAction: .previousPage)
            }
            
            dragOffset = 0
        }
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
