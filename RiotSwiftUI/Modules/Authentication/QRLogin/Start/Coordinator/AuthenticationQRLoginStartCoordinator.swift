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

import Combine
import CommonKit
import SwiftUI

struct AuthenticationQRLoginStartCoordinatorParameters {
    let navigationRouter: NavigationRouterType
    let qrLoginService: QRLoginServiceProtocol
}

enum AuthenticationQRLoginStartCoordinatorResult {
    /// Login with QR done
    case done(session: MXSession, securityCompleted: Bool)
}

final class AuthenticationQRLoginStartCoordinator: Coordinator, Presentable {
    // MARK: - Properties
    
    // MARK: Private

    private let parameters: AuthenticationQRLoginStartCoordinatorParameters
    private let onboardingQRLoginStartHostingController: VectorHostingController
    private var onboardingQRLoginStartViewModel: AuthenticationQRLoginStartViewModelProtocol
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?
    private var cancellables = Set<AnyCancellable>()

    private var navigationRouter: NavigationRouterType { parameters.navigationRouter }
    private var qrLoginService: QRLoginServiceProtocol { parameters.qrLoginService }
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var callback: ((AuthenticationQRLoginStartCoordinatorResult) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: AuthenticationQRLoginStartCoordinatorParameters) {
        self.parameters = parameters
        let viewModel = AuthenticationQRLoginStartViewModel(qrLoginService: parameters.qrLoginService)
        let view = AuthenticationQRLoginStartScreen(context: viewModel.context)
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

        qrLoginService.callbacks.sink { [weak self] callback in
            guard let self = self else { return }
            switch callback {
            case .didUpdateState:
                self.processServiceState(self.qrLoginService.state)
            default:
                break
            }
        }
        .store(in: &cancellables)
    }
    
    func toPresentable() -> UIViewController {
        onboardingQRLoginStartHostingController
    }
    
    /// Stops any ongoing activities in the coordinator.
    func stop() {
        stopLoading()
    }
    
    // MARK: - Private

    private func processServiceState(_ state: QRLoginServiceState) {
        switch state {
        case .initial:
            removeAllChildren()
        case .connectingToDevice, .waitingForRemoteSignIn:
            showLoadingScreenIfNeeded()
        case .waitingForConfirmation:
            showConfirmationScreenIfNeeded()
        case .failed(let error):
            switch error {
            case .noCameraAccess, .noCameraAvailable:
                break // handled in scanning screen
            default:
                showFailureScreenIfNeeded()
            }
        case .completed(let session, let securityCompleted):
            guard let session = session as? MXSession else {
                showFailureScreenIfNeeded()
                return
            }
            callback?(.done(session: session, securityCompleted: securityCompleted))
        default:
            break
        }
    }

    private func removeAllChildren(animated: Bool = true) {
        MXLog.debug("[AuthenticationQRLoginStartCoordinator] removeAllChildren")

        guard !childCoordinators.isEmpty else {
            return
        }

        for coordinator in childCoordinators.reversed() {
            remove(childCoordinator: coordinator)
        }

        navigationRouter.popToModule(self, animated: animated)
    }

    /// Shows the scan QR screen.
    private func showScanQRScreen() {
        MXLog.debug("[AuthenticationQRLoginStartCoordinator] showScanQRScreen")

        let parameters = AuthenticationQRLoginScanCoordinatorParameters(navigationRouter: navigationRouter,
                                                                        qrLoginService: qrLoginService)
        let coordinator = AuthenticationQRLoginScanCoordinator(parameters: parameters)
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

    /// Shows the display QR screen.
    private func showDisplayQRScreen() {
        MXLog.debug("[AuthenticationQRLoginStartCoordinator] showDisplayQRScreen")
        
        removeAllChildren(animated: false)

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

    /// Shows the loading screen.
    private func showLoadingScreenIfNeeded() {
        MXLog.debug("[AuthenticationQRLoginStartCoordinator] showLoadingScreenIfNeeded")
        
        removeAllChildren(animated: false)

        if let lastCoordinator = childCoordinators.last,
           lastCoordinator is AuthenticationQRLoginLoadingCoordinator {
            // if the last screen is loading, do nothing. It'll be updated by the service state.
            return
        }

        let parameters = AuthenticationQRLoginLoadingCoordinatorParameters(navigationRouter: navigationRouter,
                                                                           qrLoginService: qrLoginService)
        let coordinator = AuthenticationQRLoginLoadingCoordinator(parameters: parameters)
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

    /// Shows the confirmation screen.
    private func showConfirmationScreenIfNeeded() {
        MXLog.debug("[AuthenticationQRLoginStartCoordinator] showConfirmationScreenIfNeeded")
        
        removeAllChildren(animated: false)

        if let lastCoordinator = childCoordinators.last,
           lastCoordinator is AuthenticationQRLoginConfirmCoordinator {
            // if the last screen is confirmation, do nothing. It'll be updated by the service state.
            return
        }

        let parameters = AuthenticationQRLoginConfirmCoordinatorParameters(navigationRouter: navigationRouter,
                                                                           qrLoginService: qrLoginService)
        let coordinator = AuthenticationQRLoginConfirmCoordinator(parameters: parameters)
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

    /// Shows the failure screen.
    private func showFailureScreenIfNeeded() {
        MXLog.debug("[AuthenticationQRLoginStartCoordinator] showFailureScreenIfNeeded")
        
        removeAllChildren(animated: false)

        if let lastCoordinator = childCoordinators.last,
           lastCoordinator is AuthenticationQRLoginFailureCoordinator {
            // if the last screen is failure, do nothing. It'll be updated by the service state.
            return
        }

        let parameters = AuthenticationQRLoginFailureCoordinatorParameters(navigationRouter: navigationRouter,
                                                                           qrLoginService: qrLoginService)
        let coordinator = AuthenticationQRLoginFailureCoordinator(parameters: parameters)
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
