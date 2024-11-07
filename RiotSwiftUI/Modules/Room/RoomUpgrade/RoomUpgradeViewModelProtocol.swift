//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

protocol RoomUpgradeViewModelProtocol {
    var completion: ((RoomUpgradeViewModelResult) -> Void)? { get set }
    static func makeRoomUpgradeViewModel(roomUpgradeService: RoomUpgradeServiceProtocol) -> RoomUpgradeViewModelProtocol
    var context: RoomUpgradeViewModelType.Context { get }
}
