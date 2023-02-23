// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationEmailInvites SpaceCreationEmailInvites
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

import Combine
import Foundation

class MockSpaceCreationEmailInvitesService: SpaceCreationEmailInvitesServiceProtocol {
    var isLoadingSubject: CurrentValueSubject<Bool, Never>
    
    private let defaultValidation: Bool
    
    var isIdentityServiceReady: Bool {
        true
    }
    
    init(defaultValidation: Bool, isLoading: Bool) {
        self.defaultValidation = defaultValidation
        isLoadingSubject = CurrentValueSubject(isLoading)
    }
    
    func validate(_ emailAddresses: [String]) -> [Bool] {
        emailAddresses.map { _ in defaultValidation }
    }
    
    func prepareIdentityService(prepared: ((String?, String?) -> Void)?, failure: ((Error?) -> Void)?) {
        failure?(nil)
    }
}
