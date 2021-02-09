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
    private var authenticationSessionService: AuthenticationSessionService?
    
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
        
        let authenticationSessionService = AuthenticationSessionService(session: session)
        
        self.authenticationSessionService = authenticationSessionService
                
        let authenticationSessionParameters = self.setupCrossSigningAuthenticationSessionParameters()
        
        return authenticationSessionService.canAuthenticate(for: authenticationSessionParameters) { (result) in
            switch result {
            case .success(let succeeded):
                success(succeeded)
            case .failure(let error):
                failure(error)
            }
        }
    }
    
    func setupCrossSigningAuthenticationSessionParameters() -> AuthenticationSessionParameters {
        let path = "\(kMXAPIPrefixPathUnstable)/keys/device_signing/upload"
        return AuthenticationSessionParameters(path: path, httpMethod: "POST")
    }
    
    /// Setup cross-signing without authentication. Useful when a grace period is enabled.
    @discardableResult
    func setupCrossSigningWithoutAuthentication(for session: MXSession, success: @escaping (() -> Void), failure: @escaping ((Error) -> Void)) -> MXHTTPOperation? {
        
        guard let crossSigning = session.crypto.crossSigning else {
            failure(CrossSigningServiceError.unknown)
            return nil
        }
        
        let authenticationSessionService = AuthenticationSessionService(session: session)
        self.authenticationSessionService = authenticationSessionService
                        
        let authenticationSessionParameters = self.setupCrossSigningAuthenticationSessionParameters()
        
        return authenticationSessionService.authenticationSession(for: authenticationSessionParameters) { result in
            switch result {
            case .success(let authenticationSessionResult):
                switch authenticationSessionResult {
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
