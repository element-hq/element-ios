// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

@objc protocol DeactivateAccountServiceDelegate: AnyObject {
    /// The service encountered an error.
    /// - Parameter error: The error that occurred.
    func deactivateAccountServiceDidEncounterError(_ error: Error)
    
    /// The service successfully completed the account deactivation.
    func deactivateAccountServiceDidCompleteDeactivation()
}

/// The kind of authentication needed to deactivate an account.
@objc enum DeactivateAccountAuthentication: Int {
    /// The deactivation endpoint is already authenticated. This is unlikely to be the case.
    case authenticated
    /// The deactivation endpoint requires a password for authentication.
    case requiresPassword
    /// The deactivation endpoint requires fallback for authentication.
    case requiresFallback
}

/// An error that occurred in the `DeactivateAccountService`
enum DeactivateAccountServiceError: Error {
    /// The next stage in the flow wasn't found.
    case missingStage
    /// The URL needed to present fallback authentication wasn't found.
    case missingFallbackURL
}

/// A service that helps handle interactive authentication when deactivating an account.
@objcMembers class DeactivateAccountService: NSObject {
    private let session: MXSession
    private let uiaService: UserInteractiveAuthenticationService
    private let request = AuthenticatedEndpointRequest(path: "\(kMXAPIPrefixPathR0)/account/deactivate", httpMethod: "POST", params: [:])
    
    /// The authentication session's ID if interactive authentication has begun, otherwise `nil`.
    private var sessionID: String?
    
    weak var delegate: DeactivateAccountServiceDelegate?
    
    /// Creates a new service for the supplied session.
    /// - Parameter session: The session with the account to be deactivated.
    init(session: MXSession) {
        self.session = session
        self.uiaService = UserInteractiveAuthenticationService(session: session)
    }
    
    /// Checks the authentication required for deactivation.
    /// - Parameters:
    ///   - success: A closure called containing information about the kind of authentication required (and a fallback URL if needed).
    ///   - failure: A closure called then the check failed.
    func checkAuthentication(success: @escaping (DeactivateAccountAuthentication, URL?) -> Void,
                             failure: @escaping (Error) -> Void) {
        uiaService.authenticatedEndpointStatus(for: request) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let status):
                switch status {
                case .authenticationNotNeeded:
                    success(.authenticated, nil)
                case .authenticationNeeded(let session):
                    do {
                        let (authentication, fallbackURL) = try self.handleAuthenticationSession(session)
                        success(authentication, fallbackURL)
                    } catch {
                        failure(error)
                    }
                }
            case .failure(let error):
                failure(error)
            }
        }
    }
    
    /// Extracts the authentication information out of an `MXAuthenticationSession`.
    /// - Parameter authenticationSession: The authentication session to be used.
    /// - Returns: A tuple containing the required authentication method along with a URL for fallback if necessary.
    private func handleAuthenticationSession(_ authenticationSession: MXAuthenticationSession) throws -> (DeactivateAccountAuthentication, URL?) {
        guard let nextStage = uiaService.firstUncompletedFlowIdentifier(in: authenticationSession) else {
            MXLog.error("[DeactivateAccountService] handleAuthenticationSession: Failed to determine the next stage.")
            throw DeactivateAccountServiceError.missingStage
        }
        
        switch nextStage {
        case kMXLoginFlowTypePassword:
            sessionID = authenticationSession.session
            return (.requiresPassword, nil)
        default:
            guard let fallbackURL = uiaService.firstUncompletedStageAuthenticationFallbackURL(for: authenticationSession) else {
                MXLog.error("[DeactivateAccountService] handleAuthenticationSession: Failed to determine fallback URL.")
                throw DeactivateAccountServiceError.missingFallbackURL
            }
            sessionID = authenticationSession.session
            return (.requiresFallback, fallbackURL)
        }
        
    }
    
    /// Deactivates the account with the supplied password.
    /// - Parameters:
    ///   - password: The password for the account.
    ///   - eraseAccount: Whether or not to erase all of the data from the account too.
    func deactivate(with password: String, eraseAccount: Bool) {
        do {
            let parameters = try DeactivateAccountPasswordParameters(user: session.myUserId, password: password).dictionary()
            deactivateAccount(parameters: parameters, eraseAccount: eraseAccount)
        } catch {
            self.delegate?.deactivateAccountServiceDidEncounterError(error)
        }
    }
    
    /// Deactivates the account when authentication has already been completed.
    /// - Parameter eraseAccount: Whether or not to erase all of the data from the account too.
    func deactivate(eraseAccount: Bool) {
        do {
            let parameters = try DeactivateAccountDummyParameters(user: session.myUserId, session: sessionID ?? "").dictionary()
            deactivateAccount(parameters: parameters, eraseAccount: eraseAccount)
        } catch {
            self.delegate?.deactivateAccountServiceDidEncounterError(error)
        }
    }
    
    
    /// Deactivated the account using the specified parameters.
    /// - Parameters:
    ///   - parameters: The parameters for account deactivation.
    ///   - eraseAccount: Whether or not to erase all of the data from the account too.
    private func deactivateAccount(parameters: [String: Any], eraseAccount: Bool) {
        session.deactivateAccount(withAuthParameters: parameters, eraseAccount: eraseAccount) { [weak self] response in
            switch response {
            case .success:
                self?.delegate?.deactivateAccountServiceDidCompleteDeactivation()
            case .failure(let error):
                self?.delegate?.deactivateAccountServiceDidEncounterError(error)
            }
        }
    }
}
