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
        emailAddresses.map { $0.isEmpty || MXTools.isEmailAddress($0) }
    }

    func prepareIdentityService(prepared: ((String?, String?) -> Void)?, failure: ((Error?) -> Void)?) {
        isLoadingSubject.send(true)
        session.prepareIdentityServiceForTerms(withDefault: RiotSettings.shared.identityServerUrlString) { [weak self] _, baseURL, accessToken in
            self?.isLoadingSubject.send(false)
            prepared?(baseURL, accessToken)
        } failure: { [weak self] error in
            self?.isLoadingSubject.send(false)
            failure?(error)
        }
    }
}
