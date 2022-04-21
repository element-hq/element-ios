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
    
    /// An async version of `request(withMethod:path:parameters:success:failure:)`.
    func request(withMethod method: String, path: String, parameters: [AnyHashable: Any]) async throws -> [AnyHashable: Any] {
        try await withCheckedThrowingContinuation { continuation in
            request(withMethod: method, path: path, parameters: parameters) { jsonDictionary in
                guard let jsonDictionary = jsonDictionary else {
                    continuation.resume(with: .failure(ClientError.invalidResponse))
                    return
                }
                
                continuation.resume(with: .success(jsonDictionary))
            } failure: { error in
                continuation.resume(with: .failure(error ?? ClientError.unknownError))
            }
        }
    }
}
