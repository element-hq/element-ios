//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

class MockRoomUpgradeService: RoomUpgradeServiceProtocol {
    var currentRoomId = "!sfdlksjdflkfjds:matrix.org"
    
    var errorSubject: CurrentValueSubject<Error?, Never>
    var upgradingSubject: CurrentValueSubject<Bool, Never>
    var parentSpaceName: String? {
        "Parent space name"
    }
    
    init() {
        errorSubject = CurrentValueSubject(nil)
        upgradingSubject = CurrentValueSubject(false)
    }
    
    func upgradeRoom(autoInviteUsers: Bool, completion: @escaping (Bool, String) -> Void) { }
}
