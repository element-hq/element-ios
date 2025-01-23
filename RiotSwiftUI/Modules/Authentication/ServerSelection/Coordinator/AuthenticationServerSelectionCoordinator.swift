//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import CommonKit
import StoreKit
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
        let homeserverAddress: String
        if BuildSettings.forceHomeserverSelection, homeserver.addressFromUser == nil {
            homeserverAddress = ""
        } else {
            homeserverAddress = homeserver.displayableAddress
        }
        let viewModel = AuthenticationServerSelectionViewModel(homeserverAddress: homeserverAddress,
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
            case .downloadReplacementApp(let replacementApp):
                Task { await self.showReplacementAppStorePage(replacementApp) }
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
            } catch RegistrationError.delegatedOIDCRequiresReplacementApp where BuildSettings.replacementApp != nil {
                stopLoading()
                authenticationServerSelectionViewModel.displayError(.requiresReplacementApp)
            } catch let registrationError as RegistrationError {
                stopLoading()
                authenticationServerSelectionViewModel.displayError(.footerMessage(registrationError.localizedDescription))
            } catch {
                stopLoading()
                
                // Show the MXError message if possible otherwise use a generic server error
                let message = MXError(nsError: error)?.error ?? VectorL10n.authenticationServerSelectionGenericError
                authenticationServerSelectionViewModel.displayError(.footerMessage(message))
            }
        }
    }
    
    /// Presets the App Store page for the replacement app as a sheet.
    @MainActor private func showReplacementAppStorePage(_ replacementApp: BuildSettings.ReplacementApp) async {
        do {
            let storeViewController = SKStoreProductViewController()
            try await storeViewController.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier: replacementApp.productID])
            authenticationServerSelectionHostingController.present(storeViewController, animated: true)
        } catch {
            // Open the app store URL outside of the app as a fallback.
            MXLog.warning("Unable to open the in-app store product page: \(error)")
            await UIApplication.shared.open(replacementApp.appStoreURL)
        }
    }
}
