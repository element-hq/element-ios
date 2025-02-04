// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationEmailInvites SpaceCreationEmailInvites
//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
