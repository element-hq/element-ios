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

@objcMembers
final class UserSuggestionCoordinatorBridge: NSObject {
    
    private var _userSuggestionCoordinator: Any? = nil
    @available(iOS 14.0, *)
    fileprivate var userSuggestionCoordinator: UserSuggestionCoordinator {
        return _userSuggestionCoordinator as! UserSuggestionCoordinator
    }
    
    init(mediaManager: MXMediaManager, room: MXRoom) {
        let parameters = UserSuggestionCoordinatorParameters(mediaManager: mediaManager, room: room)
        if #available(iOS 14.0, *) {
            self._userSuggestionCoordinator = UserSuggestionCoordinator(parameters: parameters)
        }
    }
    
    func processPartialUserName(_ userName: String) {
        if #available(iOS 14.0, *) {
            return self.userSuggestionCoordinator.processPartialUserName(userName)
        }
    }
    
    func toPresentable() -> UIViewController? {
        if #available(iOS 14.0, *) {
            return self.userSuggestionCoordinator.toPresentable()
        }
        
        return nil
    }
}
