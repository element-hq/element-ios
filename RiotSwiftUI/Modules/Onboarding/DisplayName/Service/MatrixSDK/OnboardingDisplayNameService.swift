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
import Combine

@available(iOS 14.0, *)
class OnboardingDisplayNameService: OnboardingDisplayNameServiceProtocol {
    
    enum ServiceError: Error {
        case unknown
    }
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let userSession: UserSession
    
    // MARK: Public
    
    var displayName: String? {
        userSession.account.userDisplayName
    }
    
    // MARK: - Setup
    
    init(userSession: UserSession) {
        self.userSession = userSession
    }
    
    func setDisplayName(_ displayName: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        userSession.account.setUserDisplayName(displayName) {
            completion(.success(true))
        } failure: { error in
            completion(.failure(error ?? ServiceError.unknown))
        }
    }
}
