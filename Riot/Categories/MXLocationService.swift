// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixSDK

extension MXLocationService {
    
    public func isSomeoneSharingDisplayableLocation(inRoomWithId roomId: String) -> Bool {
        return self.getDisplayableBeaconInfoSummaries(inRoomWithId: roomId).isEmpty == false
    }
    
    /// Get beacon info summaries that can be shown on a map
    func getDisplayableBeaconInfoSummaries(inRoomWithId roomId: String) -> [MXBeaconInfoSummaryProtocol] {
        
        let liveBeaconInfoSummaries = self.getLiveBeaconInfoSummaries(inRoomWithId: roomId)
        
        return liveBeaconInfoSummaries.filter { beaconInfoSummary in
            return beaconInfoSummary.isDisplayable
        }
    }
}
