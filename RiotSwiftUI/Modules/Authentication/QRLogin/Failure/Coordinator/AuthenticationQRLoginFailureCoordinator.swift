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

struct AuthenticationQRLoginFailureCoordinatorParameters {
    let navigationRouter: NavigationRouterType
    let qrLoginService: QRLoginServiceProtocol
}

enum AuthenticationQRLoginFailureCoordinatorResult {
    /// Login with QR done
    case done
}

final class AuthenticationQRLoginFailureCoordinator: Coordinator, Presentable {
    // MARK: - Properties
    
    // MARK: Private

    private let parameters: AuthenticationQRLoginFailureCoordinatorParameters
    private let onboardingQRLoginFailureHostingController: VectorHostingController
    private var onboardingQRLoginFailureViewModel: AuthenticationQRLoginFailureViewModelProtocol
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?

    private var navigationRouter: NavigationRouterType { parameters.navigationRouter }
    private var qrLoginService: QRLoginServiceProtocol { parameters.qrLoginService }
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var callback: ((AuthenticationQRLoginFailureCoordinatorResult) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: AuthenticationQRLoginFailureCoordinatorParameters) {
        self.parameters = parameters
        let viewModel = AuthenticationQRLoginFailureViewModel(qrLoginService: parameters.qrLoginService)
        let view = AuthenticationQRLoginFailureScreen(context: viewModel.context)
        onboardingQRLoginFailureViewModel = viewModel
        
        onboardingQRLoginFailureHostingController = VectorHostingController(rootView: view)
        onboardingQRLoginFailureHostingController.vc_removeBackTitle()
        onboardingQRLoginFailureHostingController.enableNavigationBarScrollEdgeAppearance = true
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: onboardingQRLoginFailureHostingController)
    }
    
    // MARK: - Public

    func start() {
        MXLog.debug("[AuthenticationQRLoginFailureCoordinator] did start.")
        onboardingQRLoginFailureViewModel.callback = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[AuthenticationQRLoginFailureCoordinator] AuthenticationQRLoginFailureViewModel did complete with result: \(result).")
            
            switch result {
            case .retry:
                self.qrLoginService.restart()
            case .cancel:
                self.qrLoginService.reset()
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        onboardingQRLoginFailureHostingController
    }
    
    /// Stops any ongoing activities in the coordinator.
    func stop() {
        stopFailure()
    }
    
    // MARK: - Private
    
    /// Show an activity indicator whilst loading.
    private func startFailure() {
        loadingIndicator = indicatorPresenter.present(.loading(label: VectorL10n.loading, isInteractionBlocking: true))
    }
    
    /// Hide the currently displayed activity indicator.
    private func stopFailure() {
        loadingIndicator = nil
    }
}
