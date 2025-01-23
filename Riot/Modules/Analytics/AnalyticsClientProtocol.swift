// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import AnalyticsEvents

/// A protocol representing an analytics client.
protocol AnalyticsClientProtocol {
    /// Whether the analytics client is currently reporting data or ignoring it.
    var isRunning: Bool { get }
    
    /// Starts the analytics client reporting data.
    func start()
    
    /// Associate the client with an ID. This is persisted until `reset` is called.
    /// - Parameter id: The ID to associate with the user.
    func identify(id: String)
    
    /// Reset all stored properties and any event queues on the client. Note that
    /// the client will remain active, but in a fresh unidentified state.
    func reset()
    
    /// Stop the analytics client reporting data.
    func stop()
    
    /// Send any queued events immediately.
    func flush()
    
    /// Capture the supplied analytics event.
    /// - Parameter event: The event to capture.
    func capture(_ event: AnalyticsEventProtocol)
    
    /// Capture the supplied analytics screen event.
    /// - Parameter event: The screen event to capture.
    func screen(_ event: AnalyticsScreenProtocol)
    
    /// Updates any user properties to help with creating cohorts.
    /// - Parameter userProperties: The user properties to be updated.
    ///
    /// Only non-nil properties will be updated when calling this method. There might
    /// be a delay when updating user properties as these are cached to be included
    /// as part of the next event that gets captured.
    func updateUserProperties(_ userProperties: AnalyticsEvent.UserProperties)
    
    
    /// Updates the super properties.
    /// Super properties added to all captured events and screen.
    /// - Parameter superProperties: The properties event to capture.
    func updateSuperProperties(_ event: AnalyticsEvent.SuperProperties)
    
}
