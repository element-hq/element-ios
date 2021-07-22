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

/// View model used by `SpaceMenuViewController`
class SpaceMenuViewModel: SpaceMenuViewModelType {
    
    // MARK: - Enum
    
    enum ActionId: String {
        case members = "members"
        case rooms = "rooms"
        case leave = "leave"
    }
    
    // MARK: - Properties
    
    weak var coordinatorDelegate: SpaceMenuModelViewModelCoordinatorDelegate?
    
    var menuItems: [SpaceMenuListItemViewData] = [
        SpaceMenuListItemViewData(actionId: ActionId.members.rawValue, style: .normal, title: VectorL10n.roomDetailsPeople, icon: UIImage(named: "space_menu_members")),
        SpaceMenuListItemViewData(actionId: ActionId.rooms.rawValue, style: .normal, title: VectorL10n.groupDetailsRooms, icon: UIImage(named: "space_menu_rooms")),
        SpaceMenuListItemViewData(actionId: ActionId.leave.rawValue, style: .destructive, title: VectorL10n.leave, icon: UIImage(named: "space_menu_leave"))
    ]
    
    // MARK: - Public

    func process(viewAction: SpaceMenuViewAction) {
        switch viewAction {
        case .dismiss:
            self.coordinatorDelegate?.spaceListViewModelDidDismiss(self)
        case .selectRow(at: let indexPath):
            self.coordinatorDelegate?.spaceListViewModel(self, didSelectItemWithId: menuItems[indexPath.row].actionId)
        }
    }
}
