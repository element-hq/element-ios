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
        try await withCheckedThrowingContinuation { continuation in
            wellKnow { wellKnown in
                guard let wellKnown = wellKnown else {
                    continuation.resume(with: .failure(ClientError.invalidResponse))
                    return
                }
                
                continuation.resume(with: .success(wellKnown))
            } failure: { error in
                continuation.resume(with: .failure(error ?? ClientError.unknownError))
            }
        }
    }
    
    /// An async version of `getRegisterSession(completion:)`.
    func getRegisterSession() async throws -> MXAuthenticationSession {
        try await withCheckedThrowingContinuation { continuation in
            getRegisterSession { response in
                guard let session = response.value else {
                    continuation.resume(with: .failure(response.error ?? ClientError.unknownError))
                    return
                }
                
                continuation.resume(with: .success(session))
            }
        }
    }
    
    /// An async version of `getLoginSession(completion:)`.
    func getLoginSession() async throws -> MXAuthenticationSession {
        try await withCheckedThrowingContinuation { continuation in
            getLoginSession { response in
                guard let session = response.value else {
                    continuation.resume(with: .failure(response.error ?? ClientError.unknownError))
                    return
                }
                
                continuation.resume(with: .success(session))
            }
        }
    }
    
    /// An async version of `isUsernameAvailable(_:completion:)`.
    func isUsernameAvailable(_ username: String) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            isUsernameAvailable(username) { response in
                guard let availability = response.value else {
                    continuation.resume(with: .failure(response.error ?? ClientError.unknownError))
                    return
                }
                
                continuation.resume(with: .success(availability.available))
            }
        }
    }
    
    /// An async version of `register(parameters:completion:)`.
    func register(parameters: [String: Any]) async throws -> MXLoginResponse {
        try await withCheckedThrowingContinuation { continuation in
            register(parameters: parameters) { response in
                guard let jsonDictionary = response.value else {
                    continuation.resume(with: .failure(response.error ?? ClientError.unknownError))
                    return
                }
                
                guard let loginResponse = MXLoginResponse(fromJSON: jsonDictionary) else {
                    continuation.resume(with: .failure(ClientError.decodingError))
                    return
                }
                
                continuation.resume(with: .success(loginResponse))
            }
        }
    }
    
    /// An async version of both `requestToken(forEmail:isDuringRegistration:clientSecret:sendAttempt:nextLink:success:failure:)` and
    /// `requestToken(forPhoneNumber:isDuringRegistration:countryCode:clientSecret:sendAttempt:nextLink:success:failure:)` depending
    /// on the kind of third party ID is supplied to the `threePID` parameter.
    func requestTokenDuringRegistration(for threePID: RegisterThreePID, clientSecret: String, sendAttempt: UInt) async throws -> RegistrationThreePIDTokenResponse {
        try await withCheckedThrowingContinuation { continuation in
            switch threePID {
            case .email(let email):
                requestToken(forEmail: email, isDuringRegistration: true, clientSecret: clientSecret, sendAttempt: sendAttempt, nextLink: nil) { sessionID in
                    guard let sessionID = sessionID else {
                        continuation.resume(with: .failure(ClientError.invalidResponse))
                        return
                    }
                    
                    let response = RegistrationThreePIDTokenResponse(sessionID: sessionID)
                    continuation.resume(with: .success(response))
                } failure: { error in
                    continuation.resume(with: .failure(error ?? ClientError.unknownError))
                }

            case .msisdn(let msisdn, let countryCode):
                requestToken(forPhoneNumber: msisdn, isDuringRegistration: true, countryCode: countryCode, clientSecret: clientSecret, sendAttempt: sendAttempt, nextLink: nil) { sessionID, msisdn, submitURL in
                    guard let sessionID = sessionID else {
                        continuation.resume(with: .failure(ClientError.invalidResponse))
                        return
                    }
                    
                    let response = RegistrationThreePIDTokenResponse(sessionID: sessionID, submitURL: submitURL, msisdn: msisdn)
                    continuation.resume(with: .success(response))
                } failure: { error in
                    continuation.resume(with: .failure(error ?? ClientError.unknownError))
                }
            }
        }
    }
}
