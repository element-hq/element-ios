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

@objc protocol SignOutAlertPresenterDelegate: class {
    func signOutAlertPresenterDidTapSignOutAction(_ presenter: SignOutAlertPresenter)
    func signOutAlertPresenterDidTapBackupAction(_ presenter: SignOutAlertPresenter)
}

@objcMembers
final class SignOutAlertPresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private weak var presentingViewController: UIViewController?
    
    // MARK: Public
    
    var isABackupExist: Bool = false
    weak var delegate: SignOutAlertPresenterDelegate?
    
    // MARK: - Public
    
    func present(from viewController: UIViewController, animated: Bool) {
        self.presentingViewController = viewController
        
        if self.isABackupExist {
            self.presentExistingBackupAlert(animated: animated)
        } else {
            self.presentNonExistingBackupAlert(animated: animated)
        }
    }
    
    // MARK: - Private
    
    private func presentExistingBackupAlert(animated: Bool) {
        let alertContoller = UIAlertController(title: VectorL10n.signOutExistingKeyBackupAlertTitle,
                                               message: nil,
                                               preferredStyle: .actionSheet)
        
        let signoutAction = UIAlertAction(title: VectorL10n.signOutExistingKeyBackupAlertSignOutAction, style: .destructive) { (_) in
            self.delegate?.signOutAlertPresenterDidTapSignOutAction(self)
        }
        
        let cancelAction = UIAlertAction(title: VectorL10n.cancel, style: .cancel, handler: nil)
        
        alertContoller.addAction(signoutAction)
        alertContoller.addAction(cancelAction)
        
        self.presentingViewController?.present(alertContoller, animated: true, completion: nil)
    }
    
    private func presentNonExistingBackupAlert(animated: Bool) {
        let alertContoller = UIAlertController(title: VectorL10n.signOutNonExistingKeyBackupAlertTitle,
                                               message: nil,
                                               preferredStyle: .actionSheet)
        
        let doNotWantKeyBackupAction = UIAlertAction(title: VectorL10n.signOutNonExistingKeyBackupAlertDiscardKeyBackupAction, style: .destructive) { (_) in
            self.presentNonExistingBackupSignOutConfirmationAlert(animated: true)
        }
        
        let setUpKeyBackupAction = UIAlertAction(title: VectorL10n.signOutNonExistingKeyBackupAlertSetupKeyBackupAction, style: .default) { (_) in
            self.delegate?.signOutAlertPresenterDidTapBackupAction(self)
        }
        
        let cancelAction = UIAlertAction(title: VectorL10n.cancel, style: .cancel, handler: nil)
        
        alertContoller.addAction(doNotWantKeyBackupAction)
        alertContoller.addAction(setUpKeyBackupAction)
        alertContoller.addAction(cancelAction)
        
        self.presentingViewController?.present(alertContoller, animated: true, completion: nil)
    }
    
    private func presentNonExistingBackupSignOutConfirmationAlert(animated: Bool) {
        let alertContoller = UIAlertController(title: VectorL10n.signOutNonExistingKeyBackupSignOutConfirmationAlertTitle,
                                               message: VectorL10n.signOutNonExistingKeyBackupSignOutConfirmationAlertMessage,
                                               preferredStyle: .alert)
        
        let signOutAction = UIAlertAction(title: VectorL10n.signOutNonExistingKeyBackupSignOutConfirmationAlertSignOutAction, style: .destructive) { (_) in
            self.delegate?.signOutAlertPresenterDidTapSignOutAction(self)
        }
        
        let setUpKeyBackupAction = UIAlertAction(title: VectorL10n.signOutNonExistingKeyBackupSignOutConfirmationAlertBackupAction, style: .default) { (_) in
            self.delegate?.signOutAlertPresenterDidTapBackupAction(self)
        }
        
        alertContoller.addAction(signOutAction)
        alertContoller.addAction(setUpKeyBackupAction)
        
        self.presentingViewController?.present(alertContoller, animated: true, completion: nil)
    }
}
