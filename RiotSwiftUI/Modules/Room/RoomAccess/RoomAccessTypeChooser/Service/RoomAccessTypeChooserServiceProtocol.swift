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
