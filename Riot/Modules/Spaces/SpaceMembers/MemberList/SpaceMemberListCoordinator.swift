// File created from ScreenTemplate
// $ createScreen.sh Spaces/SpaceMembers/MemberList ShowSpaceMemberList
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
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
