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
    let promptType: AuthenticationVerifyEmailPromptType
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
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    @MainActor var completion: ((AuthenticationVerifyEmailViewModelResult) -> Void)?
    
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
        authenticationVerifyEmailViewModel.completion = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[AuthenticationVerifyEmailCoordinator] AuthenticationVerifyEmailViewModel did complete with result: \(result).")
            
            switch result {
            case .send(let emailAddress):
                break
            case .resend:
                break
            case .cancel:
                break
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.authenticationVerifyEmailHostingController
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
}
