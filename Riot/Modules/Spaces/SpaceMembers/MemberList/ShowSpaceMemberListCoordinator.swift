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

final class ShowSpaceMemberListCoordinator: ShowSpaceMemberListCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let spaceId: String
    private var showSpaceMemberListViewModel: ShowSpaceMemberListViewModelType
    private let showSpaceMemberListViewController: ShowSpaceMemberListViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: ShowSpaceMemberListCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, spaceId: String) {
        self.session = session
        self.spaceId = spaceId
        
        let showSpaceMemberListViewModel = ShowSpaceMemberListViewModel(session: self.session, spaceId: self.spaceId)
        let showSpaceMemberListViewController = ShowSpaceMemberListViewController.instantiate(with: showSpaceMemberListViewModel)
        self.showSpaceMemberListViewModel = showSpaceMemberListViewModel
        self.showSpaceMemberListViewController = showSpaceMemberListViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.showSpaceMemberListViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.showSpaceMemberListViewController
    }
}

// MARK: - ShowSpaceMemberListViewModelCoordinatorDelegate
extension ShowSpaceMemberListCoordinator: ShowSpaceMemberListViewModelCoordinatorDelegate {

    func showSpaceMemberListViewModel(_ viewModel: ShowSpaceMemberListViewModelType, didSelect member: MXRoomMember, from sourceView: UIView?) {
        self.delegate?.showSpaceMemberListCoordinator(self, didSelect: member, from: sourceView)
    }
    
    func showSpaceMemberListViewModelDidCancel(_ viewModel: ShowSpaceMemberListViewModelType) {
        self.delegate?.showSpaceMemberListCoordinatorDidCancel(self)
    }
}
