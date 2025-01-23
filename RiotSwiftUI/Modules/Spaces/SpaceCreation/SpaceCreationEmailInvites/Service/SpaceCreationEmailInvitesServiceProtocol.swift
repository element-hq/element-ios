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

protocol SpaceCreationEmailInvitesServiceProtocol {
    var isIdentityServiceReady: Bool { get }
    var isLoadingSubject: CurrentValueSubject<Bool, Never> { get }
    func validate(_ emailAddresses: [String]) -> [Bool]
    func prepareIdentityService(prepared: ((String?, String?) -> Void)?, failure: ((Error?) -> Void)?)
}
