// 
// Copyright 2022 New Vector Ltd
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

/// UserVoiceBroadcastServiceProvider to setup UserVoiceBroadcastService and retrieve the existing UserVoiceBroadcastService.
class UserVoiceBroadcastServiceProvider {
    
    // MARK: - Constants
    
    static let shared = UserVoiceBroadcastServiceProvider()
    
    // MARK: - Properties
    
    // UserVoiceBroadcastService per session
    public var userVoiceBroadcastService: UserVoiceBroadcastService? = nil
    
    // MARK: - Setup
    
    private init() {}
    
    // MARK: - Public
    
    public func setupUserVoiceBroadcastServiceIfNeeded(for room: MXRoom) {
        
        guard self.userVoiceBroadcastService == nil else {
            return
        }
        
        self.setupUserVoiceBroadcastService(for: room)
    }
    
    public func tearDownUserVoiceBroadcastService() {
                
        self.userVoiceBroadcastService = nil

        MXLog.debug("Stop monitoring voice broadcast recording")
    }
    
    // MARK: - Private
    
    // MARK: UserVoiceBroadcastService setup
    
    private func setupUserVoiceBroadcastService(for room: MXRoom) {
                
        let userVoiceBroadcastService = UserVoiceBroadcastService(room: room)
        
        self.userVoiceBroadcastService = userVoiceBroadcastService
        
        MXLog.debug("Start monitoring voice broadcast recording")
    }
    
}
