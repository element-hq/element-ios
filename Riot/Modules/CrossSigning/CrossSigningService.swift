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

@objcMembers
final class CrossSigningService: NSObject {
    
    private var authenticatedSessionFactory: AuthenticatedSessionViewControllerFactory?
    private var supportSetupKeyVerificationByUser: [String: Bool] = [:] // Cached server response
    
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
        
        let authenticatedSessionFactory = AuthenticatedSessionViewControllerFactory(session: session)
        
        self.authenticatedSessionFactory = authenticatedSessionFactory
        
        let path = "\(kMXAPIPrefixPathUnstable)/keys/device_signing/upload"
        
        return authenticatedSessionFactory.hasSupport(forPath: path, httpMethod: "POST", success: { [weak self] succeeded in
            guard let self = self else {
                return
            }
            self.authenticatedSessionFactory = nil
            self.supportSetupKeyVerificationByUser[userId] = succeeded
            success(succeeded)
            }, failure: { [weak self] error in
                guard let self = self else {
                    return
                }
                self.authenticatedSessionFactory = nil
                failure(error)
        })
    }
}
