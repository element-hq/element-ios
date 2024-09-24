// File created from ScreenTemplate
// $ createScreen.sh Spaces/SpaceMembers/MemberDetail ShowSpaceMemberDetail
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation
import UIKit

struct SpaceMemberDetailCoordinatorParameters {
    let userSessionsService: UserSessionsService
    let member: MXRoomMember
    let session: MXSession
    let spaceId: String
    let showCancelMenuItem: Bool
}

final class SpaceMemberDetailCoordinator: NSObject, SpaceMemberDetailCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: SpaceMemberDetailCoordinatorParameters
    
    private var spaceMemberDetailViewModel: SpaceMemberDetailViewModelType
    private let spaceMemberDetailViewController: SpaceMemberDetailViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: SpaceMemberDetailCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(parameters: SpaceMemberDetailCoordinatorParameters) {
        self.parameters = parameters
        
        let spaceMemberDetailViewModel = SpaceMemberDetailViewModel(userSessionsService: parameters.userSessionsService,
                                                                    session: parameters.session,
                                                                    member: parameters.member,
                                                                    spaceId: parameters.spaceId,
                                                                    showCancelMenuItem: parameters.showCancelMenuItem)
        let spaceMemberDetailViewController = SpaceMemberDetailViewController.instantiate(with: spaceMemberDetailViewModel)
        spaceMemberDetailViewController.enableMention = true
        spaceMemberDetailViewController.enableVoipCall = false
        spaceMemberDetailViewController.enableLeave = false

        self.spaceMemberDetailViewModel = spaceMemberDetailViewModel
        self.spaceMemberDetailViewController = spaceMemberDetailViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.spaceMemberDetailViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.spaceMemberDetailViewController
    }
}

// MARK: - SpaceMemberDetailViewModelCoordinatorDelegate
extension SpaceMemberDetailCoordinator: SpaceMemberDetailViewModelCoordinatorDelegate {
    
    func spaceMemberDetailViewModel(_ viewModel: SpaceMemberDetailViewModelType, showRoomWithId roomId: String) {
        self.delegate?.spaceMemberDetailCoordinator(self, showRoomWithId: roomId)
    }
        
    func spaceMemberDetailViewModelDidCancel(_ viewModel: SpaceMemberDetailViewModelType) {
        self.delegate?.spaceMemberDetailCoordinatorDidCancel(self)
    }
    
}

// MARK: - MXKRoomMemberDetailsViewControllerDelegate
extension SpaceMemberDetailCoordinator: MXKRoomMemberDetailsViewControllerDelegate {

    func roomMemberDetailsViewController(_ roomMemberDetailsViewController: MXKRoomMemberDetailsViewController!, startChatWithMemberId memberId: String!, completion: (() -> Void)!) {
        completion()
        self.spaceMemberDetailViewModel.process(viewAction: .createRoom(memberId))
    }

}
