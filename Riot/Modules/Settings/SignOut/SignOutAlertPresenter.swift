/*
 Copyright 2019 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import UIKit

@objc protocol SignOutAlertPresenterDelegate: AnyObject {
    func signOutAlertPresenterDidTapSignOutAction(_ presenter: SignOutAlertPresenter)
    func signOutAlertPresenterDidTapBackupAction(_ presenter: SignOutAlertPresenter)
}

@objcMembers
final class SignOutAlertPresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private weak var presentingViewController: UIViewController?
    private weak var sourceView: UIView?
    
    // MARK: Public
    
    weak var delegate: SignOutAlertPresenterDelegate?
    
    // MARK: - Public
    
    func present(for keyBackupState: MXKeyBackupState,
                 areThereKeysToBackup: Bool,
                 from viewController: UIViewController,
                 sourceView: UIView?,
                 animated: Bool) {
        self.sourceView = sourceView
        self.presentingViewController = viewController
        
        guard areThereKeysToBackup else {
            // If there is no keys to backup do not mention key backup and present same alert as if we had an existing backup.
            self.presentExistingBackupAlert(animated: animated)
            return
        }
                
        switch keyBackupState {
        case MXKeyBackupStateUnknown, MXKeyBackupStateDisabled, MXKeyBackupStateCheckingBackUpOnHomeserver:
            self.presentNonExistingBackupAlert(animated: animated)
        case MXKeyBackupStateWillBackUp, MXKeyBackupStateBackingUp:
            self.presentBackupInProgressAlert(animated: animated)
        default:
            self.presentExistingBackupAlert(animated: animated)
        }
    }
    
    // MARK: - Private
    
    private func presentExistingBackupAlert(animated: Bool) {
        let alertController = UIAlertController(title: VectorL10n.signOutExistingKeyBackupAlertTitle,
                                               message: nil,
                                               preferredStyle: .actionSheet)
        
        let signoutAction = UIAlertAction(title: VectorL10n.signOutExistingKeyBackupAlertSignOutAction, style: .destructive) { (_) in
            self.delegate?.signOutAlertPresenterDidTapSignOutAction(self)
        }
        
        let cancelAction = UIAlertAction(title: VectorL10n.cancel, style: .cancel)
        
        alertController.addAction(signoutAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController: alertController, animated: animated)
    }
    
    private func presentNonExistingBackupAlert(animated: Bool) {
        let alertController = UIAlertController(title: VectorL10n.signOutNonExistingKeyBackupAlertTitle,
                                               message: nil,
                                               preferredStyle: .actionSheet)
        
        let doNotWantKeyBackupAction = UIAlertAction(title: VectorL10n.signOutNonExistingKeyBackupAlertDiscardKeyBackupAction, style: .destructive) { (_) in
            self.presentNonExistingBackupSignOutConfirmationAlert(animated: true)
        }
        
        let setUpKeyBackupAction = UIAlertAction(title: VectorL10n.signOutNonExistingKeyBackupAlertSetupSecureBackupAction, style: .default) { (_) in
            self.delegate?.signOutAlertPresenterDidTapBackupAction(self)
        }
        
        let cancelAction = UIAlertAction(title: VectorL10n.cancel, style: .cancel)
        
        alertController.addAction(doNotWantKeyBackupAction)
        alertController.addAction(setUpKeyBackupAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController: alertController, animated: animated)
    }
    
    private func presentNonExistingBackupSignOutConfirmationAlert(animated: Bool) {
        let alertController = UIAlertController(title: VectorL10n.signOutNonExistingKeyBackupSignOutConfirmationAlertTitle,
                                               message: VectorL10n.signOutNonExistingKeyBackupSignOutConfirmationAlertMessage,
                                               preferredStyle: .alert)
        
        let signOutAction = UIAlertAction(title: VectorL10n.signOutNonExistingKeyBackupSignOutConfirmationAlertSignOutAction, style: .destructive) { (_) in
            self.delegate?.signOutAlertPresenterDidTapSignOutAction(self)
        }
        
        let setUpKeyBackupAction = UIAlertAction(title: VectorL10n.signOutNonExistingKeyBackupSignOutConfirmationAlertBackupAction, style: .default) { (_) in
            self.delegate?.signOutAlertPresenterDidTapBackupAction(self)
        }
        
        alertController.addAction(signOutAction)
        alertController.addAction(setUpKeyBackupAction)
        
        self.present(alertController: alertController, animated: animated)
    }
    
    private func presentBackupInProgressAlert(animated: Bool) {
        let alertController = UIAlertController(title: VectorL10n.signOutKeyBackupInProgressAlertTitle,
                                               message: nil,
                                               preferredStyle: .actionSheet)
        
        let discardKeyBackupAction = UIAlertAction(title: VectorL10n.signOutKeyBackupInProgressAlertDiscardKeyBackupAction, style: .destructive) { (_) in
            self.delegate?.signOutAlertPresenterDidTapSignOutAction(self)
        }
        
        let cancelAction = UIAlertAction(title: VectorL10n.signOutKeyBackupInProgressAlertCancelAction, style: .cancel)
        
        alertController.addAction(discardKeyBackupAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController: alertController, animated: animated)
    }
    
    private func present(alertController: UIAlertController, animated: Bool) {
        
        // Configure source view when alert controller is presented with a popover
        if let sourceView = self.sourceView, let popoverPresentationController = alertController.popoverPresentationController {
            popoverPresentationController.sourceView = sourceView
            popoverPresentationController.sourceRect = sourceView.bounds
            popoverPresentationController.permittedArrowDirections = [.down, .up]
        }
        
        self.presentingViewController?.present(alertController, animated: animated, completion: nil)
    }
}
