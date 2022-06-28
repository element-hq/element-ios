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
