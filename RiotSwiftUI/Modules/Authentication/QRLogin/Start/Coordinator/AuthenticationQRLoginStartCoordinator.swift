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

struct AuthenticationQRLoginStartCoordinatorParameters {
    let navigationRouter: NavigationRouterType
    let authenticationService: AuthenticationService
}

enum AuthenticationQRLoginStartCoordinatorResult {
    /// Login with QR done
    case done
}

final class AuthenticationQRLoginStartCoordinator: Coordinator, Presentable {
    // MARK: - Properties
    
    // MARK: Private

    private let parameters: AuthenticationQRLoginStartCoordinatorParameters
    private let onboardingQRLoginStartHostingController: VectorHostingController
    private var onboardingQRLoginStartViewModel: AuthenticationQRLoginStartViewModelProtocol
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var callback: ((AuthenticationQRLoginStartCoordinatorResult) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: AuthenticationQRLoginStartCoordinatorParameters) {
        self.parameters = parameters
        let viewModel = AuthenticationQRLoginStartViewModel()
        let view = AuthenticationQRLoginStartScreen(viewModel: viewModel.context)
        onboardingQRLoginStartViewModel = viewModel
        
        onboardingQRLoginStartHostingController = VectorHostingController(rootView: view)
        onboardingQRLoginStartHostingController.vc_removeBackTitle()
        onboardingQRLoginStartHostingController.enableNavigationBarScrollEdgeAppearance = true
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: onboardingQRLoginStartHostingController)
    }
    
    // MARK: - Public

    func start() {
        MXLog.debug("[AuthenticationQRLoginStartCoordinator] did start.")
        onboardingQRLoginStartViewModel.callback = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[AuthenticationQRLoginStartCoordinator] AuthenticationQRLoginStartViewModel did complete with result: \(result).")

            switch result {
            case .scanQR:
                self.showScanQRScreen()
            case .displayQR:
                self.showDisplayQRScreen()
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        onboardingQRLoginStartHostingController
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
