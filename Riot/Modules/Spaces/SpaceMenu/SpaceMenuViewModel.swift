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
    weak var viewDelegate: SpaceMenuViewModelViewDelegate?

    var menuItems: [SpaceMenuListItemViewData] = [
        SpaceMenuListItemViewData(actionId: ActionId.members.rawValue, style: .normal, title: VectorL10n.roomDetailsPeople, icon: UIImage(named: "space_menu_members")),
        SpaceMenuListItemViewData(actionId: ActionId.rooms.rawValue, style: .normal, title: VectorL10n.groupDetailsRooms, icon: UIImage(named: "space_menu_rooms")),
        SpaceMenuListItemViewData(actionId: ActionId.leave.rawValue, style: .destructive, title: VectorL10n.leave, icon: UIImage(named: "space_menu_leave"))
    ]
    
    private let session: MXSession
    private let spaceId: String
    
    // MARK: - Setup
    
    init(session: MXSession, spaceId: String) {
        self.session = session
        self.spaceId = spaceId
    }
    
    // MARK: - Public

    func process(viewAction: SpaceMenuViewAction) {
        switch viewAction {
        case .dismiss:
            self.coordinatorDelegate?.spaceMenuViewModelDidDismiss(self)
        case .selectRow(at: let indexPath):
            self.processAction(with: menuItems[indexPath.row].actionId)
        }
    }
    
    // MARK: - Private
    
    private func processAction(with actionStringId: String) {
        let actionId = ActionId(rawValue: actionStringId)
        switch actionId {
        case .leave:
            self.leaveSpace()
        default:
            self.coordinatorDelegate?.spaceMenuViewModel(self, didSelectItemWithId: actionStringId)
        }
    }

    private func leaveSpace() {
        guard let space = self.session.spaceService.getSpace(withId: self.spaceId), let displayName = space.summary?.displayname else {
            return
        }
        
        let alert = UIAlertController(title: nil, message: VectorL10n.leaveSpaceMessage(displayName), preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: VectorL10n.leave, style: .destructive, handler: { [weak self] action in
            guard let self = self else {
                return
            }

            self.viewDelegate?.spaceMenuViewModel(self, didUpdateViewState: .loading)
            
            space.room.leave(completion: { [weak self] response in
                guard let self = self else {
                    return
                }
                
                self.viewDelegate?.spaceMenuViewModel(self, didUpdateViewState: .loaded)

                if let error = response.error {
                    self.viewDelegate?.spaceMenuViewModel(self, didUpdateViewState: .error(error))
                } else {
                    self.process(viewAction: .dismiss)
                }
            })
        }))
        alert.addAction(UIAlertAction(title: VectorL10n.cancel, style: .cancel, handler: { [weak self] action in
            guard let self = self else {
                return
            }

            self.viewDelegate?.spaceMenuViewModel(self, didUpdateViewState: .deselect)
        }))

        self.viewDelegate?.spaceMenuViewModel(self, didUpdateViewState: .alert(alert))
    }
}
