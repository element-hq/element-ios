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
import MatrixSDK

@objcMembers
class UserActivityService: NSObject {
    
    // MARK: - Constants
    
    // TODO: Move constants in here from UserActivities.m
    
    // MARK: - Properties
    
    #warning("This is initialised lazily so currently only observes left rooms if RoomViewController has been presented.")
    static let shared = UserActivityService()
    
    // MARK: - Setup
    
    private override init() {
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didLeaveRoom(_:)), name: .mxSessionDidLeaveRoom, object: nil)
    }
    
    // MARK: - Public
    
    func update(_ activity: NSUserActivity, from room: MXRoom) {
        // TODO: Convert objc code into here.
    }
    
    func didLeaveRoom(_ notification: Notification) {
        guard let roomId = notification.userInfo?[kMXSessionNotificationRoomIdKey] as? String else { return }
        // TODO: Remove the room from spotlight
    }
}
