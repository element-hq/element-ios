//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation

protocol RoomUpgradeServiceProtocol {
    var currentRoomId: String { get }
    var parentSpaceName: String? { get }
    var upgradingSubject: CurrentValueSubject<Bool, Never> { get }
    var errorSubject: CurrentValueSubject<Error?, Never> { get }
    
    func upgradeRoom(autoInviteUsers: Bool, completion: @escaping (Bool, String) -> Void)
}
