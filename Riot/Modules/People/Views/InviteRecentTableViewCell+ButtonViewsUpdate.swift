// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
