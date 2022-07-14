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
import SafariServices

struct AuthenticationTermsCoordinatorParameters {
    let registrationWizard: RegistrationWizard
    /// The policies to be accepted by the user.
    let localizedPolicies: [MXLoginPolicyData]
    /// The homeserver that provided the policies.
    let homeserver: AuthenticationState.Homeserver
}

final class AuthenticationTermsCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: AuthenticationTermsCoordinatorParameters
    private let authenticationTermsHostingController: VectorHostingController
    private var authenticationTermsViewModel: AuthenticationTermsViewModelProtocol
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?
    
    /// The wizard used to handle the registration flow.
    var registrationWizard: RegistrationWizard { parameters.registrationWizard }
    
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
    
    @MainActor init(parameters: AuthenticationTermsCoordinatorParameters) {
        self.parameters = parameters
        
        let subtitle = parameters.homeserver.displayableAddress
        let policies = parameters.localizedPolicies.compactMap { AuthenticationTermsPolicy(url: $0.url, title: $0.name, subtitle: subtitle) }
        
        let viewModel = AuthenticationTermsViewModel(homeserver: parameters.homeserver.viewData, policies: policies)
        let view = AuthenticationTermsScreen(viewModel: viewModel.context)
        authenticationTermsViewModel = viewModel
        authenticationTermsHostingController = VectorHostingController(rootView: view)
        authenticationTermsHostingController.vc_removeBackTitle()
        authenticationTermsHostingController.enableNavigationBarScrollEdgeAppearance = true
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: authenticationTermsHostingController)
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[AuthenticationTermsCoordinator] did start.")
        Task { await setupViewModel() }
    }
    
    func toPresentable() -> UIViewController {
        return self.authenticationTermsHostingController
    }
    
    // MARK: - Private
    
    /// Set up the view model. This method is extracted from `start()` so it can run on the `MainActor`.
    @MainActor private func setupViewModel() {
        authenticationTermsViewModel.callback = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[AuthenticationTermsCoordinator] AuthenticationTermsViewModel did complete with result: \(result).")
            
            switch result {
            case .next:
                self.acceptTerms()
            case .showPolicy(let policy):
                self.show(policy)
            case .cancel:
                self.callback?(.cancel)
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
    
    /// Accept all of the policies and continue.
    @MainActor private func acceptTerms() {
        startLoading()
        
        currentTask = Task { [weak self] in
            do {
                let result = try await registrationWizard.acceptTerms()
                
                guard !Task.isCancelled else { return }
                callback?(.completed(result))
                
                self?.stopLoading()
            } catch {
                handleError(error)
                self?.stopLoading()
            }
        }
    }
    
    /// Present the policy page in a modal.
    @MainActor private func show(_ policy: AuthenticationTermsPolicy) {
        guard let url = URL(string: policy.url) else {
            authenticationTermsViewModel.displayError(.invalidPolicyURL)
            return
        }
        
        let safariViewController = SFSafariViewController(url: url)
        safariViewController.modalPresentationStyle = .pageSheet
        
        toPresentable().present(safariViewController, animated: true)
    }
    
    /// Processes an error to either update the flow or display it to the user.
    @MainActor private func handleError(_ error: Error) {
        if let mxError = MXError(nsError: error as NSError) {
            authenticationTermsViewModel.displayError(.mxError(mxError.error))
            return
        }
        
        // TODO: Handle any other error types as needed.
        
        authenticationTermsViewModel.displayError(.unknown)
    }
}
