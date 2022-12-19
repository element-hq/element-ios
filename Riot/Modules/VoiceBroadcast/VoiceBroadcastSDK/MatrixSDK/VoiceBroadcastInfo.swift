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

extension VoiceBroadcastInfo {
    // MARK: - Constants
    
    // MARK: - Public
    
    @objc static func isStarted(for name: String) -> Bool {
        return name == VoiceBroadcastInfoState.started.rawValue
    }
    
    @objc static func isStopped(for name: String) -> Bool {
        return name == VoiceBroadcastInfoState.stopped.rawValue
    }
    
    @objc static func startedValue() -> String {
        return VoiceBroadcastInfoState.started.rawValue
    }
    
    @objc static func pausedValue() -> String {
        return VoiceBroadcastInfoState.paused.rawValue
    }
    
    @objc static func resumedValue() -> String {
        return VoiceBroadcastInfoState.resumed.rawValue
    }
    
    @objc static func stoppedValue() -> String {
        return VoiceBroadcastInfoState.stopped.rawValue
    }
}
