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
