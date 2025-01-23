// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// An object to report the screen's display to the `Analytics` object.
@objcMembers class AnalyticsScreenTracker: NSObject {
    
    // MARK: - Properties
    
    /// The screen being tracked.
    private let screen: AnalyticsScreen

    // MARK: - Setup
    
    /// Create a new screen tracker for the specified screen.
    /// - Parameter screen: The screen that should be reported.
    init(screen: AnalyticsScreen) {
        self.screen = screen
        super.init()
    }
    
    // MARK: - Public
    
    /// Send screen event without duration
    func trackScreen() {
        Analytics.shared.trackScreen(screen)
    }
    
    // MARK: static method
    
    static func trackScreen(_ screen: AnalyticsScreen) {
        Analytics.shared.trackScreen(screen)
    }
    
}
