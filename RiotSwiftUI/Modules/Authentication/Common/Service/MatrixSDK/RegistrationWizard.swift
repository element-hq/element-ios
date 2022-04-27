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

@available(iOS 14.0, *)
/// Set of methods to be able to create an account on a homeserver.
///
/// Common scenario to register an account successfully:
///  - Call `registrationFlow` to check that you application supports all the mandatory registration stages
///  - Call `createAccount` to start the account creation
///  - Fulfil all mandatory stages using the methods `performReCaptcha` `acceptTerms` `dummy`, etc.
///
/// More documentation can be found in the file https://github.com/vector-im/element-android/blob/main/docs/signup.md
/// and https://matrix.org/docs/spec/client_server/latest#account-registration-and-management
class RegistrationWizard {
    struct State {
        var currentSession: String?
        var isRegistrationStarted = false
        var currentThreePIDData: ThreePIDData?
        
        var clientSecret = UUID().uuidString
        var sendAttempt: UInt = 0
    }
    
    let client: MXRestClient
    let sessionCreator: SessionCreator
    
    private(set) var state: State
    
    /// This is the current ThreePID, waiting for validation. The SDK will store it in database, so it can be
    /// restored even if the app has been killed during the registration
    var currentThreePID: String? {
        guard let threePid = state.currentThreePIDData?.threePID else { return nil }
        
        switch threePid {
        case .email(let string):
            return string
        case .msisdn(let msisdn, _):
            return state.currentThreePIDData?.registrationResponse.formattedMSISDN ?? msisdn
        }
    }

    /// True when login and password have been sent with success to the homeserver,
    /// i.e. `createAccount` has been called successfully.
    var isRegistrationStarted: Bool {
        state.isRegistrationStarted
    }
    
    init(client: MXRestClient, sessionCreator: SessionCreator = SessionCreator()) {
        self.client = client
        self.sessionCreator = sessionCreator
        
        self.state = State()
    }
    
    /// Call this method to get the possible registration flow of the current homeserver.
    /// It can be useful to ensure that your application implementation supports all the stages
    /// required to create an account. If it is not the case, you will have to use the web fallback
    /// to let the user create an account with your application.
    /// See `AuthenticationService.getFallbackUrl`
    func registrationFlow() async throws -> RegistrationResult {
        let parameters = RegistrationParameters()
        return try await performRegistrationRequest(parameters: parameters)
    }

    /// Can be call to check is the desired username is available for registration on the current homeserver.
    /// It may also fails if the desired username is not correctly formatted or does not follow any restriction on
    /// the homeserver. Ex: username with only digits may be rejected.
    /// - Parameter username the desired username. Ex: "alice"
    func registrationAvailable(username: String) async throws -> Bool {
        try await client.isUsernameAvailable(username)
    }

    /// This is the first method to call in order to create an account and start the registration process.
    ///
    /// - Parameter username the desired username. Ex: "alice"
    /// - Parameter password the desired password
    /// - Parameter initialDeviceDisplayName the device display name
    func createAccount(username: String?,
                       password: String?,
                       initialDeviceDisplayName: String?) async throws -> RegistrationResult {
        let parameters = RegistrationParameters(username: username, password: password, initialDeviceDisplayName: initialDeviceDisplayName)
        let result = try await performRegistrationRequest(parameters: parameters)
        state.isRegistrationStarted = true
        return result
    }

    /// Perform the "m.login.recaptcha" stage.
    ///
    /// - Parameter response: The response from ReCaptcha
    func performReCaptcha(response: String) async throws -> RegistrationResult {
        guard let session = state.currentSession else {
            throw RegistrationError.createAccountNotCalled
        }
        
        let parameters = RegistrationParameters(auth: AuthenticationParameters.captchaParameters(session: session, captchaResponse: response))
        return try await performRegistrationRequest(parameters: parameters)
    }

    /// Perform the "m.login.terms" stage.
    func acceptTerms() async throws -> RegistrationResult {
        guard let session = state.currentSession else {
            throw RegistrationError.createAccountNotCalled
        }
        
        let parameters = RegistrationParameters(auth: AuthenticationParameters(type: kMXLoginFlowTypeTerms, session: session))
        return try await performRegistrationRequest(parameters: parameters)
    }

    /// Perform the "m.login.dummy" stage.
    func dummy() async throws -> RegistrationResult {
        guard let session = state.currentSession else {
            throw RegistrationError.createAccountNotCalled
        }
        
        let parameters = RegistrationParameters(auth: AuthenticationParameters(type: kMXLoginFlowTypeDummy, session: session))
        return try await performRegistrationRequest(parameters: parameters)
    }

    /// Perform the "m.login.email.identity" or "m.login.msisdn" stage.
    ///
    /// - Parameter threePID the threePID to add to the account. If this is an email, the homeserver will send an email
    /// to validate it. For a msisdn a SMS will be sent.
    func addThreePID(threePID: RegisterThreePID) async throws -> RegistrationResult {
        state.currentThreePIDData = nil
        return try await sendThreePID(threePID: threePID)
    }

    /// Ask the homeserver to send again the current threePID (email or msisdn).
    func sendAgainThreePID() async throws -> RegistrationResult {
        guard let threePID = state.currentThreePIDData?.threePID else {
            throw RegistrationError.createAccountNotCalled
        }
        return try await sendThreePID(threePID: threePID)
    }

    /// Send the code received by SMS to validate a msisdn.
    /// If the code is correct, the registration request will be executed to validate the msisdn.
    func handleValidateThreePID(code: String) async throws -> RegistrationResult {
        return try await validateThreePid(code: code)
    }

    /// Useful to poll the homeserver when waiting for the email to be validated by the user.
    /// Once the email is validated, this method will return successfully.
    /// - Parameter delay How long to wait before sending the request.
    func checkIfEmailHasBeenValidated(delay: TimeInterval) async throws -> RegistrationResult {
        MXLog.failure("The delay on this method is no longer available. Move this to the object handling the polling.")
        guard let parameters = state.currentThreePIDData?.registrationParameters else {
            throw RegistrationError.missingThreePIDData
        }

        return try await performRegistrationRequest(parameters: parameters)
    }
    
    // MARK: - Private
    
    private func validateThreePid(code: String) async throws -> RegistrationResult {
        guard let threePIDData = state.currentThreePIDData else {
            throw RegistrationError.missingThreePIDData
        }
        
        guard let submitURL = threePIDData.registrationResponse.submitURL else {
            throw RegistrationError.missingThreePIDURL
        }
        
        
        let validationBody = ThreePIDValidationCodeBody(clientSecret: state.clientSecret,
                                                        sessionID: threePIDData.registrationResponse.sessionID,
                                                        code: code)
        
        #warning("Seems odd to pass a nil baseURL and then the url as the path, yet this is how MXK3PID works")
        guard let httpClient = MXHTTPClient(baseURL: nil, andOnUnrecognizedCertificateBlock: nil) else {
            throw RegistrationError.threePIDClientFailure
        }
        guard try await httpClient.validateThreePIDCode(submitURL: submitURL, validationBody: validationBody) else {
            throw RegistrationError.threePIDValidationFailure
        }
        
        let parameters = threePIDData.registrationParameters
        MXLog.failure("This method used to add a 3-second delay to the request. This should be moved to the caller of `handleValidateThreePID`.")
        return try await performRegistrationRequest(parameters: parameters)
    }
    
    private func sendThreePID(threePID: RegisterThreePID) async throws -> RegistrationResult {
        guard let session = state.currentSession else {
            throw RegistrationError.createAccountNotCalled
        }
        
        let response = try await client.requestTokenDuringRegistration(for: threePID,
                                                                       clientSecret: state.clientSecret,
                                                                       sendAttempt: state.sendAttempt)
        
        state.sendAttempt += 1
        
        let threePIDCredentials = ThreePIDCredentials(clientSecret: state.clientSecret, sessionID: response.sessionID)
        let authenticationParameters: AuthenticationParameters
        switch threePID {
        case .email:
            authenticationParameters = AuthenticationParameters.emailIdentityParameters(session: session, threePIDCredentials: threePIDCredentials)
        case .msisdn:
            authenticationParameters = AuthenticationParameters.msisdnIdentityParameters(session: session, threePIDCredentials: threePIDCredentials)
        }
        
        let parameters = RegistrationParameters(auth: authenticationParameters)
        
        state.currentThreePIDData = ThreePIDData(threePID: threePID, registrationResponse: response, registrationParameters: parameters)

        // Send the session id for the first time
        return try await performRegistrationRequest(parameters: parameters)
    }
    
    private func performRegistrationRequest(parameters: RegistrationParameters) async throws -> RegistrationResult {
        do {
            let response = try await client.register(parameters: parameters)
            let credentials = MXCredentials(loginResponse: response, andDefaultCredentials: client.credentials)
            return .success(sessionCreator.createSession(credentials: credentials, client: client))
        } catch {
            let nsError = error as NSError
            
            guard
                let jsonResponse = nsError.userInfo[MXHTTPClientErrorResponseDataKey] as? [String: Any],
                let authenticationSession = MXAuthenticationSession(fromJSON: jsonResponse)
            else { throw error }
            
            state.currentSession = authenticationSession.session
            return .flowResponse(authenticationSession.flowResult)
        }
    }
}
