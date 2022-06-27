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
import UIKit
import SwiftUI

protocol UserSuggestionCoordinatorDelegate: AnyObject {
    func userSuggestionCoordinator(_ coordinator: UserSuggestionCoordinator, didRequestMentionForMember member: MXRoomMember, textTrigger: String?)
}

struct UserSuggestionCoordinatorParameters {
    let mediaManager: MXMediaManager
    let room: MXRoom
}

final class UserSuggestionCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: UserSuggestionCoordinatorParameters
    
    private var userSuggestionHostingController: UIViewController
    private var userSuggestionService: UserSuggestionServiceProtocol
    private var userSuggestionViewModel: UserSuggestionViewModelProtocol
    private var roomMemberProvider: UserSuggestionCoordinatorRoomMemberProvider
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: (() -> Void)?
    
    weak var delegate: UserSuggestionCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(parameters: UserSuggestionCoordinatorParameters) {
        self.parameters = parameters
        
        roomMemberProvider = UserSuggestionCoordinatorRoomMemberProvider(room: parameters.room)
        userSuggestionService = UserSuggestionService(roomMemberProvider: roomMemberProvider)
        
        let viewModel = UserSuggestionViewModel(userSuggestionService: userSuggestionService)
        let view = UserSuggestionList(viewModel: viewModel.context)
            .addDependency(AvatarService.instantiate(mediaManager: parameters.mediaManager))
        
        userSuggestionViewModel = viewModel
        userSuggestionHostingController = VectorHostingController(rootView: view)
        
        userSuggestionViewModel.completion = { [weak self] result in
            guard let self = self else {
                return
            }
            
            switch result {
            case .selectedItemWithIdentifier(let identifier):
                guard let member = self.roomMemberProvider.roomMembers.filter({ $0.userId == identifier }).first else {
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

private class UserSuggestionCoordinatorRoomMemberProvider: RoomMembersProviderProtocol {
    
    private let room: MXRoom
    
    var roomMembers: [MXRoomMember] = []
    
    init(room: MXRoom) {
        self.room = room;
    }
    
    func fetchMembers(_ members: @escaping ([RoomMembersProviderMember]) -> Void) {
        room.members({ [weak self] roomMembers in
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
            MXLog.error("[UserSuggestionCoordinatorRoomMemberProvider] Failed loading room with error: \(String(describing: error))")
        })
    }
    
    private func roomMembersToProviderMembers(_ roomMembers: [MXRoomMember]) -> [RoomMembersProviderMember] {
        roomMembers.map { RoomMembersProviderMember(userId: $0.userId, displayName: $0.displayname ?? "", avatarUrl: $0.avatarUrl ?? "") }
    }
}
