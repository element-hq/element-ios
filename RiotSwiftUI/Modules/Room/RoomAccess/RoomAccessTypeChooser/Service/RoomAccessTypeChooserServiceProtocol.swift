//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

protocol RoomAccessTypeChooserServiceProtocol {
    var accessItemsSubject: CurrentValueSubject<[RoomAccessTypeChooserAccessItem], Never> { get }
    var roomUpgradeRequiredSubject: CurrentValueSubject<Bool, Never> { get }
    var waitingMessageSubject: CurrentValueSubject<String?, Never> { get }
    var errorSubject: CurrentValueSubject<Error?, Never> { get }
    
    var selectedType: RoomAccessTypeChooserAccessType { get }
    var currentRoomId: String { get }
    var versionOverride: String? { get }

    func updateSelection(with selectedType: RoomAccessTypeChooserAccessType)
    func applySelection(completion: @escaping () -> Void)
    func updateRoomId(with roomId: String)
}
