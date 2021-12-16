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

import UIKit

/// An object to record how long a screen has been presented for and
/// report the screen's display to the `Analytics` object.
@objcMembers class AnalyticsScreenTimer: NSObject {
    
    // MARK: - Properties
    
    /// The screen being tracked.
    private let screen: AnalyticsScreen
    
    /// The date that the screen was presented to the user.
    private var startDate: Date?
    /// Whether the app was backgrounded whilst the screen was being presented.
    private var didPause = false
    
    /// The duration in milliseconds that the screen has been shown for. The value will
    /// be reported as `nil` if the timer isn't running, or if the app was backgrounded
    /// during the screen's display.
    private var duration: Int? {
        guard let startDate = startDate else {
            MXLog.warning("[AnalyticsScreenTimer] Duration requested on a stopped timer!")
            return nil
        }
        
        // Consider the duration invalid if the app has been backgrounded
        guard !didPause else { return nil }
        
        let timeInterval = Date().timeIntervalSince(startDate)
        return Int(timeInterval * 1000)
    }
    
    // MARK: - Setup
    
    /// Create a new screen timer for the specified screen.
    /// - Parameter screen: The screen that should be timed.
    init(screen: AnalyticsScreen) {
        self.screen = screen
        
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(pause), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    // MARK: - Public
    
    /// Start the timer.
    func start() {
        startDate = Date()
    }
    
    /// Stop the timer and report the screen to `Analytics`.
    func stop() {
        guard let duration = duration else { return }
        
        Analytics.shared.trackScreen(screen, duration: duration)
        self.startDate = nil
    }
    
    // MARK: - Private
    
    /// Record that the timer has been interrupted by the app moving to the background.
    @objc private func pause() {
        didPause = true
    }
}
