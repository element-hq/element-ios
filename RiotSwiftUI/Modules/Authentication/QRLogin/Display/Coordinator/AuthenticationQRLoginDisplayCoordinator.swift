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

struct AuthenticationQRLoginDisplayCoordinatorParameters {
    let navigationRouter: NavigationRouterType
    let qrLoginService: QRLoginServiceProtocol
}

enum AuthenticationQRLoginDisplayCoordinatorResult {
    /// Login with QR done
    case done
}

final class AuthenticationQRLoginDisplayCoordinator: Coordinator, Presentable {
    // MARK: - Properties
    
    // MARK: Private

    private let parameters: AuthenticationQRLoginDisplayCoordinatorParameters
    private let onboardingQRLoginDisplayHostingController: VectorHostingController
    private var onboardingQRLoginDisplayViewModel: AuthenticationQRLoginDisplayViewModelProtocol
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?
    private var navigationRouter: NavigationRouterType { parameters.navigationRouter }
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var callback: ((AuthenticationQRLoginDisplayCoordinatorResult) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: AuthenticationQRLoginDisplayCoordinatorParameters) {
        self.parameters = parameters
        let viewModel = AuthenticationQRLoginDisplayViewModel(qrLoginService: parameters.qrLoginService)
        let view = AuthenticationQRLoginDisplayScreen(context: viewModel.context)
        onboardingQRLoginDisplayViewModel = viewModel
        
        onboardingQRLoginDisplayHostingController = VectorHostingController(rootView: view)
        onboardingQRLoginDisplayHostingController.vc_removeBackTitle()
        onboardingQRLoginDisplayHostingController.enableNavigationBarScrollEdgeAppearance = true
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: onboardingQRLoginDisplayHostingController)
    }
    
    // MARK: - Public

    func start() {
        MXLog.debug("[AuthenticationQRLoginDisplayCoordinator] did start.")
        onboardingQRLoginDisplayViewModel.callback = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[AuthenticationQRLoginDisplayCoordinator] AuthenticationQRLoginDisplayViewModel did complete with result: \(result).")

            switch result {
            case .cancel:
                self.navigationRouter.popModule(animated: true)
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        onboardingQRLoginDisplayHostingController
    }
    
    /// Stops any ongoing activities in the coordinator.
    func stop() {
        stopLoading()
    }
    
    // MARK: - Private

    private func showScanQRScreen() { }

    private func showDisplayQRScreen() { }
    
    /// Show an activity indicator whilst loading.
    private func startLoading() {
        loadingIndicator = indicatorPresenter.present(.loading(label: VectorL10n.loading, isInteractionBlocking: true))
    }
    
    /// Hide the currently displayed activity indicator.
    private func stopLoading() {
        loadingIndicator = nil
    }
}
