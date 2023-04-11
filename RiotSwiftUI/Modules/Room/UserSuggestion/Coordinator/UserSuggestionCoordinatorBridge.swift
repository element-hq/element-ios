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

@objc
protocol UserSuggestionCoordinatorBridgeDelegate: AnyObject {
    func userSuggestionCoordinatorBridge(_ coordinator: UserSuggestionCoordinatorBridge, didRequestMentionForMember member: MXRoomMember, textTrigger: String?)
    func userSuggestionCoordinatorBridgeDidRequestMentionForRoom(_ coordinator: UserSuggestionCoordinatorBridge, textTrigger: String?)
    func userSuggestionCoordinatorBridge(_ coordinator: UserSuggestionCoordinatorBridge, didUpdateViewHeight height: CGFloat)
}

@objcMembers
final class UserSuggestionCoordinatorBridge: NSObject {
    private var _userSuggestionCoordinator: Any?
    fileprivate var userSuggestionCoordinator: UserSuggestionCoordinator {
        _userSuggestionCoordinator as! UserSuggestionCoordinator
    }
    
    weak var delegate: UserSuggestionCoordinatorBridgeDelegate?
    
    init(mediaManager: MXMediaManager, room: MXRoom, userID: String) {
        let parameters = UserSuggestionCoordinatorParameters(mediaManager: mediaManager, room: room, userID: userID)
        let userSuggestionCoordinator = UserSuggestionCoordinator(parameters: parameters)
        _userSuggestionCoordinator = userSuggestionCoordinator
        
        super.init()
        
        userSuggestionCoordinator.delegate = self
    }
    
    func processTextMessage(_ textMessage: String) {
        userSuggestionCoordinator.processTextMessage(textMessage)
    }

    func processSuggestionPattern(_ suggestionPatternWrapper: SuggestionPatternWrapper) {
        userSuggestionCoordinator.processSuggestionPattern(suggestionPatternWrapper.suggestionPattern)
    }
    
    func toPresentable() -> UIViewController? {
        userSuggestionCoordinator.toPresentable()
    }

    func sharedContext() -> UserSuggestionViewModelContextWrapper {
        userSuggestionCoordinator.sharedContext()
    }
}

extension UserSuggestionCoordinatorBridge: UserSuggestionCoordinatorDelegate {
    func userSuggestionCoordinator(_ coordinator: UserSuggestionCoordinator, didRequestMentionForMember member: MXRoomMember, textTrigger: String?) {
        delegate?.userSuggestionCoordinatorBridge(self, didRequestMentionForMember: member, textTrigger: textTrigger)
    }
    
    func userSuggestionCoordinatorDidRequestMentionForRoom(_ coordinator: UserSuggestionCoordinator, textTrigger: String?) {
        delegate?.userSuggestionCoordinatorBridgeDidRequestMentionForRoom(self, textTrigger: textTrigger)
    }

    func userSuggestionCoordinator(_ coordinator: UserSuggestionCoordinator, didUpdateViewHeight height: CGFloat) {
        delegate?.userSuggestionCoordinatorBridge(self, didUpdateViewHeight: height)
    }
}
