//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import CommonKit
import SwiftUI

struct AuthenticationQRLoginLoadingCoordinatorParameters {
    let navigationRouter: NavigationRouterType
    let qrLoginService: QRLoginServiceProtocol
}

enum AuthenticationQRLoginLoadingCoordinatorResult {
    /// Login with QR done
    case done
}

final class AuthenticationQRLoginLoadingCoordinator: Coordinator, Presentable {
    // MARK: - Properties
    
    // MARK: Private

    private let parameters: AuthenticationQRLoginLoadingCoordinatorParameters
    private let onboardingQRLoginLoadingHostingController: VectorHostingController
    private var onboardingQRLoginLoadingViewModel: AuthenticationQRLoginLoadingViewModelProtocol
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?

    private var navigationRouter: NavigationRouterType { parameters.navigationRouter }
    private var qrLoginService: QRLoginServiceProtocol { parameters.qrLoginService }
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var callback: ((AuthenticationQRLoginLoadingCoordinatorResult) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: AuthenticationQRLoginLoadingCoordinatorParameters) {
        self.parameters = parameters
        let viewModel = AuthenticationQRLoginLoadingViewModel(qrLoginService: parameters.qrLoginService)
        let view = AuthenticationQRLoginLoadingScreen(context: viewModel.context)
        onboardingQRLoginLoadingViewModel = viewModel
        
        onboardingQRLoginLoadingHostingController = VectorHostingController(rootView: view)
        onboardingQRLoginLoadingHostingController.vc_removeBackTitle()
        onboardingQRLoginLoadingHostingController.enableNavigationBarScrollEdgeAppearance = true
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: onboardingQRLoginLoadingHostingController)
    }
    
    // MARK: - Public

    func start() {
        MXLog.debug("[AuthenticationQRLoginLoadingCoordinator] did start.")
        onboardingQRLoginLoadingViewModel.callback = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[AuthenticationQRLoginLoadingCoordinator] AuthenticationQRLoginLoadingViewModel did complete with result: \(result).")
            
            switch result {
            case .cancel:
                self.qrLoginService.reset()
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        onboardingQRLoginLoadingHostingController
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
