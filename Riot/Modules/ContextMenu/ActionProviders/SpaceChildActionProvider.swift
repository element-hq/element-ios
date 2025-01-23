// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// `SpaceChildActionProvider` provides the menu for `MXSpaceChildInfo` instances
@available(iOS 13.0, *)
class SpaceChildActionProvider: RoomActionProviderProtocol {

    // MARK: - Properties
    
    private let spaceChildInfo: MXSpaceChildInfo
    private let service: UnownedRoomContextActionService

    // MARK: - Setup
    
    init(spaceChildInfo: MXSpaceChildInfo, service: UnownedRoomContextActionService) {
        self.spaceChildInfo = spaceChildInfo
        self.service = service
    }
    
    // MARK: - RoomActionProviderProtocol
    
    var menu: UIMenu {
        return UIMenu(children: [
            self.joinAction
        ])
    }
    
    // MARK: - Private
    
    private var joinAction: UIAction {
        return UIAction(
            title: VectorL10n.join) { [weak self] action in
                self?.service.joinRoom()
        }
    }
}
