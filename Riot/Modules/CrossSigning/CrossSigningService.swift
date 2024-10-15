/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

enum CrossSigningServiceError: Int, Error {
    case authenticationRequired
    case unknown
}

extension CrossSigningServiceError: CustomNSError {
    public static let errorDomain = "CrossSigningService"

    public var errorCode: Int {
        return Int(rawValue)
    }

    public var errorUserInfo: [String: Any] {
        return [:]
    }
}

@objcMembers
final class CrossSigningService: NSObject {
    
    // MARK - Properties
    
    private var supportSetupKeyVerificationByUser: [String: Bool] = [:] // Cached server response
    private var userInteractiveAuthenticationService: UserInteractiveAuthenticationService?
    
    // MARK - Public
    
    @discardableResult
    func canSetupCrossSigning(for session: MXSession, success: @escaping ((Bool) -> Void), failure: @escaping ((Error) -> Void)) -> MXHTTPOperation? {
        
        guard let crossSigning = session.crypto?.crossSigning, crossSigning.state == .notBootstrapped else {
            // Cross-signing already setup
            success(false)
            return nil
        }
        
        let userId: String = session.myUserId
        
        if let supportSetupKeyVerification = self.supportSetupKeyVerificationByUser[userId] {
            // Return cached response
            success(supportSetupKeyVerification)
            return nil
        }
        
        let userInteractiveAuthenticationService = UserInteractiveAuthenticationService(session: session)
        
        self.userInteractiveAuthenticationService = userInteractiveAuthenticationService
                
        let request = self.setupCrossSigningRequest()
        
        return userInteractiveAuthenticationService.canAuthenticate(with: request) { (result) in
            switch result {
            case .success(let succeeded):
                success(succeeded)
            case .failure(let error):
                failure(error)
            }
        }
    }
    
    func setupCrossSigningRequest() -> AuthenticatedEndpointRequest {
        let path = "\(kMXAPIPrefixPathUnstable)/keys/device_signing/upload"
        return AuthenticatedEndpointRequest(path: path, httpMethod: "POST", params: [:])
    }
    
    /// Setup cross-signing without authentication. Useful when a grace period is enabled.
    @discardableResult
    func setupCrossSigningWithoutAuthentication(for session: MXSession, success: @escaping (() -> Void), failure: @escaping ((Error) -> Void)) -> MXHTTPOperation? {
        
        guard let crossSigning = session.crypto?.crossSigning else {
            failure(CrossSigningServiceError.unknown)
            return nil
        }
        
        let userInteractiveAuthenticationService = UserInteractiveAuthenticationService(session: session)
        self.userInteractiveAuthenticationService = userInteractiveAuthenticationService
                        
        let request = self.setupCrossSigningRequest()
        
        return userInteractiveAuthenticationService.authenticatedEndpointStatus(for: request) { result in
            switch result {
            case .success(let authenticatedEnpointStatus):
                switch authenticatedEnpointStatus {
                case .authenticationNeeded:
                    failure(CrossSigningServiceError.authenticationRequired)
                case .authenticationNotNeeded:
                    crossSigning.setup(withAuthParams: [:]) {
                        success()
                    } failure: { error in
                        failure(error)
                    }
                }
            case .failure(let error):
                failure(error)
            }
        }
    }
}
