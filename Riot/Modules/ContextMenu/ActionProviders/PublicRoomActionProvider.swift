//
// Copyright 2022 New Vector Ltd
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

/// `PublicRoomActionProvider` provides the menu for `MXPUblicRoom` instances
@available(iOS 13.0, *)
class PublicRoomActionProvider: RoomActionProviderProtocol {
    // MARK: - Properties
    
    private let publicRoom: MXPublicRoom
    private let service: UnownedRoomContextActionService
    
    // MARK: - Setup
    
    init(publicRoom: MXPublicRoom, service: UnownedRoomContextActionService) {
        self.publicRoom = publicRoom
        self.service = service
    }
    
    // MARK: - RoomActionProviderProtocol
    
    var menu: UIMenu {
        UIMenu(children: [
            joinAction
        ])
    }
    
    // MARK: - Private
    
    private var joinAction: UIAction {
        UIAction(
            title: VectorL10n.join) { [weak self] _ in
                self?.service.joinRoom()
            }
    }
}
