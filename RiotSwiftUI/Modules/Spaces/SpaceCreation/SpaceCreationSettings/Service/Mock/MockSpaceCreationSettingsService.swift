// File created from TemplateAdvancedRoomsExample
// $ createSwiftUITwoScreen.sh Spaces/SpaceCreation SpaceCreation SpaceCreationMenu SpaceCreationSettings
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

import Combine
import Foundation

class MockSpaceCreationSettingsService: SpaceCreationSettingsServiceProtocol {
    var addressValidationSubject: CurrentValueSubject<SpaceCreationSettingsAddressValidationStatus, Never>
    var avatarViewDataSubject: CurrentValueSubject<AvatarInputProtocol, Never>
    var defaultAddressSubject: CurrentValueSubject<String, Never>
    var spaceAddress: String?
    var roomName: String
    var userDefinedAddress: String?
    var isAddressValid = true

    init() {
        roomName = "Fake"
        defaultAddressSubject = CurrentValueSubject("fake-uri")
        addressValidationSubject = CurrentValueSubject(.none("#fake-uri:fake-domain.org"))
        avatarViewDataSubject = CurrentValueSubject(AvatarInput(mxContentUri: defaultAddressSubject.value, matrixItemId: "", displayName: roomName))
    }
    
    func simulateUpdate(addressValidationStatus: SpaceCreationSettingsAddressValidationStatus) {
        addressValidationSubject.value = addressValidationStatus
    }
    
//    func simulateUpdate()
}
