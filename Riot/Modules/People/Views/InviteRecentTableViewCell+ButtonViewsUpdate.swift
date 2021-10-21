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

extension InviteRecentTableViewCell {
    
    @objc func resetButtonViews() {
        self.leftButton.isEnabled = true
        self.rightButton.isEnabled = true        
        self.leftButtonActivityIndicator.stopAnimating()
        self.rightButtonActivityIndicator.stopAnimating()
    }
    
    /// Update buttons according to current MXMembershipChangeState of the room
    @objc func updateButtonViews(with summary: MXRoomSummaryProtocol) {
        let membershipTransitionState = summary.membershipTransitionState
        
        var joinButtonIsLoading = false
        var leaveButtonIsLoading = false
        
        switch membershipTransitionState {
        case .joining:
            joinButtonIsLoading = true
        case .leaving:
            leaveButtonIsLoading = true
        default:
            break
        }
        
        let areButtonsEnabled = !(joinButtonIsLoading || leaveButtonIsLoading)
        
        self.leftButton.isEnabled = areButtonsEnabled
        self.rightButton.isEnabled = areButtonsEnabled
        
        if leaveButtonIsLoading {
            self.leftButtonActivityIndicator.startAnimating()
        } else {
            self.leftButtonActivityIndicator.stopAnimating()
        }
        
        if joinButtonIsLoading {
            self.rightButtonActivityIndicator.startAnimating()
        } else {
            self.rightButtonActivityIndicator.stopAnimating()
        }
    }
}
