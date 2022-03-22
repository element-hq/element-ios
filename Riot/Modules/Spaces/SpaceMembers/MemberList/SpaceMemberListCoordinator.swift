// File created from ScreenTemplate
// $ createScreen.sh Spaces/SpaceMembers/MemberList ShowSpaceMemberList
/*
 Copyright 2021 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation
import UIKit

final class SpaceMemberListCoordinator: SpaceMemberListCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let spaceId: String
    private var spaceMemberListViewModel: SpaceMemberListViewModelType
    private let spaceMemberListViewController: SpaceMemberListViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: SpaceMemberListCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, spaceId: String) {
        self.session = session
        self.spaceId = spaceId
        
        let spaceMemberListViewModel = SpaceMemberListViewModel(session: self.session, spaceId: self.spaceId)
        let spaceMemberListViewController = SpaceMemberListViewController.instantiate(with: spaceMemberListViewModel)
        self.spaceMemberListViewModel = spaceMemberListViewModel
        self.spaceMemberListViewController = spaceMemberListViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.spaceMemberListViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.spaceMemberListViewController
    }
}

// MARK: - SpaceMemberListViewModelCoordinatorDelegate
extension SpaceMemberListCoordinator: SpaceMemberListViewModelCoordinatorDelegate {

    func spaceMemberListViewModel(_ viewModel: SpaceMemberListViewModelType, didSelect member: MXRoomMember, from sourceView: UIView?) {
        self.delegate?.spaceMemberListCoordinator(self, didSelect: member, from: sourceView)
    }
    
    func spaceMemberListViewModelDidCancel(_ viewModel: SpaceMemberListViewModelType) {
        self.delegate?.spaceMemberListCoordinatorDidCancel(self)
    }
    
    func spaceMemberListViewModelShowInvite(_ viewModel: SpaceMemberListViewModelType) {
        self.delegate?.spaceMemberListCoordinatorShowInvite(self)
    }
}
