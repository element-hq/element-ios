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

import SwiftUI
import CommonKit
import MatrixSDK

@available(iOS 14.0, *)
struct AuthenticationRegistrationCoordinatorParameters {
    let navigationRouter: NavigationRouterType
    let authenticationService: AuthenticationService
    /// The registration flows that are to be displayed.
    let registrationResult: RegistrationResult
    /// The login flows to allow for SSO sign up.
    let loginFlowResult: LoginFlowResult
}

enum AuthenticationRegistrationCoordinatorResult {
    /// The user would like to select another server.
    case selectServer
    /// The screen completed but there are remaining authentication steps.
    case flowResponse(FlowResult)
    /// The screen completed with a successful login.
    case sessionCreated(session: MXSession, isAccountCreated: Bool)
}

@available(iOS 14.0, *)
final class AuthenticationRegistrationCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: AuthenticationRegistrationCoordinatorParameters
    private let authenticationRegistrationHostingController: VectorHostingController
    private var authenticationRegistrationViewModel: AuthenticationRegistrationViewModelProtocol
    
    private var currentTask: Task<Void, Error>? {
        willSet {
            currentTask?.cancel()
        }
    }
    
    private var navigationRouter: NavigationRouterType { parameters.navigationRouter }
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var waitingIndicator: UserIndicator?
    
    /// The authentication service used for the registration.
    var authenticationService: AuthenticationService { parameters.authenticationService }
    /// The wizard used to handle the registration flow.
    var registrationWizard: RegistrationWizard
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    @MainActor var completion: ((AuthenticationRegistrationCoordinatorResult) -> Void)?
    
    // MARK: - Setup
    
    @MainActor init(parameters: AuthenticationRegistrationCoordinatorParameters) {
        self.parameters = parameters
        
        do {
            let registrationWizard = try parameters.authenticationService.registrationWizard()
            self.registrationWizard = registrationWizard
            
            let viewModel = AuthenticationRegistrationViewModel(homeserverAddress: registrationWizard.pendingData.homeserverAddress,
                                                                ssoIdentityProviders: parameters.loginFlowResult.ssoIdentityProviders)
            authenticationRegistrationViewModel = viewModel
            
            let view = AuthenticationRegistrationScreen(viewModel: viewModel.context)
            authenticationRegistrationHostingController = VectorHostingController(rootView: view)
            authenticationRegistrationHostingController.vc_removeBackTitle()
            authenticationRegistrationHostingController.enableNavigationBarScrollEdgeAppearance = true
        } catch {
            MXLog.failure("[AuthenticationRegistrationCoordinator] The registration wizard was requested before getting the login flow.")
            fatalError(error.localizedDescription)
        }
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: authenticationRegistrationHostingController)
    }
    
    // MARK: - Public
    func start() {
        Task {
            await MainActor.run {
                MXLog.debug("[AuthenticationRegistrationCoordinator] did start.")
                authenticationRegistrationViewModel.completion = { [weak self] result in
                    guard let self = self else { return }
                    MXLog.debug("[AuthenticationRegistrationCoordinator] AuthenticationRegistrationViewModel did complete with result: \(result).")
                    switch result {
                    case .selectServer:
                        self.presentServerSelectionScreen()
                    case.validateUsername(let username):
                        self.validateUsername(username)
                    case .createAccount(let username, let password):
                        self.createAccount(username: username, password: password)
                    }
                }
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.authenticationRegistrationHostingController
    }
    
    // MARK: - Private
    
    /// Show a blocking activity indicator whilst saving.
    @MainActor private func startLoading(label: String? = nil) {
        waitingIndicator = indicatorPresenter.present(.loading(label: label ?? VectorL10n.loading, isInteractionBlocking: true))
    }
    
    /// Hide the currently displayed activity indicator.
    @MainActor private func stopLoading() {
        waitingIndicator = nil
    }
    
    /// Asks the homeserver to check the supplied username's format and availability.
    @MainActor private func validateUsername(_ username: String) {
        currentTask = Task {
            do {
                _ = try await registrationWizard.registrationAvailable(username: username)
            } catch {
                guard !Task.isCancelled, let mxError = MXError(nsError: error as NSError) else { return }
                if mxError.errcode == kMXErrCodeStringUserInUse
                    || mxError.errcode == kMXErrCodeStringInvalidUsername
                    || mxError.errcode == kMXErrCodeStringExclusiveResource {
                    authenticationRegistrationViewModel.displayError(.usernameUnavailable(mxError.error))
                }
            }
        }
    }
    
    /// Creates an account on the homeserver with the supplied username and password.
    @MainActor private func createAccount(username: String, password: String) {
        // reAuthHelper.data = state.password
        let deviceDisplayName = UIDevice.current.isPhone ? VectorL10n.loginMobileDevice : VectorL10n.loginTabletDevice
        
        startLoading()
        
        currentTask = executeRegistrationStep { [weak self] wizard in
            defer { Task { [weak self] in await self?.stopLoading() } }
            
            do {
                return try await wizard.createAccount(username: username, password: password, initialDeviceDisplayName: deviceDisplayName)
            } catch {
                self?.handleError(error)
                throw error // Throw the error as there is nothing to return (it will be swallowed up by executeRegistrationStep).
            }
        }
    }
    
    /// Processes an error to either update the flow or display it to the user.
    @MainActor private func handleError(_ error: Error) {
        if let mxError = MXError(nsError: error as NSError) {
            authenticationRegistrationViewModel.displayError(.mxError(mxError.error))
            return
        }
        
        if let authenticationError = error as? AuthenticationError {
            switch authenticationError {
            case .invalidHomeserver:
                authenticationRegistrationViewModel.displayError(.invalidHomeserver)
            case .dictionaryError:
                authenticationRegistrationViewModel.displayError(.unknown)
            case .loginFlowNotCalled, .missingRegistrationWizard, .createAccountNotCalled:
                #warning("Reset the flow")
                break
            case .missingMXRestClient:
                #warning("Forget the soft logout session")
                break
            case .noPendingThreePID, .missingThreePIDURL, .threePIDClientFailure, .threePIDValidationFailure:
                // Shouldn't happen at this stage
                authenticationRegistrationViewModel.displayError(.unknown)
            }
            return
        }
        
        authenticationRegistrationViewModel.displayError(.unknown)
    }
    
    /// Presents the server selection screen as a modal.
    @MainActor private func presentServerSelectionScreen() {
        MXLog.debug("[AuthenticationCoordinator] showServerSelectionScreen")
        let parameters = AuthenticationServerSelectionCoordinatorParameters(authenticationService: authenticationService,
                                                                            hasModalPresentation: true)
        let coordinator = AuthenticationServerSelectionCoordinator(parameters: parameters)
        coordinator.completion = { [weak self, weak coordinator] result in
            guard let self = self, let coordinator = coordinator else { return }
            self.serverSelectionCoordinator(coordinator, didCompleteWith: result)
        }
        
        coordinator.start()
        add(childCoordinator: coordinator)
        
        let modalRouter = NavigationRouter()
        modalRouter.setRootModule(coordinator)
        
        navigationRouter.present(modalRouter, animated: true)
    }
    
    /// Handles the result from the server selection modal, dismissing it after updating the view.
    @MainActor private func serverSelectionCoordinator(_ coordinator: AuthenticationServerSelectionCoordinator,
                                                       didCompleteWith result: AuthenticationServerSelectionCoordinatorResult) {
        if case let .updated(loginFlow, registrationResult) = result {
            
            authenticationRegistrationViewModel.update(homeserverAddress: authenticationService.homeserverAddress,
                                                       ssoIdentityProviders: loginFlow.ssoIdentityProviders)
            
            do {
                registrationWizard = try authenticationService.registrationWizard()
            } catch {
                MXLog.failure("[AuthenticationRegistrationCoordinator] The registration wizard was requested before getting the login flow: \(error.localizedDescription)")
            }
        }
        
        navigationRouter.dismissModule(animated: true) { [weak self] in
            self?.remove(childCoordinator: coordinator)
        }
    }
}

@available(iOS 14, *)
extension AuthenticationRegistrationCoordinator: RegistrationFlowHandling { }
