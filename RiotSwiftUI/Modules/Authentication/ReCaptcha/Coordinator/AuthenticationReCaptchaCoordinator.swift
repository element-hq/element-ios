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

struct AuthenticationReCaptchaCoordinatorParameters {
    let authenticationService: AuthenticationService
    let registrationWizard: RegistrationWizard
    /// The ReCaptcha widget's site key.
    let siteKey: String
}

enum AuthenticationReCaptchaCoordinatorResult {
    /// The screen completed with the associated registration result.
    case completed(RegistrationResult)
    /// The user would like to cancel the registration.
    case cancel
}

final class AuthenticationReCaptchaCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: AuthenticationReCaptchaCoordinatorParameters
    private let authenticationReCaptchaHostingController: UIViewController
    private var authenticationReCaptchaViewModel: AuthenticationReCaptchaViewModelProtocol
    
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
    @MainActor var callback: ((AuthenticationReCaptchaCoordinatorResult) -> Void)?
    
    // MARK: - Setup
    
    @MainActor init(parameters: AuthenticationReCaptchaCoordinatorParameters) {
        self.parameters = parameters
        
        guard let homeserverURL = URL(string: parameters.authenticationService.state.homeserver.address) else {
            fatalError()
        }
        
        let viewModel = AuthenticationReCaptchaViewModel(siteKey: parameters.siteKey, homeserverURL: homeserverURL)
        let view = AuthenticationReCaptchaScreen(viewModel: viewModel.context)
        authenticationReCaptchaViewModel = viewModel
        authenticationReCaptchaHostingController = VectorHostingController(rootView: view)
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: authenticationReCaptchaHostingController)
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[AuthenticationReCaptchaCoordinator] did start.")
        Task { await setupViewModel() }
    }
    
    func toPresentable() -> UIViewController {
        return self.authenticationReCaptchaHostingController
    }
    
    // MARK: - Private
    
    /// Set up the view model. This method is extracted from `start()` so it can run on the `MainActor`.
    @MainActor private func setupViewModel() {
        authenticationReCaptchaViewModel.callback = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[AuthenticationReCaptchaCoordinator] AuthenticationReCaptchaViewModel did complete with result: \(result).")
            
            switch result {
            case .validate(let response):
                self.performReCaptcha(response)
            case .cancel:
                #warning("Reset the flow")
            }
        }
    }
    
    /// Show an activity indicator whilst loading.
    /// - Parameters:
    ///   - label: The label to show on the indicator.
    ///   - isInteractionBlocking: Whether the indicator should block any user interaction.
    @MainActor private func startLoading(label: String = VectorL10n.loading, isInteractionBlocking: Bool = true) {
        loadingIndicator = indicatorPresenter.present(.loading(label: label, isInteractionBlocking: isInteractionBlocking))
    }
    
    /// Hide the currently displayed activity indicator.
    @MainActor private func stopLoading() {
        loadingIndicator = nil
    }
    
    /// Performs the ReCaptcha stage with the supplied response string.
    @MainActor private func performReCaptcha(_ response: String) {
        startLoading()
        
        currentTask = Task { [weak self] in
            do {
                let result = try await registrationWizard.performReCaptcha(response: response)
                
                guard !Task.isCancelled else { return }
                
                callback?(.completed(result))
                self?.stopLoading()
            } catch {
                self?.stopLoading()
            }
        }
    }
}
