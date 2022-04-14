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

@available(iOS 14.0, *)
struct AuthenticationServerSelectionCoordinatorParameters {
    let authenticationService: AuthenticationService
    /// Whether the screen is presented modally or within a navigation stack.
    let hasModalPresentation: Bool
}

enum AuthenticationServerSelectionCoordinatorResult {
    case updated(loginFlow: LoginFlowResult, registrationResult: RegistrationResult)
    case dismiss
}

@available(iOS 14.0, *)
final class AuthenticationServerSelectionCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: AuthenticationServerSelectionCoordinatorParameters
    private let authenticationServerSelectionHostingController: VectorHostingController
    private var authenticationServerSelectionViewModel: AuthenticationServerSelectionViewModelProtocol
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?
    
    /// The authentication service that will be updated with the new selection.
    var authenticationService: AuthenticationService { parameters.authenticationService }
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    @MainActor var completion: ((AuthenticationServerSelectionCoordinatorResult) -> Void)?
    
    // MARK: - Setup
    
    @MainActor init(parameters: AuthenticationServerSelectionCoordinatorParameters) {
        self.parameters = parameters
        
        let viewModel = AuthenticationServerSelectionViewModel(homeserverAddress: parameters.authenticationService.homeserverAddress,
                                                               hasModalPresentation: parameters.hasModalPresentation)
        let view = AuthenticationServerSelectionScreen(viewModel: viewModel.context)
        authenticationServerSelectionViewModel = viewModel
        authenticationServerSelectionHostingController = VectorHostingController(rootView: view)
        authenticationServerSelectionHostingController.vc_removeBackTitle()
        authenticationServerSelectionHostingController.enableNavigationBarScrollEdgeAppearance = true
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: authenticationServerSelectionHostingController)
    }
    
    // MARK: - Public
    
    func start() {
        Task {
            await MainActor.run {
                MXLog.debug("[AuthenticationServerSelectionCoordinator] did start.")
                authenticationServerSelectionViewModel.completion = { [weak self] result in
                    guard let self = self else { return }
                    MXLog.debug("[AuthenticationServerSelectionCoordinator] AuthenticationServerSelectionViewModel did complete with result: \(result).")
                    
                    switch result {
                    case .next(let homeserverAddress):
                        self.useHomeserver(homeserverAddress)
                    case .dismiss:
                        self.completion?(.dismiss)
                    }
                }
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.authenticationServerSelectionHostingController
    }
    
    // MARK: - Private
    
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
    
    /// Updates the login flow using the supplied homeserver address, or shows an error when this isn't possible.
    @MainActor private func useHomeserver(_ homeserverAddress: String) {
        startLoading()
        authenticationService.reset()
        
        let homeserverAddress = HomeserverAddress.sanitize(homeserverAddress)
        
        Task {
            do {
                let (loginFlow, registrationResult) = try await authenticationService.refreshServer(homeserverAddress: homeserverAddress)
                stopLoading()
                
                completion?(.updated(loginFlow: loginFlow, registrationResult: registrationResult))
            } catch {
                stopLoading()
                
                // Show the MXError message if possible otherwise use a generic server error
                let message = MXError(nsError: error)?.error ?? VectorL10n.authenticationServerSelectionGenericError
                authenticationServerSelectionViewModel.displayError(.footerMessage(message))
            }
        }
    }
}
