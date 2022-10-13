// 
// Copyright 2022 New Vector Ltd
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

import Foundation

@objc protocol SignOutFlowPresenterDelegate {
    /// The presenter is starting an operation that might take while and the UI should indicate this.
    func signOutFlowPresenterDidStartLoading(_ presenter: SignOutFlowPresenter)
    /// The presenter has finished an operation and the UI should indicate this if necessary.
    func signOutFlowPresenterDidStopLoading(_ presenter: SignOutFlowPresenter)
    /// The presenter encountered an error and has stopped.
    func signOutFlowPresenter(_ presenter: SignOutFlowPresenter, didFailWith error: Error)
}

/// This class provides a reusable component to present the sign out flow
/// for the current session, including the initial prompt, and any follow-up
/// key-backup setup that is necessary for the user.
@objcMembers class SignOutFlowPresenter: NSObject {
    private let session: MXSession
    private let presentingViewController: UIViewController
    
    private var signOutAlertPresenter = SignOutAlertPresenter()
    
    weak var delegate: SignOutFlowPresenterDelegate?
    
    init(session: MXSession, presentingViewController: UIViewController) {
        self.session = session
        self.presentingViewController = presentingViewController
        
        super.init()
        
        signOutAlertPresenter.delegate = self
    }
    
    /// Starts the flow without a specific source view. On iPad any popups
    /// will show from the presenting view controller itself.
    func start() {
        start(sourceView: presentingViewController.view)
    }
    
    /// Starts the flow, presenting any popups on iPad from the specified view.
    func start(sourceView: UIView?) {
        guard let keyBackup = session.crypto?.backup else { return }
        
        signOutAlertPresenter.present(for: keyBackup.state,
                                      areThereKeysToBackup: keyBackup.hasKeysToBackup,
                                      from: presentingViewController,
                                      sourceView: sourceView ?? presentingViewController.view,
                                      animated: true)
    }
    
    // MARK: - SecureBackupSetupCoordinatorBridgePresenter
    
    private var secureBackupSetupCoordinatorBridgePresenter: SecureBackupSetupCoordinatorBridgePresenter?
    private var crossSigningSetupCoordinatorBridgePresenter: CrossSigningSetupCoordinatorBridgePresenter?

    private func showSecureBackupSetupFromSignOutFlow() {
        if canSetupSecureBackup {
            setupSecureBackup()
        } else {
            // Set up cross-signing first
            setupCrossSigning(title: VectorL10n.secureKeyBackupSetupIntroTitle,
                              message: VectorL10n.securitySettingsUserPasswordDescription) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let isCompleted):
                    if isCompleted {
                        self.setupSecureBackup()
                    }
                case .failure(let error):
                    self.delegate?.signOutFlowPresenter(self, didFailWith: error)
                }
            }
        }
    }
    
    private var canSetupSecureBackup: Bool {
        return session.vc_canSetupSecureBackup()
    }
    
    private func setupSecureBackup() {
        let secureBackupSetupCoordinatorBridgePresenter = SecureBackupSetupCoordinatorBridgePresenter(session: session, allowOverwrite: true)
        secureBackupSetupCoordinatorBridgePresenter.delegate = self
        secureBackupSetupCoordinatorBridgePresenter.present(from: presentingViewController, animated: true)
        self.secureBackupSetupCoordinatorBridgePresenter = secureBackupSetupCoordinatorBridgePresenter
    }
    
    private func setupCrossSigning(title: String, message: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        delegate?.signOutFlowPresenterDidStartLoading(self)
        
        let dismissAnimation = { [weak self] in
            guard let self = self else { return }
            
            self.delegate?.signOutFlowPresenterDidStopLoading(self)
            self.crossSigningSetupCoordinatorBridgePresenter?.dismiss(animated: true, completion: {
                self.crossSigningSetupCoordinatorBridgePresenter = nil
            })
        }
        
        let crossSigningSetupCoordinatorBridgePresenter = CrossSigningSetupCoordinatorBridgePresenter(session: session)
        crossSigningSetupCoordinatorBridgePresenter.present(with: title, message: message, from: presentingViewController, animated: true) {
            dismissAnimation()
            completion(.success(true))
        } cancel: {
            dismissAnimation()
            completion(.success(false))
        } failure: { error in
            dismissAnimation()
            completion(.failure(error))
        }

        self.crossSigningSetupCoordinatorBridgePresenter = crossSigningSetupCoordinatorBridgePresenter
    }
}

// MARK: - SignOutAlertPresenterDelegate
extension SignOutFlowPresenter: SignOutAlertPresenterDelegate {
    
    func signOutAlertPresenterDidTapSignOutAction(_ presenter: SignOutAlertPresenter) {
        // Allow presenting screen to black user interaction when signing out
        // TODO: Prevent user interaction in all application (navigation controller and split view controller included)
        delegate?.signOutFlowPresenterDidStartLoading(self)
        
        AppDelegate.theDelegate().logout(withConfirmation: false) { [weak self] isLoggedOut in
            guard let self = self else { return }
            self.delegate?.signOutFlowPresenterDidStopLoading(self)
        }
    }
    
    func signOutAlertPresenterDidTapBackupAction(_ presenter: SignOutAlertPresenter) {
        showSecureBackupSetupFromSignOutFlow()
    }
    
}

// MARK: - SecureBackupSetupCoordinatorBridgePresenterDelegate
extension SignOutFlowPresenter: SecureBackupSetupCoordinatorBridgePresenterDelegate {
    func secureBackupSetupCoordinatorBridgePresenterDelegateDidCancel(_ coordinatorBridgePresenter: SecureBackupSetupCoordinatorBridgePresenter) {
        coordinatorBridgePresenter.dismiss(animated: true) {
            self.secureBackupSetupCoordinatorBridgePresenter = nil
        }
    }
    
    func secureBackupSetupCoordinatorBridgePresenterDelegateDidComplete(_ coordinatorBridgePresenter: SecureBackupSetupCoordinatorBridgePresenter) {
        coordinatorBridgePresenter.dismiss(animated: true) {
            self.secureBackupSetupCoordinatorBridgePresenter = nil
        }
    }
}
