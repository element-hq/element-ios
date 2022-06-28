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
        self.isLoadingSubject = CurrentValueSubject(isLoading)
        self.showPostProcessAlert = CurrentValueSubject(showPostProcessAlert)
        self.roomPropertiesSubject = CurrentValueSubject(roomProperties)
        self.addressValidationSubject = CurrentValueSubject(.none(spaceId))
    }

    func update(roomName: String, topic: String, address: String, avatar: UIImage?, completion: ((SpaceSettingsServiceCompletionResult) -> Void)?) {
    }
    
    func addressDidChange(_ newValue: String) {
        
    }
    
    func simulateUpdate(addressValidationStatus: SpaceCreationSettingsAddressValidationStatus) {
        self.addressValidationSubject.value = addressValidationStatus
    }
    
    func trackSpace() {
        
    }
}
