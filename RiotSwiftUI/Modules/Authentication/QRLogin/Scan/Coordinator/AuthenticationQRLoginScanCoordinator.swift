//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import CommonKit
import MatrixSDK
import SwiftUI

struct AuthenticationQRLoginScanCoordinatorParameters {
    let navigationRouter: NavigationRouterType
    let qrLoginService: QRLoginServiceProtocol
}

enum AuthenticationQRLoginScanCoordinatorResult {
    /// Login with QR done
    case done
}

final class AuthenticationQRLoginScanCoordinator: Coordinator, Presentable {
    // MARK: - Properties
    
    // MARK: Private

    private let parameters: AuthenticationQRLoginScanCoordinatorParameters
    private let onboardingQRLoginScanHostingController: VectorHostingController
    private var onboardingQRLoginScanViewModel: AuthenticationQRLoginScanViewModelProtocol
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?

    private var navigationRouter: NavigationRouterType { parameters.navigationRouter }
    private var qrLoginService: QRLoginServiceProtocol { parameters.qrLoginService }
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var callback: ((AuthenticationQRLoginScanCoordinatorResult) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: AuthenticationQRLoginScanCoordinatorParameters) {
        self.parameters = parameters
        let viewModel = AuthenticationQRLoginScanViewModel(qrLoginService: parameters.qrLoginService)
        let view = AuthenticationQRLoginScanScreen(context: viewModel.context)
        onboardingQRLoginScanViewModel = viewModel
        
        onboardingQRLoginScanHostingController = VectorHostingController(rootView: view)
        onboardingQRLoginScanHostingController.vc_removeBackTitle()
        onboardingQRLoginScanHostingController.enableNavigationBarScrollEdgeAppearance = true
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: onboardingQRLoginScanHostingController)
    }
    
    // MARK: - Public

    func start() {
        MXLog.debug("[AuthenticationQRLoginScanCoordinator] did start.")
        onboardingQRLoginScanViewModel.callback = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[AuthenticationQRLoginScanCoordinator] AuthenticationQRLoginScanViewModel did complete with result: \(result).")

            switch result {
            case .goToSettings:
                self.goToSettings()
            case .displayQR:
                self.showDisplayQRScreen()
            case .qrScanned(let data):
                self.qrLoginService.stopScanning(destroy: false)
                self.qrLoginService.processScannedQR(data)
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        onboardingQRLoginScanHostingController
    }
    
    /// Stops any ongoing activities in the coordinator.
    func stop() {
        stopLoading()
    }
    
    // MARK: - Private

    private func goToSettings() {
        UIApplication.shared.vc_openSettings()
    }

    /// Shows the display QR screen.
    private func showDisplayQRScreen() {
        MXLog.debug("[AuthenticationQRLoginScanCoordinator] showDisplayQRScreen")

        let parameters = AuthenticationQRLoginDisplayCoordinatorParameters(navigationRouter: navigationRouter,
                                                                           qrLoginService: qrLoginService)
        let coordinator = AuthenticationQRLoginDisplayCoordinator(parameters: parameters)
        coordinator.callback = { [weak self, weak coordinator] _ in
            guard let self = self, let coordinator = coordinator else { return }
            self.remove(childCoordinator: coordinator)
        }

        coordinator.start()
        add(childCoordinator: coordinator)

        navigationRouter.push(coordinator, animated: true) { [weak self] in
            self?.remove(childCoordinator: coordinator)
        }
    }
    
    /// Show an activity indicator whilst loading.
    private func startLoading() {
        loadingIndicator = indicatorPresenter.present(.loading(label: VectorL10n.loading, isInteractionBlocking: true))
    }
    
    /// Hide the currently displayed activity indicator.
    private func stopLoading() {
        loadingIndicator = nil
    }
}
