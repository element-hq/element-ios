// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
