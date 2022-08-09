// 
// Copyright 2022 New Vector Ltd
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

@testable import Element

/// A mock REST client that can be used for authentication.
class MockAuthenticationRestClient: AuthenticationRestClient {
    
    enum MockError: Error {
        /// The fixture is missing.
        case fixture
        /// The method isn't implemented.
        case unhandled
        /// Login attempted with incorrect credentials.
        case invalidCredentials
        /// The homeserver doesn't allow for registration.
        case registrationDisabled
        /// A registration stage was attempted without first registering a username and password.
        case createAccountNotCalled
        /// The request is invalid.
        case invalidRequest
    }
    
    /// An account to test password based login with.
    static let registeredAccount = (username: "alice", email: "alice@example.com", phone: "+447777777777", password: "password")
    /// A token to test token based login with.
    static var pendingLoginToken = "000000"
    
    // MARK: - Configuration
    
    /// The client's internal configuration.
    var config: Config
    /// The homeserver's URL string.
    var homeserver: String! { homeserverURL.absoluteString }
    /// Unused: The identity server.
    var identityServer: String!
    /// Unused: The credentials.
    var credentials: MXCredentials!
    /// Unused: The type of content to accept for responses.
    var acceptableContentTypes: Set<String>!
    
    // MARK: - Private
    
    /// The URL used to create the client with.
    private var homeserverURL: URL
    /// Unused: A callback for handling an unrecognized certificate.
    private var unrecognizedCertificateHandler: MXHTTPClientOnUnrecognizedCertificate?
    
    /// The credentials for a pending account creation.
    private var newAccount: (username: String, password: String)?
    /// The stages completed in the registration flow.
    private var completedStages: Set<String> = []
    
    // MARK: - Setup
    
    /// Creates a new mock client.
    /// - Parameters:
    ///   - homeServer: See `MockAuthenticationRestClient.Config` for various URLs that can be used.
    ///   - handler: Unused.
    required init(homeServer: URL, unrecognizedCertificateHandler handler: MXHTTPClientOnUnrecognizedCertificate?) {
        self.config = Config(url: homeServer)
        
        self.homeserverURL = homeServer
        self.unrecognizedCertificateHandler = handler
    }
    
    // MARK: - Login
    
    var loginFallbackURL: URL {
        homeserverURL.appendingPathComponent("_matrix/static/client/login")
    }
    
    func wellKnown() async throws -> MXWellKnown {
        try MXWellKnown(fromJSON: config.wellKnownJSON())
    }
    
    func getLoginSession() async throws -> MXAuthenticationSession {
        try MXAuthenticationSession(fromJSON: config.loginSessionJSON())
    }
    
    func login(parameters: LoginParameters) async throws -> MXCredentials {
        if let passwordParameters = parameters as? LoginPasswordParameters {
            return try login(passwordParameters: passwordParameters)
        } else if let tokenParameters = parameters as? LoginTokenParameters {
            return try login(tokenParameters: tokenParameters)
        } else {
            throw MockError.unhandled
        }
    }
    
    /// Checks login against the `registeredAccount` and returns credentials if valid.
    private func login(passwordParameters: LoginPasswordParameters) throws -> MXCredentials {
        switch passwordParameters.id {
        case .user(let username):
            guard username == Self.registeredAccount.username else { throw MockError.invalidCredentials }
        case .thirdParty(medium: let medium, address: let address):
            guard medium == .email, address == Self.registeredAccount.email else { throw MockError.invalidCredentials }
        case .phone(country: let country, phone: let phone):
            guard "+\(country)\(phone)" == Self.registeredAccount.phone else { throw MockError.invalidCredentials }
        }
        
        guard passwordParameters.password == Self.registeredAccount.password else { throw MockError.invalidCredentials }
        
        return makeCredentials()
    }
    
    /// Checks login against the `pendingLoginToken` and returns credentials if valid.
    private func login(tokenParameters: LoginTokenParameters) throws -> MXCredentials {
        guard tokenParameters.token == Self.pendingLoginToken else { throw MockError.invalidCredentials }
        return makeCredentials()
    }
    
    /// Mock credentials for the registered account.
    private func makeCredentials() -> MXCredentials {
        MXCredentials(homeServer: homeserver,
                      userId: "@\(Self.registeredAccount.username):\(config.baseURL)",
                      accessToken: "1234")
    }
    
    func login(parameters: [String : Any]) async throws -> MXCredentials {
        throw MockError.unhandled
    }
    
    // MARK: - Registration
    
    var registerFallbackURL: URL {
        homeserverURL.appendingPathComponent("_matrix/static/client/register")
    }
    
    func getRegisterSession() async throws -> MXAuthenticationSession {
        try MXAuthenticationSession(fromJSON: config.registerSessionJSON())
    }
    
    func isUsernameAvailable(_ username: String) async throws -> Bool {
        username != Self.registeredAccount.username
    }
    
    func register(parameters: RegistrationParameters) async throws -> MXLoginResponse {
        guard let supportedStages = config.supportedStages else { throw MockError.registrationDisabled }
        
        let success = attemptStage(with: parameters)
        
        guard success, completedStages == supportedStages, let newAccount = newAccount else {
            var errorResponse = try config.registerSessionJSON()
            errorResponse["completed"] = Array(completedStages)
            let nsError = NSError(domain: "mock",
                                  code: 401,
                                  userInfo: [MXHTTPClientErrorResponseDataKey: errorResponse])
            throw nsError
        }
        
        let response = MXLoginResponse()
        response.accessToken = "1234"
        response.homeserver = homeserver
        response.userId = "@\(newAccount.username):\(config.baseURL)"
        
        return response
    }
    
    /// Returns a boolean indicating whether the stage was completed or not.
    private func attemptStage(with parameters: RegistrationParameters) -> Bool {
        if let username = parameters.username, let password = parameters.password {
            newAccount = (username: username, password: password)
            return true
        }
        
        guard newAccount != nil else { return false }
        guard let auth = parameters.auth else { return false }
        
        completedStages.insert(auth.type)
        
        return true
    }
    
    func register(parameters: [String : Any]) async throws -> MXLoginResponse {
        throw MockError.unhandled
    }
    
    func requestTokenDuringRegistration(for threePID: RegisterThreePID, clientSecret: String, sendAttempt: UInt) async throws -> RegistrationThreePIDTokenResponse {
        throw MockError.unhandled
    }
    
    // MARK: - Forgot password
    
    func forgetPassword(for email: String, clientSecret: String, sendAttempt: UInt) async throws -> String {
        throw MockError.unhandled
    }
    
    func resetPassword(parameters: CheckResetPasswordParameters) async throws {
        throw MockError.unhandled
    }
    
    func resetPassword(parameters: [String : Any]) async throws {
        throw MockError.unhandled
    }
}
