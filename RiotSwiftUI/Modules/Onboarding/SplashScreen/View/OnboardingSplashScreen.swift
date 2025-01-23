//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// The splash screen shown at the beginning of the onboarding flow.
struct OnboardingSplashScreen: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme
    @Environment(\.layoutDirection) private var layoutDirection
    
    private var isLeftToRight: Bool { layoutDirection == .leftToRight }
    private var pageCount: Int { viewModel.viewState.content.count }
    
    /// A timer to automatically animate the pages.
    @State private var pageTimer: Timer?
    /// The amount of offset to apply when a drag gesture is in progress.
    @State private var dragOffset: CGFloat = .zero
    
    // MARK: Public
    
    @ObservedObject var viewModel: OnboardingSplashScreenViewModel.Context
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading) {
                Spacer()
                    .frame(height: OnboardingMetrics.spacerHeight(in: geometry))
                
                // The main content of the carousel
                HStack(alignment: .top, spacing: 0) {
                    // Add a hidden page at the start of the carousel duplicating the content of the last page
                    OnboardingSplashScreenPage(content: viewModel.viewState.content[pageCount - 1])
                        .frame(width: geometry.size.width)
                    
                    ForEach(0..<pageCount, id: \.self) { index in
                        OnboardingSplashScreenPage(content: viewModel.viewState.content[index])
                            .frame(width: geometry.size.width)
                    }
                }
                .offset(x: pageOffset(in: geometry))
                
                Spacer()
                
                OnboardingSplashScreenPageIndicator(pageCount: pageCount,
                                                    pageIndex: viewModel.pageIndex)
                    .frame(width: geometry.size.width)
                    .padding(.bottom)
                
                Spacer()
                
                buttons
                    .frame(width: geometry.size.width)
                    .padding(.bottom, OnboardingMetrics.actionButtonBottomPadding)
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 16)
                
                Spacer()
                    .frame(height: OnboardingMetrics.spacerHeight(in: geometry))
            }
            .frame(maxHeight: .infinity)
            .background(background.ignoresSafeArea().offset(x: pageOffset(in: geometry)))
            .gesture(
                DragGesture()
                    .onChanged(handleDragGestureChange)
                    .onEnded { handleDragGestureEnded($0, viewSize: geometry.size) }
            )
        }
        .accentColor(theme.colors.accent)
        .navigationBarHidden(true)
        .onAppear {
            startTimer()
        }
        .onDisappear { stopTimer() }
        .track(screen: .welcome)
    }
    
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
        .padding(.horizontal, 16)
        .readableFrame()
    }
    
    @ViewBuilder
    /// The view's background, showing a gradient in light mode and a solid colour in dark mode.
    var background: some View {
        if !theme.isDark {
            LinearGradient(gradient: viewModel.viewState.backgroundGradient,
                           startPoint: .leading,
                           endPoint: .trailing)
                .flipsForRightToLeftLayoutDirection(true)
        } else {
            theme.colors.background
        }
    }
    
    // MARK: - Animation
    
    /// Starts the animation timer for an automatic carousel effect.
    private func startTimer() {
        guard pageTimer == nil else { return }
        
        pageTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
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
    
    /// The offset to apply to the `HStack` of pages.
    private func pageOffset(in geometry: GeometryProxy) -> CGFloat {
        (CGFloat(viewModel.pageIndex + 1) * -geometry.size.width) + dragOffset
    }
    
    // MARK: - Gestures
    
    /// Whether or not a drag gesture is valid or not.
    /// - Parameter width: The gesture's translation width.
    /// - Returns: `true` if there is another page to drag to.
    private func shouldSwipeForTranslation(_ width: CGFloat) -> Bool {
        if viewModel.pageIndex == 0 {
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

struct OnboardingSplashScreen_Previews: PreviewProvider {
    static let stateRenderer = MockOnboardingSplashScreenScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
