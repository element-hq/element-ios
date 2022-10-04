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
