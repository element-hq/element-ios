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

import Foundation
import Combine

class SpaceCreationEmailInvitesService: SpaceCreationEmailInvitesServiceProtocol {
    
    private let session: MXSession
    private(set) var isLoadingSubject: CurrentValueSubject<Bool, Never>
    
    var isIdentityServiceReady: Bool {
        if let identityService = session.identityService {
            return identityService.areAllTermsAgreed
        }
        return false
    }
    
    init(session: MXSession) {
        self.session = session
        isLoadingSubject = CurrentValueSubject(false)
    }
    
    func validate(_ emailAddresses: [String]) -> [Bool] {
        return emailAddresses.map { $0.isEmpty || MXTools.isEmailAddress($0) }
    }

    func prepareIdentityService(prepared: ((String?, String?) -> Void)?, failure: ((Error?) -> Void)?) {
        isLoadingSubject.send(true)
        session.prepareIdentityServiceForTerms(withDefault: RiotSettings.shared.identityServerUrlString) { [weak self] session, baseURL, accessToken in
            self?.isLoadingSubject.send(false)
            prepared?(baseURL, accessToken)
        } failure: { [weak self] error in
            self?.isLoadingSubject.send(false)
            failure?(error)
        }
    }
}
