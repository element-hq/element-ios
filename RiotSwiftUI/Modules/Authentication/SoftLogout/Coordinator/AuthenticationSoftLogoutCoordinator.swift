//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import CommonKit
import SwiftUI

struct AuthenticationSoftLogoutCoordinatorParameters {
    let navigationRouter: NavigationRouterType
    let authenticationService: AuthenticationService
    let credentials: SoftLogoutCredentials
    let keyBackupNeeded: Bool
}

enum AuthenticationSoftLogoutCoordinatorResult: CustomStringConvertible {
    /// Login was successful with the associated session created.
    case success(session: MXSession, password: String)
    /// Clear all user data
    case clearAllData
    /// Continue using the supplied SSO provider.
    case continueWithSSO(SSOIdentityProvider)
    /// Continue using the fallback page
    case fallback
    
    /// A string representation of the result, ignoring any associated values that could leak PII.
    var description: String {
        switch self {
        case .success:
            return "success"
        case .clearAllData:
            return "clearAllData"
        case .continueWithSSO(let provider):
            return "continueWithSSO: \(provider)"
        case .fallback:
            return "fallback"
        }
    }
}

final class AuthenticationSoftLogoutCoordinator: Coordinator, Presentable {
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: AuthenticationSoftLogoutCoordinatorParameters
    private let authenticationSoftLogoutHostingController: VectorHostingController
    private var authenticationSoftLogoutViewModel: AuthenticationSoftLogoutViewModelProtocol
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?
    private var successIndicator: UserIndicator?
    
    /// The wizard used to handle the registration flow.
    private var loginWizard: LoginWizard? { parameters.authenticationService.loginWizard }

    private var navigationRouter: NavigationRouterType { parameters.navigationRouter }
    
    private var currentTask: Task<Void, Error>? {
        willSet {
            currentTask?.cancel()
        }
    }
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var callback: (@MainActor (AuthenticationSoftLogoutCoordinatorResult) -> Void)?
    
    // MARK: - Setup
    
    @MainActor init(parameters: AuthenticationSoftLogoutCoordinatorParameters) {
        self.parameters = parameters

        let homeserver = parameters.authenticationService.state.homeserver
        
        let viewModel = AuthenticationSoftLogoutViewModel(credentials: parameters.credentials,
                                                          homeserver: homeserver.viewData,
                                                          keyBackupNeeded: parameters.keyBackupNeeded)
        let view = AuthenticationSoftLogoutScreen(viewModel: viewModel.context)
        authenticationSoftLogoutViewModel = viewModel
        authenticationSoftLogoutHostingController = VectorHostingController(rootView: view)
        authenticationSoftLogoutHostingController.vc_removeBackTitle()
        authenticationSoftLogoutHostingController.enableNavigationBarScrollEdgeAppearance = true
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: authenticationSoftLogoutHostingController)
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[AuthenticationSoftLogoutCoordinator] did start.")
        Task { await setupViewModel() }
    }
    
    func toPresentable() -> UIViewController {
        authenticationSoftLogoutHostingController
    }
    
    // MARK: - Private
    
    /// Set up the view model. This method is extracted from `start()` so it can run on the `MainActor`.
    @MainActor private func setupViewModel() {
        authenticationSoftLogoutViewModel.callback = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[AuthenticationSoftLogoutCoordinator] AuthenticationSoftLogoutViewModel did complete with result: \(result).")
            
            switch result {
            case .login(let password):
                self.login(withPassword: password)
            case .forgotPassword:
                self.showForgotPasswordScreen()
            case .clearAllData:
                self.callback?(.clearAllData)
            case .continueWithSSO(let provider):
                self.callback?(.continueWithSSO(provider))
            case .fallback:
                self.callback?(.fallback)
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

    /// Shows the forgot password screen.
    @MainActor private func showForgotPasswordScreen() {
        MXLog.debug("[AuthenticationSoftLogoutCoordinator] showForgotPasswordScreen")

        guard let loginWizard = loginWizard else {
            MXLog.failure("[AuthenticationSoftLogoutCoordinator] The login wizard was requested before getting the login flow.")
            return
        }

        let modalRouter = NavigationRouter()

        let parameters = AuthenticationForgotPasswordCoordinatorParameters(navigationRouter: modalRouter,
                                                                           loginWizard: loginWizard,
                                                                           homeserver: parameters.authenticationService.state.homeserver)
        let coordinator = AuthenticationForgotPasswordCoordinator(parameters: parameters)
        coordinator.callback = { [weak self, weak coordinator] result in
            guard let self = self, let coordinator = coordinator else { return }
            switch result {
            case .success:
                self.navigationRouter.dismissModule(animated: true, completion: nil)
                self.successIndicator = self.indicatorPresenter.present(.success(label: VectorL10n.done))
            case .cancel:
                self.navigationRouter.dismissModule(animated: true, completion: nil)
            }
            self.remove(childCoordinator: coordinator)
        }

        coordinator.start()
        add(childCoordinator: coordinator)

        modalRouter.setRootModule(coordinator)

        navigationRouter.present(modalRouter, animated: true)
    }
    
    /// Login with the supplied username and password.
    @MainActor private func login(withPassword password: String) {
        guard let loginWizard = loginWizard else {
            MXLog.failure("[AuthenticationSoftLogoutCoordinator] The login wizard was requested before getting the login flow.")
            return
        }

        let userId = parameters.credentials.userId
        let deviceId = parameters.credentials.deviceId
        startLoading()

        currentTask = Task { [weak self] in
            do {
                let session = try await loginWizard.login(login: userId,
                                                          password: password,
                                                          initialDeviceName: UIDevice.current.initialDisplayName,
                                                          deviceID: deviceId,
                                                          removeOtherAccounts: true)

                guard !Task.isCancelled else { return }
                callback?(.success(session: session, password: password))

                self?.stopLoading()
            } catch {
                self?.stopLoading()
                self?.handleError(error)
            }
        }
    }

    /// Processes an error to either update the flow or display it to the user.
    @MainActor private func handleError(_ error: Error) {
        if let mxError = MXError(nsError: error as NSError) {
            let message = mxError.authenticationErrorMessage()
            authenticationSoftLogoutViewModel.displayError(.mxError(message))
            return
        }
        
        // TODO: Handle another other error types as needed.
        
        authenticationSoftLogoutViewModel.displayError(.unknown)
    }
}
