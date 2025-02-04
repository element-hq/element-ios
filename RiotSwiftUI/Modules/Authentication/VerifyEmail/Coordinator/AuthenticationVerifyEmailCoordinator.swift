//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import CommonKit
import SwiftUI

struct AuthenticationVerifyEmailCoordinatorParameters {
    let registrationWizard: RegistrationWizard
    /// The homeserver that is requesting email verification.
    let homeserver: AuthenticationState.Homeserver
}

final class AuthenticationVerifyEmailCoordinator: Coordinator, Presentable {
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: AuthenticationVerifyEmailCoordinatorParameters
    private let authenticationVerifyEmailHostingController: VectorHostingController
    private var authenticationVerifyEmailViewModel: AuthenticationVerifyEmailViewModelProtocol
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?
    
    /// The wizard used to handle the registration flow.
    private var registrationWizard: RegistrationWizard { parameters.registrationWizard }
    
    private var currentTask: Task<Void, Error>? {
        willSet {
            currentTask?.cancel()
        }
    }
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var callback: (@MainActor (AuthenticationRegistrationStageResult) -> Void)?
    
    // MARK: - Setup
    
    @MainActor init(parameters: AuthenticationVerifyEmailCoordinatorParameters) {
        self.parameters = parameters
        
        let viewModel = AuthenticationVerifyEmailViewModel(homeserver: parameters.homeserver.viewData)
        let view = AuthenticationVerifyEmailScreen(viewModel: viewModel.context)
        authenticationVerifyEmailViewModel = viewModel
        authenticationVerifyEmailHostingController = VectorHostingController(rootView: view)
        authenticationVerifyEmailHostingController.vc_removeBackTitle()
        authenticationVerifyEmailHostingController.enableNavigationBarScrollEdgeAppearance = true
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: authenticationVerifyEmailHostingController)
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[AuthenticationVerifyEmailCoordinator] did start.")
        Task { await setupViewModel() }
    }
    
    func toPresentable() -> UIViewController {
        authenticationVerifyEmailHostingController
    }
    
    // MARK: - Private
    
    /// Set up the view model. This method is extracted from `start()` so it can run on the `MainActor`.
    @MainActor private func setupViewModel() {
        authenticationVerifyEmailViewModel.callback = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[AuthenticationVerifyEmailCoordinator] AuthenticationVerifyEmailViewModel did complete with result: \(result).")
            
            switch result {
            case .send(let emailAddress):
                self.sendEmail(emailAddress)
            case .resend:
                self.resendEmail()
            case .cancel:
                self.callback?(.cancel)
            case .goBack:
                self.authenticationVerifyEmailViewModel.goBackToEnterEmailForm()
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
        let threePID = RegisterThreePID.email(address.trimmingCharacters(in: .whitespaces))
        
        startLoading()
        
        currentTask = Task { [weak self] in
            do {
                let result = try await registrationWizard.addThreePID(threePID: threePID)
                
                // Shouldn't be reachable but just in case, continue the flow.
                
                guard !Task.isCancelled else { return }
                
                self?.callback?(.completed(result))
                self?.stopLoading()
            } catch RegistrationError.waitingForThreePIDValidation {
                // If everything went well, begin polling the server.
                authenticationVerifyEmailViewModel.updateForSentEmail()
                self?.stopLoading()
                
                checkForEmailValidation()
            } catch is CancellationError {
                return
            } catch {
                self?.stopLoading()
                self?.handleError(error)
            }
        }
    }
    
    /// Resends an email to the previously entered address and then resumes polling the server.
    @MainActor private func resendEmail() {
        startLoading()
        
        currentTask = Task { [weak self] in
            do {
                let result = try await registrationWizard.sendAgainThreePID()
                
                // Shouldn't be reachable but just in case, continue the flow.
                
                guard !Task.isCancelled else { return }
                
                self?.callback?(.completed(result))
                self?.stopLoading()
            } catch RegistrationError.waitingForThreePIDValidation {
                // Resume polling the server.
                self?.stopLoading()
                checkForEmailValidation()
            } catch is CancellationError {
                return
            } catch {
                self?.stopLoading()
                self?.handleError(error)
            }
        }
    }
    
    @MainActor private func checkForEmailValidation() {
        currentTask = Task { [weak self] in
            do {
                MXLog.debug("[AuthenticationVerifyEmailCoordinator] checkForEmailValidation: Sleeping for 3 seconds.")
                
                try await Task.sleep(nanoseconds: 3_000_000_000)
                let result = try await registrationWizard.checkIfEmailHasBeenValidated()
                
                guard !Task.isCancelled else { return }
                
                self?.callback?(.completed(result))
            } catch RegistrationError.waitingForThreePIDValidation {
                // Check again, creating a poll on the server.
                checkForEmailValidation()
            } catch is CancellationError {
                return
            } catch {
                self?.handleError(error)
            }
        }
    }
    
    /// Processes an error to either update the flow or display it to the user.
    @MainActor private func handleError(_ error: Error) {
        if let mxError = MXError(nsError: error as NSError) {
            let message = mxError.authenticationErrorMessage()
            authenticationVerifyEmailViewModel.displayError(.mxError(message))
            return
        }
        
        // TODO: Handle another other error types as needed.
        
        authenticationVerifyEmailViewModel.displayError(.unknown)
    }
}
