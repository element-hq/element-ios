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

struct AuthenticationQRLoginConfirmCoordinatorParameters {
    let navigationRouter: NavigationRouterType
    let qrLoginService: QRLoginServiceProtocol
}

enum AuthenticationQRLoginConfirmCoordinatorResult {
    /// Login with QR done
    case done
}

final class AuthenticationQRLoginConfirmCoordinator: Coordinator, Presentable {
    // MARK: - Properties
    
    // MARK: Private

    private let parameters: AuthenticationQRLoginConfirmCoordinatorParameters
    private let onboardingQRLoginConfirmHostingController: VectorHostingController
    private var onboardingQRLoginConfirmViewModel: AuthenticationQRLoginConfirmViewModelProtocol
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?

    private var navigationRouter: NavigationRouterType { parameters.navigationRouter }
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var callback: ((AuthenticationQRLoginConfirmCoordinatorResult) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: AuthenticationQRLoginConfirmCoordinatorParameters) {
        self.parameters = parameters
        let viewModel = AuthenticationQRLoginConfirmViewModel(qrLoginService: parameters.qrLoginService)
        let view = AuthenticationQRLoginConfirmScreen(context: viewModel.context)
        onboardingQRLoginConfirmViewModel = viewModel
        
        onboardingQRLoginConfirmHostingController = VectorHostingController(rootView: view)
        onboardingQRLoginConfirmHostingController.vc_removeBackTitle()
        onboardingQRLoginConfirmHostingController.enableNavigationBarScrollEdgeAppearance = true
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: onboardingQRLoginConfirmHostingController)
    }
    
    // MARK: - Public

    func start() {
        MXLog.debug("[AuthenticationQRLoginConfirmCoordinator] did start.")
        onboardingQRLoginConfirmViewModel.callback = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[AuthenticationQRLoginConfirmCoordinator] AuthenticationQRLoginConfirmViewModel did complete with result: \(result).")
            
            switch result {
            case .confirm:
                self.parameters.qrLoginService.confirmCode()
            case .cancel:
                self.parameters.qrLoginService.reset()
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        onboardingQRLoginConfirmHostingController
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
