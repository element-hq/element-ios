//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

enum SpaceSettingsServiceCompletionResult {
    case success
    case failure(Error)
}

protocol SpaceSettingsServiceProtocol: Avatarable {
    var spaceId: String { get }
    var roomProperties: SpaceSettingsRoomProperties? { get }
    
    var isLoadingSubject: CurrentValueSubject<Bool, Never> { get }
    var roomPropertiesSubject: CurrentValueSubject<SpaceSettingsRoomProperties?, Never> { get }
    var showPostProcessAlert: CurrentValueSubject<Bool, Never> { get }
    var addressValidationSubject: CurrentValueSubject<SpaceCreationSettingsAddressValidationStatus, Never> { get }

    func update(roomName: String, topic: String, address: String, avatar: UIImage?, completion: ((_ result: SpaceSettingsServiceCompletionResult) -> Void)?)
    func addressDidChange(_ newValue: String)
    func trackSpace()
}

// MARK: Avatarable

extension SpaceSettingsServiceProtocol {
    var mxContentUri: String? {
        roomProperties?.avatarUrl
    }

    var matrixItemId: String {
        spaceId
    }
}
