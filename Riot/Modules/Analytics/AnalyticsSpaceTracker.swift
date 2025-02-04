// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

class AnalyticsSpaceTracker {
    
    // MARK: - Setup
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.spaceGraphDidUpdate(notification:)), name: MXSpaceService.didBuildSpaceGraph, object: nil)
    }
    
    @objc private func spaceGraphDidUpdate(notification: Notification) {
        guard let spaceService = notification.object as? MXSpaceService else {
            return
        }
        
        trackSpaceNumber(with: spaceService)
    }
    
    // MARK: - Private
    
    private func trackSpaceNumber(with spaceService: MXSpaceService) {
        let spaceNumber = spaceService.spaceSummaries.filter { $0.membership == .join }.count
        
        guard RiotSettings.shared.lastNumberOfTrackedSpaces != spaceNumber else {
            return
        }
        
        Analytics.shared.updateUserProperties(numSpaces: spaceNumber)
        RiotSettings.shared.lastNumberOfTrackedSpaces = spaceNumber
    }
}
