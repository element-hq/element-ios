// 
// Copyright 2020 New Vector Ltd
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

/// UserInteractiveAuthenticationService errors
enum UserInteractiveAuthenticationServiceError: Int, Error {
    case flowNotSupported = 0
}

extension UserInteractiveAuthenticationServiceError: CustomNSError {
    static let errorDomain = "UserInteractiveAuthenticationServiceErrorDomain"
    
    var errorCode: Int {
        return self.rawValue
    }
    
    var errorUserInfo: [String: Any] {
        let userInfo: [String: Any]

        switch self {
        case .flowNotSupported:
            userInfo = [NSLocalizedDescriptionKey: VectorL10n.authenticatedSessionFlowNotSupported]
        }
        return userInfo
    }
}

/// AuthenticatedEndpointStatus indicates the success status after checking if an API endpoint needs authentication
enum AuthenticatedEndpointStatus {
    case authenticationNotNeeded
    case authenticationNeeded(_ authenticationSession: MXAuthenticationSession)
}

/// UserInteractiveAuthenticationService enables to check if an API endpoint needs authentication.
@objcMembers
final class UserInteractiveAuthenticationService: NSObject {
    
    // MARK: - Constants
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    
    // MARK: Public
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.session = session
        super.init()
    }
    
    // MARK: - Public
    
    /// Check if API endpoint requires authentication and get authentication session if needed
    /// - Parameters:
    ///   - request: Authenticated API endpoint request.
    ///   - completion: The closure executed the operation completes. AuthenticatedEndpointStatus indicates if authentication is needed or not.
    /// - Returns: A `MXHTTPOperation` instance.
    @discardableResult
    func authenticatedEndpointStatus(for request: AuthenticatedEndpointRequest, completion: @escaping (Result<AuthenticatedEndpointStatus, Error>) -> Void) -> MXHTTPOperation {
        
        return self.authenticationSession(with: request) { (authenticationSession) in
            
            let status: AuthenticatedEndpointStatus
            
            if let authenticationSession = authenticationSession {
                status = .authenticationNeeded(authenticationSession)
            } else {
                status = .authenticationNotNeeded
            }
            
            completion(.success(status))
        } failure: { (error) in
            completion(.failure(error))
        }
    }
    
    /// Check if API endpoint requires authentication.
    /// - Parameters:
    ///   - request: Authenticated API endpoint request.
    ///   - completion: The closure executed the operation completes.
    /// - Returns: A `MXHTTPOperation` instance.
    @discardableResult
    func canAuthenticate(with request: AuthenticatedEndpointRequest, completion: @escaping (Result<Bool, Error>) -> Void) -> MXHTTPOperation {
        
        return self.authenticatedEndpointStatus(for: request) { (result) in
            switch result {
            case .success(let authenticationSessionResult):
                let canAuthenticate: Bool
                
                switch authenticationSessionResult {
                case .authenticationNotNeeded:
                    canAuthenticate = true
                case .authenticationNeeded(let authenticationSession):
                    canAuthenticate = self.canAuthenticate(with: authenticationSession)
                }
                
                completion(.success(canAuthenticate))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Check if API endpoint requires authentication.
    /// This method is compatible with Objective-C
    /// - Parameters:
    ///   - request: Authenticated API endpoint request.
    ///   - success: The closure executed the operation succeed. Get an MXAuthenticationSession if authentication is required or nil if there is no authentication needed.
    ///   - failure: The closure executed the operation fails.
    /// - Returns: A `MXHTTPOperation` instance.
    @discardableResult
    func authenticationSession(with request: AuthenticatedEndpointRequest,
                               success: @escaping (MXAuthenticationSession?) -> Void,
                               failure: @escaping (Error) -> Void) -> MXHTTPOperation {
        // Get the authentication flow required for this API
        return self.session.matrixRestClient.authSessionForRequest(withMethod: request.httpMethod, path: request.path, parameters: request.params, success: { [weak self] (authenticationSession) in
            guard let self = self else {
                return
            }
            
            if let authenticationSession = authenticationSession {
                
                if let flows = authenticationSession.flows {
                    // Check if a supported flow exists
                    if self.isThereAKnownFlow(inFlows: flows) {
                        success(authenticationSession)
                    } else if self.firstUncompletedStageAuthenticationFallbackURL(for: authenticationSession) != nil {
                        success(authenticationSession)
                    } else {
                        // Flow not supported
                        failure(UserInteractiveAuthenticationServiceError.flowNotSupported)
                    }
                }
            } else {
                // No need to authenticate
                success(nil)
            }
        }, failure: { (error) in
            guard let error = error else {
                return
            }
            failure(error)
        })
    }
    
    /// Check if a request error ask for User-Interactive Authentication.
    /// - Parameter error: A request error.
    /// - Returns: An AuthenticatedEndpointStatus if the error can indicates authentication status or nil for other errors
    func getAuthenticatedEndpointStatus(fromRequestError error: Error) -> AuthenticatedEndpointStatus? {
        
        guard let urlResponse = MXHTTPOperation.urlResponse(fromError: error) else {
            return nil
        }
        
        var status: AuthenticatedEndpointStatus?
        
        switch urlResponse.statusCode {
        case 400:
            status = .authenticationNotNeeded
        case 401:
            let nsError = error as NSError
            if let jsonResponse = nsError.userInfo[MXHTTPClientErrorResponseDataKey] as? [AnyHashable: Any], let authenticationSession = MXAuthenticationSession(fromJSON: jsonResponse) {
                status = .authenticationNeeded(authenticationSession)
            }
        default:
            break
        }
        
        return status
    }
    
    /// Check if a request error ask for User-Interactive Authentication.
    /// Note: ObjC compatible.
    /// - Parameters:
    ///   - error: A request error.
    ///   - success: The closure executed the operation succeed. Get an MXAuthenticationSession if authentication is required or nil if there is no authentication needed.
    ///   - failure: The closure executed the operation fails.
    func authenticationSession(fromRequestError error: Error, success: @escaping (MXAuthenticationSession?) -> Void, failure: @escaping (Error) -> Void) {
        
        if let authenticatedEndpointStatus = self.getAuthenticatedEndpointStatus(fromRequestError: error) {
            
            if case .authenticationNeeded(let authenticationSession) = authenticatedEndpointStatus {
                success(authenticationSession)
            } else {
                success(nil)
            }
        } else {
            failure(error)
        }
    }
    
    /// Get the authentication fallback URL for the first uncompleted stage found.
    /// - Parameter authenticationSession: An authentication session for a given request.
    /// - Returns: The fallback URL for the first uncompleted stage found.
    func firstUncompletedStageAuthenticationFallbackURL(for authenticationSession: MXAuthenticationSession) -> URL? {
        guard let sessiondId = authenticationSession.session, let firstUncompletedStageIdentifier = self.firstUncompletedFlowIdentifier(in: authenticationSession) else {
            return nil
        }
        return self.authenticationFallbackURL(for: firstUncompletedStageIdentifier, sessionId: sessiondId)
    }
    
    /// Build UIA fallback authentication URL for a given stage (https://matrix.org/docs/spec/client_server/latest#fallback)
    /// - Parameters:
    ///   - flowIdentifier: The login type to authenticate with.
    ///   - sessionId:  The the ID of the session given by the homeserver.
    /// - Returns: a `MXHTTPOperation` instance.
    func authenticationFallbackURL(for flowIdentifier: String, sessionId: String) -> URL? {
        guard let homeserverStringURL = self.session.matrixRestClient.credentials.homeServer, let homeserverURL = URL(string: homeserverStringURL) else {
            return nil
        }                
        
        let fallbackPath =  "\(kMXAPIPrefixPathR0)/auth/\(flowIdentifier)/fallback/web?session=\(sessionId)"
        
        return URL(string: fallbackPath, relativeTo: homeserverURL)
    }
    
    /// Find the first uncompleted login flow stage in a MXauthenticationSession.
    /// - Parameter authenticationSession: An authentication session for a given request.
    /// - Returns: Uncompleted login flow stage identifier.
    func firstUncompletedFlowIdentifier(in authenticationSession: MXAuthenticationSession) -> String? {
        
        let completedStages = authenticationSession.completed ?? []
        
        guard let flows = authenticationSession.flows else {
            return nil
        }
               
        // Remove nil values
        let allNonNullStages = flows.compactMap { $0.stages }
        
        // Make a flat array of all stages
        let allStages: [String] = allNonNullStages.flatMap { $0 }
        
        // Keep stages order
        let uncompletedStages = NSMutableOrderedSet(array: allStages)
        
        // Keep uncompleted stages
        let completedStagesSet = NSOrderedSet(array: completedStages)
        uncompletedStages.minus(completedStagesSet)
        
        let firstUncompletedFlowIdentifier = uncompletedStages.firstObject as? String
        return firstUncompletedFlowIdentifier
    }
    
    /// Check if an array of login flows contains "m.login.password" flow.
    func hasPasswordFlow(inFlows flows: [MXLoginFlow]) -> Bool {
        for flow in flows {
            if flow.type == MXLoginFlowType.password.identifier || flow.stages.contains(MXLoginFlowType.password.identifier) {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Private
    
    private func isThereAKnownFlow(inFlows flows: [MXLoginFlow]) -> Bool {
        return self.hasPasswordFlow(inFlows: flows)
    }
    
    private func canAuthenticate(with authenticationSession: MXAuthenticationSession) -> Bool {
                        
        if self.isThereAKnownFlow(inFlows: authenticationSession.flows) {
            return true
        }
        
        if self.firstUncompletedStageAuthenticationFallbackURL(for: authenticationSession) != nil {
            return true
        }
        
        return false
    }
}
