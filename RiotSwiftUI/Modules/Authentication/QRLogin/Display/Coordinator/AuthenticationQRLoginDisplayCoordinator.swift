//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
