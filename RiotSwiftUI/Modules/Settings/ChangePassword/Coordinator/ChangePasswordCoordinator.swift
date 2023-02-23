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

struct ChangePasswordCoordinatorParameters {
    let restClient: MXRestClient
}

final class ChangePasswordCoordinator: Coordinator, Presentable {
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: ChangePasswordCoordinatorParameters
    private let changePasswordHostingController: VectorHostingController
    private var changePasswordViewModel: ChangePasswordViewModelProtocol
    private let passwordValidator = PasswordValidator(withRules: [
        .minLength(8),
        .containUppercaseLetter,
        .containLowercaseLetter,
        .containNumber,
        .containSymbol
    ])
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?
    
    private var currentTask: Task<Void, Error>? {
        willSet {
            currentTask?.cancel()
        }
    }
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var callback: (@MainActor () -> Void)?
    
    // MARK: - Setup
    
    init(parameters: ChangePasswordCoordinatorParameters) {
        self.parameters = parameters

        let requirements = passwordValidator.description(with: VectorL10n.passwordValidationInfoHeader)
        let viewModel = ChangePasswordViewModel(passwordRequirements: requirements)
        let view = ChangePasswordScreen(viewModel: viewModel.context)
        changePasswordViewModel = viewModel
        changePasswordHostingController = VectorHostingController(rootView: view)
        changePasswordHostingController.vc_removeBackTitle()
        changePasswordHostingController.enableNavigationBarScrollEdgeAppearance = true
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: changePasswordHostingController)
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[ChangePasswordCoordinator] did start.")
        Task { await setupViewModel() }
    }
    
    func toPresentable() -> UIViewController {
        changePasswordHostingController
    }
    
    // MARK: - Private
    
    /// Set up the view model. This method is extracted from `start()` so it can run on the `MainActor`.
    @MainActor private func setupViewModel() {
        changePasswordViewModel.callback = { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .submit(let oldPassword, let newPassword, let signoutAllDevices):
                MXLog.debug("[ChangePasswordCoordinator] ChangePasswordViewModel did complete with result: submit.")
                self.changePassword(from: oldPassword, to: newPassword, signoutAllDevices: signoutAllDevices)
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
    
    /// Submits a reset password request with signing out of all devices option
    @MainActor private func changePassword(from oldPassword: String, to newPassword: String, signoutAllDevices: Bool) {
        startLoading()

        currentTask = Task { [weak self] in
            do {
                try passwordValidator.validate(password: newPassword)
                try await parameters.restClient.changePassword(from: oldPassword, to: newPassword, logoutDevices: signoutAllDevices)

                guard !Task.isCancelled else { return }

                self?.stopLoading()
                self?.callback?()
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
            changePasswordViewModel.displayError(.mxError(message))
            return
        }

        if let error = error as? PasswordValidatorError {
            changePasswordViewModel.displayError(.mxError(error.localizedDescription))
        } else {
            changePasswordViewModel.displayError(.unknown)
        }
    }
}
