// File created from SimpleUserProfileExample
// $ createScreen.sh Room/UserSuggestion UserSuggestion
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
import SwiftUI

@available(iOS 14.0, *)
protocol UserSuggestionCoordinatorDelegate: AnyObject {
    func userSuggestionCoordinator(_ coordinator: UserSuggestionCoordinator, didRequestMentionForMember member: MXRoomMember, textTrigger: String?)
}

@available(iOS 14.0, *)
final class UserSuggestionCoordinator: Coordinator {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: UserSuggestionCoordinatorParameters
    
    private var userSuggestionHostingController: UIViewController!
    private var userSuggestionService: UserSuggestionServiceProtocol!
    private var userSuggestionViewModel: UserSuggestionViewModelProtocol!
    
    private var roomMembers: [MXRoomMember] = []
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: (() -> Void)?
    
    weak var delegate: UserSuggestionCoordinatorDelegate?
    
    // MARK: - Setup
    
    @available(iOS 14.0, *)
    init(parameters: UserSuggestionCoordinatorParameters) {
        self.parameters = parameters
        
        userSuggestionService = UserSuggestionService(roomMembersProvider: self)
        userSuggestionViewModel = UserSuggestionViewModel.makeUserSuggestionViewModel(userSuggestionService: userSuggestionService)

        let view = UserSuggestionList(viewModel: userSuggestionViewModel.context)
            .addDependency(AvatarService.instantiate(mediaManager: parameters.mediaManager))
        
        userSuggestionHostingController = VectorHostingController(rootView: view)
        
        userSuggestionViewModel.completion = { [weak self] result in
            guard let self = self else {
                return
            }
            
            switch result {
            case .selectedItemWithIdentifier(let identifier):
                guard let member = self.roomMembers.filter({ $0.userId == identifier }).first else {
                    return
                }
                
                self.delegate?.userSuggestionCoordinator(self, didRequestMentionForMember: member, textTrigger: self.userSuggestionService.currentTextTrigger)
            }
        }
    }
    
    func processTextMessage(_ textMessage: String) {
        userSuggestionService.processTextMessage(textMessage)
    }
    
    // MARK: - Public
    func start() {
        
    }
    
    func toPresentable() -> UIViewController {
        return self.userSuggestionHostingController
    }
}

@available(iOS 14.0, *)
extension UserSuggestionCoordinator: RoomMembersProviderProtocol {
    func fetchMembers(_ members: @escaping ([RoomMembersProviderMember]) -> Void) {
        parameters.room.members({ [weak self] roomMembers in
            guard let self = self, let joinedMembers = roomMembers?.joinedMembers else {
                return
            }
            self.roomMembers = joinedMembers
            members(self.roomMembersToProviderMembers(joinedMembers))
        }, lazyLoadedMembers: { [weak self] lazyRoomMembers in
            guard let self = self, let joinedMembers = lazyRoomMembers?.joinedMembers else {
                return
            }
            self.roomMembers = joinedMembers
            members(self.roomMembersToProviderMembers(joinedMembers))
        }, failure: { error in
            MXLog.error("[UserSuggestionCoordinator] Failed loading room with error: \(String(describing: error))")
        })
    }
    
    private func roomMembersToProviderMembers(_ roomMembers: [MXRoomMember]) -> [RoomMembersProviderMember] {
        roomMembers.map { RoomMembersProviderMember(userId: $0.userId, displayName: $0.displayname ?? "", avatarUrl: $0.avatarUrl ?? "") }
    }
}
