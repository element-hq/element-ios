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

struct AuthenticationVerifyEmailCoordinatorParameters {
    let authenticationService: AuthenticationService
    let registrationWizard: RegistrationWizard
}

@available(iOS 14.0, *)
final class AuthenticationVerifyEmailCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: AuthenticationVerifyEmailCoordinatorParameters
    private let authenticationVerifyEmailHostingController: VectorHostingController
    private var authenticationVerifyEmailViewModel: AuthenticationVerifyEmailViewModelProtocol
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?
    
    /// The authentication service used for the registration.
    private var authenticationService: AuthenticationService { parameters.authenticationService }
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
    @MainActor var callback: ((AuthenticationVerifyEmailViewModelResult) -> Void)?
    
    // MARK: - Setup
    
    @MainActor init(parameters: AuthenticationVerifyEmailCoordinatorParameters) {
        self.parameters = parameters
        
        let viewModel = AuthenticationVerifyEmailViewModel()
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
        return self.authenticationVerifyEmailHostingController
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
                self.resentEmail()
            case .cancel:
                #warning("Reset the flow.")
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
    
    @MainActor private func sendEmail(_ address: String) {
        let threePID = RegisterThreePID.email(address)
        
        startLoading()
        
        currentTask = Task { [weak self] in
            do {
                _ = try await registrationWizard.addThreePID(threePID: threePID)
                
                guard !Task.isCancelled else { return }
                
                authenticationVerifyEmailViewModel.updateForSentEmail()
                pollForEmailValidation()
                self?.stopLoading()
            } catch {
                self?.stopLoading()
                self?.handleError(error)
            }
        }
    }
    
    @MainActor private func resentEmail() {
        startLoading()
        
        currentTask = Task { [weak self] in
            do {
                _ = try await registrationWizard.sendAgainThreePID()
                
                guard !Task.isCancelled else { return }
                
                pollForEmailValidation()
                self?.stopLoading()
            } catch {
                self?.stopLoading()
                self?.handleError(error)
            }
        }
    }
    
    @MainActor private func pollForEmailValidation() {
        // TODO
    }
    
    /// Processes an error to either update the flow or display it to the user.
    @MainActor private func handleError(_ error: Error) {
        if let mxError = MXError(nsError: error as NSError) {
            authenticationVerifyEmailViewModel.displayError(.mxError(mxError.error))
            return
        }
        
        // TODO: Handle another other error types as needed.
        
        authenticationVerifyEmailViewModel.displayError(.unknown)
    }
}
