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

struct AuthenticationServerSelectionCoordinatorParameters {
    let authenticationService: AuthenticationService
    /// Whether the server selection is for the login flow or registration flow.
    let flow: AuthenticationFlow
    /// Whether the screen is presented modally or within a navigation stack.
    let hasModalPresentation: Bool
}

enum AuthenticationServerSelectionCoordinatorResult {
    case updated
    case dismiss
}

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
    var callback: (@MainActor (AuthenticationServerSelectionCoordinatorResult) -> Void)?
    
    // MARK: - Setup
    
    @MainActor init(parameters: AuthenticationServerSelectionCoordinatorParameters) {
        self.parameters = parameters
        
        let homeserver = parameters.authenticationService.state.homeserver
        let viewModel = AuthenticationServerSelectionViewModel(homeserverAddress: homeserver.displayableAddress,
                                                               flow: parameters.authenticationService.state.flow,
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
        MXLog.debug("[AuthenticationServerSelectionCoordinator] did start.")
        Task { await setupViewModel() }
    }
    
    func toPresentable() -> UIViewController {
        authenticationServerSelectionHostingController
    }
    
    // MARK: - Private
    
    /// Set up the view model. This method is extracted from `start()` so it can run on the `MainActor`.
    @MainActor private func setupViewModel() {
        authenticationServerSelectionViewModel.callback = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[AuthenticationServerSelectionCoordinator] AuthenticationServerSelectionViewModel did complete with result: \(result).")
            
            switch result {
            case .confirm(let homeserverAddress):
                self.useHomeserver(homeserverAddress)
            case .dismiss:
                self.callback?(.dismiss)
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
    
    /// Updates the login flow using the supplied homeserver address, or shows an error when this isn't possible.
    @MainActor private func useHomeserver(_ homeserverAddress: String) {
        startLoading()
        
        let homeserverAddress = HomeserverAddress.sanitized(homeserverAddress)
        
        Task {
            do {
                try await authenticationService.startFlow(parameters.flow, for: homeserverAddress)
                stopLoading()
                
                callback?(.updated)
            } catch {
                stopLoading()
                
                if let error = error as? RegistrationError {
                    authenticationServerSelectionViewModel.displayError(.footerMessage(error.localizedDescription))
                } else {
                    // Show the MXError message if possible otherwise use a generic server error
                    let message = MXError(nsError: error)?.error ?? VectorL10n.authenticationServerSelectionGenericError
                    authenticationServerSelectionViewModel.displayError(.footerMessage(message))
                }
            }
        }
    }
}
