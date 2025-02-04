//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import CommonKit
import SwiftUI

protocol OnboardingSplashScreenCoordinatorProtocol: Coordinator, Presentable {
    var completion: ((OnboardingSplashScreenViewModelResult) -> Void)? { get set }
}

final class OnboardingSplashScreenCoordinator: OnboardingSplashScreenCoordinatorProtocol {
    // MARK: - Properties
    
    // MARK: Private
    
    private let onboardingSplashScreenHostingController: VectorHostingController
    private var onboardingSplashScreenViewModel: OnboardingSplashScreenViewModelProtocol
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: ((OnboardingSplashScreenViewModelResult) -> Void)?
    
    // MARK: - Setup
    
    init() {
        let viewModel = OnboardingSplashScreenViewModel()
        let view = OnboardingSplashScreen(viewModel: viewModel.context)
        onboardingSplashScreenViewModel = viewModel
        onboardingSplashScreenHostingController = VectorHostingController(rootView: view)
        onboardingSplashScreenHostingController.vc_removeBackTitle()
        onboardingSplashScreenHostingController.isNavigationBarHidden = true
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: onboardingSplashScreenHostingController)
    }
    
    // MARK: - Public

    func start() {
        MXLog.debug("[OnboardingSplashScreenCoordinator] did start.")
        onboardingSplashScreenViewModel.completion = { [weak self] result in
            MXLog.debug("[OnboardingSplashScreenCoordinator] OnboardingSplashScreenViewModel did complete with result: \(result).")
            guard let self = self else { return }
            switch result {
            case .login:
                self.startLoading()
                self.completion?(result)
            case .register:
                self.completion?(result)
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        onboardingSplashScreenHostingController
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
