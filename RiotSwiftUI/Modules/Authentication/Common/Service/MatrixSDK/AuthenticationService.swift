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
    /// Pending data collected as the authentication flow progresses.
    private var pendingData: AuthenticationPendingData?
    /// The current registration wizard or `nil` if `registrationWizard()` hasn't been called.
    private var currentRegistrationWizard: RegistrationWizard?
    /// The current login wizard or `nil` if `loginWizard()` hasn't been called.
    private var currentLoginWizard: LoginWizard?
    /// The object used to create a new `MXSession` when authentication has completed.
    private var sessionCreator = SessionCreator()
    
    // MARK: Public
    
    /// The address of the homeserver that the service is using.
    var homeserverAddress: String {
        state.homeserverAddress ?? RiotSettings.shared.homeserverUrlString
    }
    
    
    // MARK: Android OnboardingViewModel
    /// The current state of the authentication flow.
    private var state = AuthenticationCoordinatorState()
    /// The currently executing async task.
    private var currentTask: Task<Void, Error>? {
        willSet {
            currentTask?.cancel()
        }
    }
    
    
    // MARK: - Setup
    
    override init() {
        guard let homeserverURL = URL(string: RiotSettings.shared.homeserverUrlString) else {
            fatalError("[AuthenticationService]: Failed to create URL from default homeserver URL string.")
        }
        
        client = MXRestClient(homeServer: homeserverURL, unrecognizedCertificateHandler: nil)
        
        super.init()
    }
    
    // MARK: - Android OnboardingViewModel
    
    func loginFlow(homeserverAddress: String) async {
        currentTask = Task {
            cancelPendingLoginOrRegistration()
            
            do {
                let data = try await loginFlow(for: homeserverAddress)
                
                guard !Task.isCancelled else { return }
                
                // Valid Homeserver, add it to the history.
                // Note: we add what the user has input, as the data can contain a different value.
                RiotSettings.shared.homeserverUrlString = homeserverAddress
                
                let loginMode: LoginMode
                
                if data.supportedLoginTypes.contains(where: { $0.type == kMXLoginFlowTypeSSO }),
                   data.supportedLoginTypes.contains(where: { $0.type == kMXLoginFlowTypePassword }) {
                    loginMode = .ssoAndPassword(ssoIdentityProviders: data.ssoIdentityProviders)
                } else if data.supportedLoginTypes.contains(where: { $0.type == kMXLoginFlowTypeSSO }) {
                    loginMode = .sso(ssoIdentityProviders: data.ssoIdentityProviders)
                } else if data.supportedLoginTypes.contains(where: { $0.type == kMXLoginFlowTypePassword }) {
                    loginMode = .password
                } else {
                    loginMode = .unsupported
                }
                
                state.homeserverAddressFromUser = homeserverAddress
                state.homeserverAddress = data.homeserverAddress
                state.loginMode = loginMode
                state.loginModeSupportedTypes = data.supportedLoginTypes
            } catch {
                #warning("Show an error message and/or handle the error?")
                return
            }
        }
    }
    
    func refreshServer(homeserverAddress: String) async throws -> (LoginFlowResult, RegistrationResult) {
        let loginFlows = try await loginFlow(for: homeserverAddress)
        let wizard = try registrationWizard()
        let registrationFlow = try await wizard.registrationFlow()
        
        state.homeserverAddress = homeserverAddress
        
        return (loginFlows, registrationFlow)
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
    
    enum AuthenticationMode {
        case login
        case registration
    }
    
    /// Request the supported login flows for this homeserver.
    /// This is the first method to call to be able to get a wizard to login or to create an account
    /// - Parameter homeserverAddress: The homeserver string entered by the user.
    func loginFlow(for homeserverAddress: String) async throws -> LoginFlowResult {
        pendingData = nil
        
        let homeserverAddress = HomeserverAddress.sanitize(homeserverAddress)
        
        guard var homeserverURL = URL(string: homeserverAddress) else {
            throw AuthenticationError.invalidHomeserver
        }
        
        let pendingData = AuthenticationPendingData(homeserverAddress: homeserverAddress)
        
        if let wellKnown = try? await wellKnown(for: homeserverURL),
           let baseURL = URL(string: wellKnown.homeServer.baseUrl) {
            homeserverURL = baseURL
        }
        
        #warning("Add an unrecognized certificate handler.")
        let client = MXRestClient(homeServer: homeserverURL, unrecognizedCertificateHandler: nil)
        
        let loginFlow = try await getLoginFlowResult(client: client)
        
        self.client = client
        self.pendingData = pendingData
        
        return loginFlow
    }
    
    /// Request the supported login flows for the corresponding session.
    /// This method is used to get the flows for a server after a soft-logout.
    /// - Parameter session: The MXSession where a soft-logout has occurred.
    func loginFlow(for session: MXSession) async throws -> LoginFlowResult {
        pendingData = nil
        
        guard let client = session.matrixRestClient else { throw AuthenticationError.missingMXRestClient }
        let pendingData = AuthenticationPendingData(homeserverAddress: client.homeserver)
        
        let loginFlow = try await getLoginFlowResult(client: session.matrixRestClient)
        
        self.client = client
        self.pendingData = pendingData
        
        return loginFlow
    }
    
    /// Get a SSO url
    func getSSOURL(redirectUrl: String, deviceId: String?, providerId: String?) -> String? {
        fatalError("Not implemented.")
    }
    
    /// Get the sign in or sign up fallback URL
    func fallbackURL(for authenticationMode: AuthenticationMode) -> URL {
        switch authenticationMode {
        case .login:
            return client.loginFallbackURL
        case .registration:
            return client.registerFallbackURL
        }
    }
    
    /// Return a LoginWizard, to login to the homeserver. The login flow has to be retrieved first.
    ///
    /// See ``LoginWizard`` for more details
    func loginWizard() throws -> LoginWizard {
        if let currentLoginWizard = currentLoginWizard {
            return currentLoginWizard
        }
        
        guard let pendingData = pendingData else {
            throw AuthenticationError.loginFlowNotCalled
        }
        
        let wizard = LoginWizard()
        return wizard
    }
    
    /// Return a RegistrationWizard, to create a matrix account on the homeserver. The login flow has to be retrieved first.
    ///
    /// See ``RegistrationWizard`` for more details.
    func registrationWizard() throws -> RegistrationWizard {
        if let currentRegistrationWizard = currentRegistrationWizard {
            return currentRegistrationWizard
        }
        
        guard let pendingData = pendingData else {
            throw AuthenticationError.loginFlowNotCalled
        }

        
        let wizard = RegistrationWizard(client: client, pendingData: pendingData)
        currentRegistrationWizard = wizard
        return wizard
    }
    
    /// True when login and password has been sent with success to the homeserver
    var isRegistrationStarted: Bool {
        currentRegistrationWizard?.isRegistrationStarted ?? false
    }
    
    /// Cancel pending login or pending registration
    func cancelPendingLoginOrRegistration() {
        currentTask?.cancel()
        
        currentLoginWizard = nil
        currentRegistrationWizard = nil

        // Keep only the homesever config
        guard let pendingData = pendingData else {
            // Should not happen
            return
        }

        self.pendingData = AuthenticationPendingData(homeserverAddress: pendingData.homeserverAddress)
    }
    
    /// Reset all pending settings, including current HomeServerConnectionConfig
    func reset() {
        pendingData = nil
        currentRegistrationWizard = nil
        currentLoginWizard = nil
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
    
    private func getLoginFlowResult(client: MXRestClient/*, versions: Versions*/) async throws -> LoginFlowResult {
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
