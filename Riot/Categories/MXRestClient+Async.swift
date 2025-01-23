// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

@available(iOS 13.0, *)
extension MXRestClient {
    /// Errors thrown by the async extensions to `MXRestClient.`
    enum ClientError: Error {
        /// An unexpected response was received.
        case invalidResponse
        /// The error that occurred was missing from the closure.
        case unknownError
        /// An error occurred whilst decoding the received JSON.
        case decodingError
    }
    
    /// An async version of `wellKnow(_:failure:)`.
    func wellKnown() async throws -> MXWellKnown {
        try await getResponse { success, failure in
            wellKnow(success, failure: failure)
        }
    }
    
    // MARK: - Login
    
    /// An async version of `getLoginSession(completion:)`.
    func getLoginSession() async throws -> MXAuthenticationSession {
        try await getResponse(getLoginSession)
    }
    
    /// An async version of `login(parameters:completion:)`, that takes a value that conforms to `LoginParameters`.
    func login(parameters: LoginParameters) async throws -> MXCredentials {
        let dictionary = try parameters.dictionary()
        return try await login(parameters: dictionary)
    }
    
    /// An async version of `login(parameters:completion:)`.
    func login(parameters: [String: Any]) async throws -> MXCredentials {
        let jsonDictionary = try await getResponse { completion in
            login(parameters: parameters, completion: completion)
        }
        guard let loginResponse = MXLoginResponse(fromJSON: jsonDictionary) else { throw ClientError.decodingError }
        return MXCredentials(loginResponse: loginResponse, andDefaultCredentials: credentials)
    }
    
    /// An async version of generateLoginToken(completion:)
    func generateLoginToken() async throws -> MXLoginToken {
        try await getResponse(generateLoginToken)
    }
    
    // MARK: - Registration
    
    /// An async version of `getRegisterSession(completion:)`.
    func getRegisterSession() async throws -> MXAuthenticationSession {
        try await getResponse(getRegisterSession)
    }
    
    /// An async version of `isUsernameAvailable(_:completion:)`.
    func isUsernameAvailable(_ username: String) async throws -> Bool {
        let availability = try await getResponse { completion in
            isUsernameAvailable(username, completion: completion)
        }
        return availability.available
    }
    
    /// An async version of `register(parameters:completion:)`, that takes a `RegistrationParameters` value instead of a dictionary.
    func register(parameters: RegistrationParameters) async throws -> MXLoginResponse {
        let dictionary = try parameters.dictionary()
        return try await register(parameters: dictionary)
    }
    
    /// An async version of `register(parameters:completion:)`.
    func register(parameters: [String: Any]) async throws -> MXLoginResponse {
        let jsonDictionary = try await getResponse { completion in
            register(parameters: parameters, completion: completion)
        }
        guard let loginResponse = MXLoginResponse(fromJSON: jsonDictionary) else { throw ClientError.decodingError }
        return loginResponse
    }
    
    /// An async version of both `requestToken(forEmail:isDuringRegistration:clientSecret:sendAttempt:nextLink:success:failure:)` and
    /// `requestToken(forPhoneNumber:isDuringRegistration:countryCode:clientSecret:sendAttempt:nextLink:success:failure:)` depending
    /// on the kind of third party ID is supplied to the `threePID` parameter.
    func requestTokenDuringRegistration(for threePID: RegisterThreePID, clientSecret: String, sendAttempt: UInt) async throws -> RegistrationThreePIDTokenResponse {
        switch threePID {
        case .email(let email):
            let sessionID: String = try await getResponse { success, failure in
                requestToken(forEmail: email,
                             isDuringRegistration: true,
                             clientSecret: clientSecret,
                             sendAttempt: sendAttempt,
                             nextLink: nil,
                             success: success,
                             failure: failure)
            }
            
            return RegistrationThreePIDTokenResponse(sessionID: sessionID)
        case .msisdn(let msisdn, let countryCode):
            let (sessionID, msisdn, submitURL): (String?, String?, String?) = try await getResponse { success, failure in
                requestToken(forPhoneNumber: msisdn,
                             isDuringRegistration: true,
                             countryCode: countryCode,
                             clientSecret: clientSecret,
                             sendAttempt: sendAttempt,
                             nextLink: nil,
                             success: success,
                             failure: failure)
            }
            guard let sessionID = sessionID else { throw ClientError.invalidResponse }
            return RegistrationThreePIDTokenResponse(sessionID: sessionID, submitURL: submitURL, msisdn: msisdn)
        }
    }
    
    // MARK: - Reset Password
    
    /// An async version of `forgetPassword(forEmail:clientSecret:sendAttempt:success:failure:)`.
    /// - Returns: The session ID to be included when calling `resetPassword(parameters:)`.
    func forgetPassword(for email: String, clientSecret: String, sendAttempt: UInt) async throws -> String {
        try await getResponse { success, failure in
            forgetPassword(forEmail: email,
                           clientSecret: clientSecret,
                           sendAttempt: sendAttempt,
                           success: success,
                           failure: failure)
        }
    }
    
    /// An async version of `resetPassword(parameters:completion:)`, that takes a `CheckResetPasswordParameters` value instead of a dictionary.
    func resetPassword(parameters: CheckResetPasswordParameters) async throws {
        let dictionary = try parameters.dictionary()
        try await resetPassword(parameters: dictionary)
    }
    
    /// An async version of `resetPassword(parameters:completion:)`.
    func resetPassword(parameters: [String: Any]) async throws {
        try await getResponse { completion in
            resetPassword(parameters: parameters, completion: completion)
        }
    }

    // MARK: - Change Password

    /// An async version of `changePassword(from:to:logoutDevices:completion:)`.
    func changePassword(from oldPassword: String, to newPassword: String, logoutDevices: Bool) async throws {
        try await getResponse { completion in
            changePassword(from: oldPassword, to: newPassword, logoutDevices: logoutDevices, completion: completion)
        }
    }

    // MARK: - Versions

    /// An async version of `supportedMatrixVersions(completion:)`.
    func supportedMatrixVersions() async throws -> MXMatrixVersions {
        try await getResponse({ completion in
            supportedMatrixVersions(completion: completion)
        })
    }
    
    // MARK: - Private
    
    @MainActor
    private func getResponse<T>(_ callback: (@escaping (MXResponse<T>) -> Void) -> MXHTTPOperation) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            _ = callback { response in
                guard let value = response.value else {
                    continuation.resume(with: .failure(response.error ?? ClientError.unknownError))
                    return
                }
                
                continuation.resume(with: .success(value))
            }
        }
    }
    
    @MainActor
    private func getResponse<T>(_ callback: (@escaping (T?) -> Void, @escaping (Error?) -> Void) -> MXHTTPOperation) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            _ = callback { response in
                guard let response = response else {
                    continuation.resume(with: .failure(ClientError.invalidResponse))
                    return
                }
                
                continuation.resume(with: .success(response))
            } _: { error in
                continuation.resume(with: .failure(error ?? ClientError.unknownError))
            }
        }
    }
    
    @MainActor
    private func getResponse<T, U, V>(_ callback: (@escaping (T?, U?, V?) -> Void, @escaping (Error?) -> Void) -> MXHTTPOperation) async throws -> (T?, U?, V?) {
        try await withCheckedThrowingContinuation { continuation in
            _ = callback { arg1, arg2, arg3  in
                continuation.resume(with: .success((arg1, arg2, arg3)))
            } _: { error in
                continuation.resume(with: .failure(error ?? ClientError.unknownError))
            }
        }
    }
}
