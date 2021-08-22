// File created from ScreenTemplate
// $ createScreen.sh Spaces/SpaceMembers/MemberDetail ShowSpaceMemberDetail
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

final class ShowSpaceMemberDetailCoordinator: NSObject, ShowSpaceMemberDetailCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let member: MXRoomMember
    private let spaceId: String
    
    private var showSpaceMemberDetailViewModel: ShowSpaceMemberDetailViewModelType
    private let showSpaceMemberDetailViewController: ShowSpaceMemberDetailViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: ShowSpaceMemberDetailCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, member: MXRoomMember, spaceId: String) {
        self.session = session
        self.member = member
        self.spaceId = spaceId
        
        let showSpaceMemberDetailViewModel = ShowSpaceMemberDetailViewModel(session: self.session, member: self.member)
        let showSpaceMemberDetailViewController = ShowSpaceMemberDetailViewController.instantiate(with: showSpaceMemberDetailViewModel)
        showSpaceMemberDetailViewController.enableMention = true
        showSpaceMemberDetailViewController.enableVoipCall = false
        showSpaceMemberDetailViewController.enableLeave = false

        self.showSpaceMemberDetailViewModel = showSpaceMemberDetailViewModel
        self.showSpaceMemberDetailViewController = showSpaceMemberDetailViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.showSpaceMemberDetailViewModel.coordinatorDelegate = self
        if let space = self.session.spaceService.getSpace(withId: spaceId) {
            // Set delegate to handle action on member (start chat, mention)
            self.showSpaceMemberDetailViewController.delegate = self
            self.showSpaceMemberDetailViewController.display(self.member, withMatrixRoom: space.room)
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.showSpaceMemberDetailViewController
    }
}

// MARK: - ShowSpaceMemberDetailViewModelCoordinatorDelegate
extension ShowSpaceMemberDetailCoordinator: ShowSpaceMemberDetailViewModelCoordinatorDelegate {
    
    func showSpaceMemberDetailViewModel(_ viewModel: ShowSpaceMemberDetailViewModelType, showRoomWithId roomId: String) {
        self.delegate?.showSpaceMemberDetailCoordinator(self, showRoomWithId: roomId)
    }
        
    func showSpaceMemberDetailViewModelDidCancel(_ viewModel: ShowSpaceMemberDetailViewModelType) {
        self.delegate?.showSpaceMemberDetailCoordinatorDidCancel(self)
    }
    
}

// MARK: - MXKRoomMemberDetailsViewControllerDelegate
extension ShowSpaceMemberDetailCoordinator: MXKRoomMemberDetailsViewControllerDelegate {

    func roomMemberDetailsViewController(_ roomMemberDetailsViewController: MXKRoomMemberDetailsViewController!, startChatWithMemberId memberId: String!, completion: (() -> Void)!) {
        completion()
        self.showSpaceMemberDetailViewModel.process(viewAction: .createRoom(memberId))
    }

}
