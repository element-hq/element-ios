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
    
    // MARK: - Properties
    
    weak var coordinatorDelegate: SpaceMenuModelViewModelCoordinatorDelegate?
    weak var viewDelegate: SpaceMenuViewModelViewDelegate?

    private let spaceMenuItems: [SpaceMenuListItemViewData] = [
        SpaceMenuListItemViewData(action: .invite, style: .normal, title: VectorL10n.spacesInvitePeople, icon: Asset.Images.spaceInviteUser.image, value: nil),
        SpaceMenuListItemViewData(action: .exploreSpaceRooms, style: .normal, title: VectorL10n.spacesExploreRooms, icon: Asset.Images.spaceMenuRooms.image, value: nil),
        SpaceMenuListItemViewData(action: .exploreSpaceMembers, style: .normal, title: VectorL10n.roomDetailsPeople, icon: Asset.Images.spaceMenuMembers.image, value: nil),
        SpaceMenuListItemViewData(action: .settings, style: .normal, title: VectorL10n.sideMenuActionSettings, icon: Asset.Images.sideMenuActionIconSettings.image, value: nil),
        SpaceMenuListItemViewData(action: .addRoom, style: .normal, title: VectorL10n.spacesAddRoom, icon: Asset.Images.spaceMenuPlusIcon.image, value: nil),
        SpaceMenuListItemViewData(action: .addSpace, style: .normal, title: VectorL10n.spacesAddSpace, icon: Asset.Images.spaceMenuPlusIcon.image, value: nil, isBeta: true),
        SpaceMenuListItemViewData(action: .leaveSpace, style: .destructive, title: VectorL10n.leave, icon: Asset.Images.spaceMenuLeave.image, value: nil)
    ]
    
    var menuItems: [SpaceMenuListItemViewData] = []
    
    private let session: MXSession
    private let spaceId: String
    
    // MARK: - Setup
    
    init(session: MXSession, spaceId: String) {
        self.session = session
        self.spaceId = spaceId
        
        if spaceId != SpaceListViewModel.Constants.homeSpaceId {
            self.menuItems = spaceMenuItems
        } else {
            self.menuItems = [
                SpaceMenuListItemViewData(action: .showAllRoomsInHomeSpace, style: .toggle, title: VectorL10n.spaceHomeShowAllRooms, icon: nil, value: RiotSettings.shared.showAllRoomsInHomeSpace)
            ]
        }
    }
    
    // MARK: - Public

    func process(viewAction: SpaceMenuViewAction) {
        switch viewAction {
        case .dismiss:
            self.coordinatorDelegate?.spaceMenuViewModelDidDismiss(self)
        case .selectRow(at: let indexPath):
            self.processAction(with: menuItems[indexPath.row].action, at: indexPath)
        case .leaveSpaceAndKeepRooms:
            self.leaveSpaceAndKeepRooms()
        case .leaveSpaceAndLeaveRooms:
            self.leaveSpaceAndLeaveAllRooms()
        }
    }
    
    // MARK: - Private
    
    private func processAction(with action: SpaceMenuListItemAction, at indexPath: IndexPath) {
        switch action {
        case .showAllRoomsInHomeSpace:
            RiotSettings.shared.showAllRoomsInHomeSpace.toggle()
            self.menuItems[indexPath.row].value = RiotSettings.shared.showAllRoomsInHomeSpace
            self.viewDelegate?.spaceMenuViewModel(self, didUpdateViewState: .deselect)
        case .leaveSpace:
            self.leaveSpace()
        default:
            self.coordinatorDelegate?.spaceMenuViewModel(self, didSelectItemWith: action)
        }
    }

    private func leaveSpace() {
        self.viewDelegate?.spaceMenuViewModel(self, didUpdateViewState: .deselect)
        self.coordinatorDelegate?.spaceMenuViewModel(self, didSelectItemWith: .leaveSpaceAndChooseRooms)
    }
    
    private func leaveSpaceAndKeepRooms() {
        guard let space = self.session.spaceService.getSpace(withId: self.spaceId) else {
            return
        }

        self.viewDelegate?.spaceMenuViewModel(self, didUpdateViewState: .loading)
        self.leaveSpace(space)
    }
    
    private func leaveSpaceAndLeaveAllRooms() {
        guard let space = self.session.spaceService.getSpace(withId: self.spaceId) else {
            return
        }

        self.viewDelegate?.spaceMenuViewModel(self, didUpdateViewState: .loading)
        
        let allRoomsAndSpaces = space.childRoomIds + space.childSpaces.map({ space in
            space.spaceId
        })

        self.leaveAllRooms(from: allRoomsAndSpaces, at: 0) { [weak self] error in
            guard let self = self else {
                return
            }
            
            if let error = error {
                self.viewDelegate?.spaceMenuViewModel(self, didUpdateViewState: .loaded)
                self.viewDelegate?.spaceMenuViewModel(self, didUpdateViewState: .error(error))
                return
            }

            self.leaveSpace(space)
        }
    }

    private func leaveAllRooms(from roomIds: [String], at index: Int, completion: @escaping (_ error: Error?) -> Void) {
        guard index < roomIds.count, let room = self.session.room(withRoomId: roomIds[index]), !room.isDirect else {
            let nextIndex = index+1
            if nextIndex < roomIds.count {
                self.leaveAllRooms(from: roomIds, at: nextIndex, completion: completion)
            } else {
                completion(nil)
            }
            return
        }
        
        room.leave { [weak self] response in
            guard let self = self else {
                return
            }

            guard response.isSuccess else {
                completion(response.error)
                return
            }
            
            let nextIndex = index+1
            if nextIndex < roomIds.count {
                self.leaveAllRooms(from: roomIds, at: nextIndex, completion: completion)
            } else {
                completion(nil)
            }
        }
    }
    
    private func leaveSpace(_ space: MXSpace) {
        space.room?.leave(completion: { [weak self] response in
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
    }
}
