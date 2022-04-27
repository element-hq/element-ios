// 
// Copyright 2021 New Vector Ltd
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

@available(iOS 14.0, *)
protocol AuthenticationServiceDelegate: AnyObject {
    func authenticationServiceDidUpdateRegistrationParameters(_ authenticationService: AuthenticationService)
}

@available(iOS 14.0, *)
class AuthenticationService: NSObject {
    
    /// The shared service object.
    static let shared = AuthenticationService()
    
    // MARK: - Properties
    
    // MARK: Private
    
    /// The rest client used to make authentication requests.
    private var client: MXRestClient
    /// The object used to create a new `MXSession` when authentication has completed.
    private var sessionCreator = SessionCreator()
    
    // MARK: Public
    
    /// The current state of the authentication flow.
    private(set) var state: AuthenticationState
    /// The current login wizard or `nil` if `startFlow` hasn't been called.
    private(set) var loginWizard: LoginWizard?
    /// The current registration wizard or `nil` if `startFlow` hasn't been called for `.registration`.
    private(set) var registrationWizard: RegistrationWizard?
    
    // MARK: - Setup
    
    override init() {
        if let homeserverURL = URL(string: RiotSettings.shared.homeserverUrlString) {
            // Use the same homeserver that was last used.
            state = AuthenticationState(flow: .login, homeserverAddress: RiotSettings.shared.homeserverUrlString)
            client = MXRestClient(homeServer: homeserverURL, unrecognizedCertificateHandler: nil)
            
        } else if let homeserverURL = URL(string: BuildSettings.serverConfigDefaultHomeserverUrlString) {
            // Fall back to the default homeserver if the stored one is invalid.
            state = AuthenticationState(flow: .login, homeserverAddress: BuildSettings.serverConfigDefaultHomeserverUrlString)
            client = MXRestClient(homeServer: homeserverURL, unrecognizedCertificateHandler: nil)
            
        } else {
            MXLog.failure("[AuthenticationService]: Failed to create URL from default homeserver URL string.")
            fatalError("Invalid default homeserver URL string.")
        }
        
        super.init()
    }
    
    // MARK: - Public
    
    /// Whether authentication is needed by checking for any accounts.
    /// - Returns: `true` there are no accounts or if there is an inactive account that has had a soft logout.
    var needsAuthentication: Bool {
        MXKAccountManager.shared().accounts.isEmpty || softLogoutCredentials != nil
    }
    
    /// Credentials to be used when authenticating after soft logout, otherwise `nil`.
    var softLogoutCredentials: MXCredentials? {
        guard MXKAccountManager.shared().activeAccounts.isEmpty else { return nil }
        for account in MXKAccountManager.shared().accounts {
            if account.isSoftLogout {
                return account.mxCredentials
            }
        }
        
        return nil
    }
    
    /// Get the last authenticated [Session], if there is an active session.
    /// - Returns: The last active session if any, or `nil`
    var lastAuthenticatedSession: MXSession? {
        MXKAccountManager.shared().activeAccounts?.first?.mxSession
    }
    
    func startFlow(_ flow: AuthenticationFlow, for homeserverAddress: String) async throws {
        reset()
        
        let loginFlows = try await loginFlow(for: homeserverAddress)
        
        // Valid Homeserver, add it to the history.
        // Note: we add what the user has input, as the data can contain a different value.
        RiotSettings.shared.homeserverUrlString = homeserverAddress
        
        state.homeserver = .init(address: loginFlows.homeserverAddress,
                                         addressFromUser: homeserverAddress,
                                         preferredLoginMode: loginFlows.loginMode,
                                         loginModeSupportedTypes: loginFlows.supportedLoginTypes)
        
        let loginWizard = LoginWizard()
        self.loginWizard = loginWizard
        
        if flow == .registration {
            let registrationWizard = RegistrationWizard(client: client)
            state.homeserver.registrationFlow = try await registrationWizard.registrationFlow()
            self.registrationWizard = registrationWizard
        }
        
        state.flow = flow
    }
    
    /// Get a SSO url
    func getSSOURL(redirectUrl: String, deviceId: String?, providerId: String?) -> String? {
        fatalError("Not implemented.")
    }
    
    /// Get the sign in or sign up fallback URL
    func fallbackURL(for flow: AuthenticationFlow) -> URL {
        switch flow {
        case .login:
            return client.loginFallbackURL
        case .registration:
            return client.registerFallbackURL
        }
    }
    
    /// True when login and password has been sent with success to the homeserver
    var isRegistrationStarted: Bool {
        registrationWizard?.isRegistrationStarted ?? false
    }
    
    /// Reset the service to a fresh state.
    func reset() {
        loginWizard = nil
        registrationWizard = nil
        
        // The previously used homeserver is re-used as `startFlow` will be called again a replace it anyway.
        self.state = AuthenticationState(flow: .login, homeserverAddress: state.homeserver.address)
    }

    /// Create a session after a SSO successful login
    func makeSessionFromSSO(credentials: MXCredentials) -> MXSession {
        sessionCreator.createSession(credentials: credentials, client: client)
    }
    
//    /// Perform a well-known request, using the domain from the matrixId
//    func getWellKnownData(matrixId: String,
//                          homeServerConnectionConfig: HomeServerConnectionConfig?) async -> WellknownResult {
//
//    }
//
//    /// Authenticate with a matrixId and a password
//    /// Usually call this after a successful call to getWellKnownData()
//    /// - Parameter homeServerConnectionConfig the information about the homeserver and other configuration
//    /// - Parameter matrixId the matrixId of the user
//    /// - Parameter password the password of the account
//    /// - Parameter initialDeviceName the initial device name
//    /// - Parameter deviceId the device id, optional. If not provided or null, the server will generate one.
//    func directAuthentication(homeServerConnectionConfig: HomeServerConnectionConfig,
//                              matrixId: String,
//                              password: String,
//                              initialDeviceName: String,
//                              deviceId: String? = nil) async -> MXSession {
//        
//    }
    
    // MARK: - Private
    
    /// Request the supported login flows for this homeserver.
    /// This is the first method to call to be able to get a wizard to login or to create an account
    /// - Parameter homeserverAddress: The homeserver string entered by the user.
    private func loginFlow(for homeserverAddress: String) async throws -> LoginFlowResult {
        let homeserverAddress = HomeserverAddress.sanitized(homeserverAddress)
        
        guard var homeserverURL = URL(string: homeserverAddress) else {
            throw AuthenticationError.invalidHomeserver
        }
        
        let state = AuthenticationState(flow: .login, homeserverAddress: homeserverAddress)
        
        if let wellKnown = try? await wellKnown(for: homeserverURL),
           let baseURL = URL(string: wellKnown.homeServer.baseUrl) {
            homeserverURL = baseURL
        }
        
        #warning("Add an unrecognized certificate handler.")
        let client = MXRestClient(homeServer: homeserverURL, unrecognizedCertificateHandler: nil)
        
        let loginFlow = try await getLoginFlowResult(client: client)
        
        self.client = client
        self.state = state
        
        return loginFlow
    }
    
    /// Request the supported login flows for the corresponding session.
    /// This method is used to get the flows for a server after a soft-logout.
    /// - Parameter session: The MXSession where a soft-logout has occurred.
    private func loginFlow(for session: MXSession) async throws -> LoginFlowResult {
        guard let client = session.matrixRestClient else { throw AuthenticationError.missingMXRestClient }
        let state = AuthenticationState(flow: .login, homeserverAddress: client.homeserver)
        
        let loginFlow = try await getLoginFlowResult(client: session.matrixRestClient)
        
        self.client = client
        self.state = state
        
        return loginFlow
    }
    
    private func getLoginFlowResult(client: MXRestClient) async throws -> LoginFlowResult {
        // Get the login flow
        let loginFlowResponse = try await client.getLoginSession()
        
        let identityProviders = loginFlowResponse.flows?.compactMap { $0 as? MXLoginSSOFlow }.first?.identityProviders ?? []
        return LoginFlowResult(supportedLoginTypes: loginFlowResponse.flows?.compactMap { $0 } ?? [],
                               ssoIdentityProviders: identityProviders.sorted { $0.name < $1.name }.map { $0.ssoIdentityProvider },
                               homeserverAddress: client.homeserver)
    }
    
    /// Perform a well-known request on the specified homeserver URL.
    private func wellKnown(for homeserverURL: URL) async throws -> MXWellKnown {
        let wellKnownClient = MXRestClient(homeServer: homeserverURL, unrecognizedCertificateHandler: nil)
        
        // The .well-known/matrix/client API is often just a static file returned with no content type.
        // Make our HTTP client compatible with this behaviour
        wellKnownClient.acceptableContentTypes = nil
        
        return try await wellKnownClient.wellKnown()
    }
}

extension MXLoginSSOIdentityProvider {
    var ssoIdentityProvider: SSOIdentityProvider {
        SSOIdentityProvider(id: identifier, name: name, brand: brand, iconURL: icon)
    }
}
