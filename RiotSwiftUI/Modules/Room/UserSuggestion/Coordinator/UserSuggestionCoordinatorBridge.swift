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
    func userSuggestionCoordinatorBridge(_ coordinator: UserSuggestionCoordinatorBridge, didUpdateViewHeight height: CGFloat)
}

@objcMembers
final class UserSuggestionCoordinatorBridge: NSObject {
    
    private var _userSuggestionCoordinator: Any? = nil
    fileprivate var userSuggestionCoordinator: UserSuggestionCoordinator {
        return _userSuggestionCoordinator as! UserSuggestionCoordinator
    }
    
    weak var delegate: UserSuggestionCoordinatorBridgeDelegate?
    
    init(mediaManager: MXMediaManager, room: MXRoom) {
        let parameters = UserSuggestionCoordinatorParameters(mediaManager: mediaManager, room: room)
        let userSuggestionCoordinator = UserSuggestionCoordinator(parameters: parameters)
        self._userSuggestionCoordinator = userSuggestionCoordinator
        
        super.init()
        
        userSuggestionCoordinator.delegate = self
    }
    
    func processTextMessage(_ textMessage: String) {
        return self.userSuggestionCoordinator.processTextMessage(textMessage)
    }
    
    func toPresentable() -> UIViewController? {
        return self.userSuggestionCoordinator.toPresentable()
    }
}

extension UserSuggestionCoordinatorBridge: UserSuggestionCoordinatorDelegate {
    func userSuggestionCoordinator(_ coordinator: UserSuggestionCoordinator, didRequestMentionForMember member: MXRoomMember, textTrigger: String?) {
        delegate?.userSuggestionCoordinatorBridge(self, didRequestMentionForMember: member, textTrigger: textTrigger)
    }

    func userSuggestionCoordinator(_ coordinator: UserSuggestionCoordinator, didUpdateViewHeight height: CGFloat) {
        delegate?.userSuggestionCoordinatorBridge(self, didUpdateViewHeight: height)
    }
}
