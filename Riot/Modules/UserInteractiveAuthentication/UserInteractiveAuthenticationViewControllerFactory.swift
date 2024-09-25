/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */
import Foundation

/// This class creates view controllers that can handle an authentication flow for given requests.
@objcMembers
final class UserInteractiveAuthenticationViewControllerFactory: NSObject {
        
    // MARK: - Password flow
    
    /// Create a view controller to handle a password authentication.
    /// - Parameters:
    ///   - title: the title to use in the view controller.
    ///   - message: the information to display in the view controller.
    ///   - onPasswordEntered: the closure called when the enter the password.
    ///   - onCancelled: the closure called when the user cancelled the authentication.
    /// - Returns: the password authentication view controller
    func createPasswordViewController(
                        title: String?,
                        message: String?,
                        onPasswordEntered: @escaping (String) -> Void,
                        onCancelled: @escaping () -> Void) -> UIViewController {
        
        // Use a simple UIAlertController as before
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertController.addTextField { (textField) in
            textField.isSecureTextEntry = true
            textField.placeholder = VectorL10n.authPasswordPlaceholder
            textField.keyboardType = .default
        }
        
        alertController.addAction(UIAlertAction(title: VectorL10n.cancel, style: .cancel, handler: { _ in
            onCancelled()
        }))
        
        alertController.addAction(UIAlertAction(title: VectorL10n.ok, style: .default, handler: { _ in
            
            guard let password = alertController.textFields?.first?.text else {
                // Should not happen
                return
            }
            onPasswordEntered(password)
        }))
        
        return alertController
    }
}
