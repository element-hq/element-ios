//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import CommonKit
import SwiftUI

final class OnboardingUseCaseSelectionCoordinator: Coordinator, Presentable {
    // MARK: - Properties
    
    // MARK: Private
    
    private let onboardingUseCaseHostingController: VectorHostingController
    private var onboardingUseCaseViewModel: OnboardingUseCaseViewModelProtocol
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: ((OnboardingUseCaseViewModelResult) -> Void)?
    
    // MARK: - Setup
    
    init() {
        let viewModel = OnboardingUseCaseViewModel()
        let view = OnboardingUseCaseSelectionScreen(viewModel: viewModel.context)
        onboardingUseCaseViewModel = viewModel
        
        onboardingUseCaseHostingController = VectorHostingController(rootView: view)
        onboardingUseCaseHostingController.vc_removeBackTitle()
        onboardingUseCaseHostingController.enableNavigationBarScrollEdgeAppearance = true
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: onboardingUseCaseHostingController)
    }
    
    // MARK: - Public

    func start() {
        MXLog.debug("[OnboardingUseCaseSelectionCoordinator] did start.")
        onboardingUseCaseViewModel.completion = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[OnboardingUseCaseSelectionCoordinator] OnboardingUseCaseViewModel did complete with result: \(result).")
            
            // Show a loading indicator which can be dismissed externally by calling `stop`.
            self.startLoading()
            self.completion?(result)
        }
    }
    
    func toPresentable() -> UIViewController {
        onboardingUseCaseHostingController
    }
    
    /// Stops any ongoing activities in the coordinator.
    func stop() {
        stopLoading()
    }
    
    // MARK: - Private
    
    /// Show an activity indicator whilst loading.
    private func startLoading() {
        loadingIndicator = indicatorPresenter.present(.loading(label: VectorL10n.loading, isInteractionBlocking: true))
    }
    
    /// Hide the currently displayed activity indicator.
    private func stopLoading() {
        loadingIndicator = nil
    }
}
