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

enum AuthenticatedSessionViewControllerFactoryError: Int, Error, CustomNSError {
    case flowNotSupported = 0
    
    // MARK: - CustomNSError
    
    static let errorDomain = "AuthenticatedSessionViewControllerFactoryErrorDomain"
    
    var errorCode: Int { return self.rawValue }
    
    var errorUserInfo: [String: Any] {
        let userInfo: [String: Any]

        switch self {
        case .flowNotSupported:
            userInfo = [NSLocalizedDescriptionKey: VectorL10n.authenticatedSessionFlowNotSupported]
        }
        return userInfo
    }
}

/// This class creates view controllers that can handle an authentication flow for given requests.
@objcMembers
final class AuthenticatedSessionViewControllerFactory: NSObject {
    
    // MARK: - Constants
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    
    
    // MARK: Public
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.session = session
    }
    
    
    // MARK: - Public methods
    
    /// Create a view controller to handle an authentication flow for a given request.
    ///
    /// - Parameters:
    ///   - path: the request path.
    ///   - httpMethod: the request http method.
    ///   - title: the title to use in the view controller.
    ///   - message: the information to display in the view controller.
    ///   - onViewController: the block called when the view controller is ready. The caller must display it.
    ///   - onAuthenticated: the block called when the user finished to enter their credentials.
    ///   - onCancelled: the block called when the user cancelled the authentication.
    ///   - onFailure: the blocked called on error.
    @discardableResult
    func viewController(forPath path: String,
                        httpMethod: String,
                        title: String?,
                        message: String?,
                        onViewController: @escaping (UIViewController) -> Void,
                        onAuthenticated: @escaping ([String: Any]) -> Void,
                        onCancelled: @escaping () -> Void,
                        onFailure: @escaping (Error) -> Void) -> MXHTTPOperation {
        
        // Get the authentication flow required for this API
        return session.matrixRestClient.authSessionForRequest(withMethod: httpMethod, path: path, parameters: [:], success: { [weak self] (authenticationSession) in
            guard let self = self else {
                return
            }
            
            guard let authenticationSession = authenticationSession, let flows = authenticationSession.flows else {
                onFailure(AuthenticatedSessionViewControllerFactoryError.flowNotSupported)
                return
            }
            
            // Return the corresponding VC
            if self.hasPasswordFlow(inFlows: flows) {
                let authViewController = self.createPasswordViewController(title: title,
                                                                           message: message,
                                                                           authenticationSession: authenticationSession,
                                                                           onAuthenticated: onAuthenticated,
                                                                           onCancelled: onCancelled,
                                                                           onFailure: onFailure)
                onViewController(authViewController)
            } else {
                // Flow not supported yet
                onFailure(AuthenticatedSessionViewControllerFactoryError.flowNotSupported)
            }
            
        }, failure: { (error) in
            guard let error = error else {
                return
            }
            
            onFailure(error)
        })
    }
    
    /// Check if we support the authentication flow for a given request.
    ///
    /// - Parameters:
    ///   - path: the request path.
    ///   - httpMethod: the request http method.
    ///   - onCancelled: the block called when the user cancelled the authentication.
    ///   - onFailure: the blocked called on error.
    func hasSupport(forPath path: String,
                    httpMethod: String,
                    success: @escaping (Bool) -> Void,
                    failure: @escaping (Error) -> Void) -> MXHTTPOperation {
        
        // Get the authentication flow required for this API
        return session.matrixRestClient.authSessionForRequest(withMethod: httpMethod, path: path, parameters: [:], success: { [weak self] (authenticationSession) in
            guard let self = self else {
                return
            }
            
            guard let authenticationSession = authenticationSession, let flows = authenticationSession.flows else {
                success(false)
                return
            }
            
            // Return the corresponding VC
            if self.hasPasswordFlow(inFlows: flows) {
                success(true)
            } else {
                // Flow not supported yet
                success(false)
            }
            
            }, failure: { (error) in
                guard let error = error else {
                    return
                }
                
                failure(error)
        })
    }
    
    
    // MARK: - Private methods
    
    // MARK: - Password flow
    
    private func hasPasswordFlow(inFlows flows: [MXLoginFlow]) -> Bool {
        for flow in flows {
            if flow.type == kMXLoginFlowTypePassword || flow.stages.contains(kMXLoginFlowTypePassword) {
                return true
            }
        }
        
        return false
    }
    
    private func createPasswordViewController(
                        title: String?,
                        message: String?,
                        authenticationSession: MXAuthenticationSession,
                        onAuthenticated: @escaping ([String: Any]) -> Void,
                        onCancelled: @escaping () -> Void,
                        onFailure: @escaping (Error) -> Void) -> UIViewController {
        
        // Use a simple UIAlertController as before
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertController.addTextField { (textField) in
            textField.isSecureTextEntry = true
            textField.placeholder = VectorL10n.authPasswordPlaceholder
            textField.keyboardType = .default
        }
        
        alertController.addAction(UIAlertAction(title: Bundle.mxk_localizedString(forKey: "cancel"), style: .cancel, handler: { _ in
            onCancelled()
        }))
        
        alertController.addAction(UIAlertAction(title: Bundle.mxk_localizedString(forKey: "ok"), style: .default, handler: { _ in
            
            guard let password = alertController.textFields?.first?.text else {
                // Should not happen
                return
            }
            
            guard let authParams = self.createAuthParams(password: password, authenticationSession: authenticationSession) else {
                onFailure(AuthenticatedSessionViewControllerFactoryError.flowNotSupported)
                return
            }
            
            onAuthenticated(authParams)
        }))
        
        return alertController
    }
    
    private func createAuthParams(password: String,
                                  authenticationSession: MXAuthenticationSession) -> [String: Any]? {
        guard let userId = self.session.myUserId, let session = authenticationSession.session  else {
            return nil
        }
            
        return [
            "type": kMXLoginFlowTypePassword,
            "session": session,
            "user": userId,
            "password": password
        ]
    }
}
