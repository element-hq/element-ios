//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

class MockSpaceSettingsService: SpaceSettingsServiceProtocol {
    var spaceId: String
    var roomProperties: SpaceSettingsRoomProperties?
    private(set) var displayName: String?
    
    var roomPropertiesSubject: CurrentValueSubject<SpaceSettingsRoomProperties?, Never>
    private(set) var isLoadingSubject: CurrentValueSubject<Bool, Never>
    private(set) var showPostProcessAlert: CurrentValueSubject<Bool, Never>
    private(set) var addressValidationSubject: CurrentValueSubject<SpaceCreationSettingsAddressValidationStatus, Never>

    init(spaceId: String = "!\(UUID().uuidString):matrix.org",
         roomProperties: SpaceSettingsRoomProperties? = nil,
         displayName: String? = nil,
         isLoading: Bool = false,
         showPostProcessAlert: Bool = false) {
        self.spaceId = spaceId
        self.roomProperties = roomProperties
        self.displayName = displayName
        isLoadingSubject = CurrentValueSubject(isLoading)
        self.showPostProcessAlert = CurrentValueSubject(showPostProcessAlert)
        roomPropertiesSubject = CurrentValueSubject(roomProperties)
        addressValidationSubject = CurrentValueSubject(.none(spaceId))
    }

    func update(roomName: String, topic: String, address: String, avatar: UIImage?, completion: ((SpaceSettingsServiceCompletionResult) -> Void)?) { }
    
    func addressDidChange(_ newValue: String) { }
    
    func simulateUpdate(addressValidationStatus: SpaceCreationSettingsAddressValidationStatus) {
        addressValidationSubject.value = addressValidationStatus
    }
    
    func trackSpace() { }
}
