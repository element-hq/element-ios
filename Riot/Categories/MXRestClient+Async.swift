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
    
    /// An async version of `getRegisterSession(completion:)`.
    func getRegisterSession() async throws -> MXAuthenticationSession {
        try await getResponse(getRegisterSession)
    }
    
    /// An async version of `getLoginSession(completion:)`.
    func getLoginSession() async throws -> MXAuthenticationSession {
        try await getResponse(getLoginSession)
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
    
    // MARK: Private
    
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
