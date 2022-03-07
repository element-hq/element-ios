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
class MockOnboardingDisplayNameService: OnboardingDisplayNameServiceProtocol {
    var displayName: String?
    
    #warning("isWaiting isn't handled.")
    init(displayName: String? = nil, isWaiting: Bool = false) {
        self.displayName = displayName
    }
    
    func setDisplayName(_ displayName: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
            self.displayName = displayName
            completion(.success(true))
        }
    }
}
