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

struct AuthenticationForgotPasswordCoordinatorParameters {
    let navigationRouter: NavigationRouterType
    let loginWizard: LoginWizard
    /// The homeserver currently being used.
    let homeserver: AuthenticationState.Homeserver
}

enum AuthenticationForgotPasswordCoordinatorResult {
    /// Forgot password flow succeeded
    case success
    /// Forgot password flow cancelled
    case cancel
}

final class AuthenticationForgotPasswordCoordinator: Coordinator, Presentable {
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: AuthenticationForgotPasswordCoordinatorParameters
    private let authenticationForgotPasswordHostingController: VectorHostingController
    private var authenticationForgotPasswordViewModel: AuthenticationForgotPasswordViewModelProtocol
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?

    private var navigationRouter: NavigationRouterType { parameters.navigationRouter }
    /// The wizard used to handle the registration flow.
    private var loginWizard: LoginWizard { parameters.loginWizard }
    
    private var currentTask: Task<Void, Error>? {
        willSet {
            currentTask?.cancel()
        }
    }
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var callback: (@MainActor (AuthenticationForgotPasswordCoordinatorResult) -> Void)?
    
    // MARK: - Setup
    
    @MainActor init(parameters: AuthenticationForgotPasswordCoordinatorParameters) {
        self.parameters = parameters
        
        let viewModel = AuthenticationForgotPasswordViewModel(homeserver: parameters.homeserver.viewData)
        let view = AuthenticationForgotPasswordScreen(viewModel: viewModel.context)
        authenticationForgotPasswordViewModel = viewModel
        authenticationForgotPasswordHostingController = VectorHostingController(rootView: view)
        authenticationForgotPasswordHostingController.vc_removeBackTitle()
        authenticationForgotPasswordHostingController.enableNavigationBarScrollEdgeAppearance = true
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: authenticationForgotPasswordHostingController)
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[AuthenticationForgotPasswordCoordinator] did start.")
        Task { await setupViewModel() }
    }
    
    func toPresentable() -> UIViewController {
        authenticationForgotPasswordHostingController
    }
    
    // MARK: - Private
    
    /// Set up the view model. This method is extracted from `start()` so it can run on the `MainActor`.
    @MainActor private func setupViewModel() {
        authenticationForgotPasswordViewModel.callback = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[AuthenticationForgotPasswordCoordinator] AuthenticationForgotPasswordViewModel did complete with result: \(result).")
            
            switch result {
            case .send(let emailAddress):
                self.sendEmail(emailAddress)
            case .cancel:
                self.callback?(.cancel)
            case .done:
                self.showChoosePasswordScreen()
            case .goBack:
                self.authenticationForgotPasswordViewModel.goBackToEnterEmailForm()
            }
        }
    }
    
    /// Show an activity indicator whilst loading.
    @MainActor private func startLoading() {
        loadingIndicator = indicatorPresenter.present(.loading(label: VectorL10n.loading, isInteractionBlocking: true))
    }
    
    /// Hide the currently displayed activity indicator.
    @MainActor private func stopLoading() {
        loadingIndicator = nil
    }
    
    /// Sends a validation email to the supplied address and then begins polling the server.
    @MainActor private func sendEmail(_ address: String) {
        startLoading()

        currentTask = Task { [weak self] in
            do {
                try await loginWizard.resetPassword(email: address)

                // Shouldn't be reachable but just in case, continue the flow.

                guard !Task.isCancelled else { return }
                authenticationForgotPasswordViewModel.updateForSentEmail()

                self?.stopLoading()
            } catch is CancellationError {
                return
            } catch {
                self?.stopLoading()
                self?.handleError(error)
            }
        }
    }

    /// Shows the choose password screen
    @MainActor private func showChoosePasswordScreen() {
        MXLog.debug("[AuthenticationForgotPasswordCoordinator] showChoosePasswordScreen")

        let parameters = AuthenticationChoosePasswordCoordinatorParameters(loginWizard: loginWizard)
        let coordinator = AuthenticationChoosePasswordCoordinator(parameters: parameters)
        coordinator.callback = { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.callback?(.success)
            case .cancel:
                self.navigationRouter.popModule(animated: true)
            }
        }

        coordinator.start()
        add(childCoordinator: coordinator)

        navigationRouter.push(coordinator, animated: true, popCompletion: nil)
    }

    /// Processes an error to either update the flow or display it to the user.
    @MainActor private func handleError(_ error: Error) {
        if let mxError = MXError(nsError: error as NSError) {
            let message = mxError.authenticationErrorMessage()
            authenticationForgotPasswordViewModel.displayError(.mxError(message))
            return
        }
        
        // TODO: Handle another other error types as needed.
        
        authenticationForgotPasswordViewModel.displayError(.unknown)
    }
}
