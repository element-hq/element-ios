/*
 Copyright 2020 New Vector Ltd
 
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
