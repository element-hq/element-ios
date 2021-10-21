// 
// Copyright 2020 New Vector Ltd
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

extension RecentsViewController {
    
    @objc
    func canShowRoomPreview(for summary: MXRoomSummaryProtocol) -> Bool {
        let membershipTransitionState = summary.membershipTransitionState
        
        // NOTE: For the moment do not offer the possibility to show room preview when invitation action is in progress
        
        switch membershipTransitionState {
        case .failedJoining, .failedLeaving:
            return false
        default:
            return true
        }
    }
}
