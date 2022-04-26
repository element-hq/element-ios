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
extension MXHTTPClient {
    /// Errors thrown by the async extensions to `MXHTTPClient.`
    enum ClientError: Error {
        /// An unexpected response was received.
        case invalidResponse
        /// The error that occurred was missing from the closure.
        case unknownError
    }
    
    /// Validates a third party ID code at the given URL.
    func validateThreePIDCode(submitURL: String, validationBody: ThreePIDValidationCodeBody) async throws -> Bool {
        let data = try validationBody.jsonData()
        let responseDictionary = try await request(withMethod: "POST", path: submitURL, parameters: nil, data: data)
        
        // Response is a json dictionary with a single success parameter
        guard let success = responseDictionary["success"] as? Bool else {
            throw ClientError.invalidResponse
        }
        
        return success
    }
    
    /// An async version of `request(withMethod:path:parameters:success:failure:)`.
    func request(withMethod method: String,
                 path: String,
                 parameters: [AnyHashable: Any]?,
                 needsAuthentication: Bool? = nil,
                 data: Data? = nil,
                 headers: [AnyHashable: Any]? = nil,
                 timeout: TimeInterval = -1) async throws -> [AnyHashable: Any] {
        try await getResponse { success, failure in
            request(withMethod: method,
                    path: path,
                    parameters: parameters,
                    needsAuthentication: needsAuthentication ?? isAuthenticatedClient,
                    data: data,
                    headers: headers,
                    timeout: timeout,
                    uploadProgress: nil,
                    success: success,
                    failure: failure)
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
}
