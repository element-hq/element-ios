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

import PostHog
import AnalyticsEvents

/// An analytics client that reports events to a PostHog server.
class PostHogAnalyticsClient: AnalyticsClientProtocol {
    /// The PHGPostHog object used to report events.
    private var postHog: PHGPostHog?
    
    /// Any user properties to be included with the next captured event.
    private(set) var pendingUserProperties: AnalyticsEvent.UserProperties?
    
    var isRunning: Bool { postHog?.enabled ?? false }
    
    func start() {
        // Only start if analytics have been configured in BuildSettings
        guard let configuration = PHGPostHogConfiguration.standard else { return }
        
        if postHog == nil {
            postHog = PHGPostHog(configuration: configuration)
        }
        
        postHog?.enable()
    }
    
    func identify(id: String) {
        if let userProperties = pendingUserProperties {
            // As user properties overwrite old ones, compactMap the dictionary to avoid resetting any missing properties
            postHog?.identify(id, properties: userProperties.properties.compactMapValues { $0 })
            pendingUserProperties = nil
        } else {
            postHog?.identify(id)
        }
    }
    
    func reset() {
        postHog?.reset()
        pendingUserProperties = nil
    }
    
    func stop() {
        postHog?.disable()
        
        // As of PostHog 1.4.4, setting the client to nil here doesn't release
        // it. Keep it around to avoid having multiple instances if the user re-enables
    }
    
    func flush() {
        postHog?.flush()
    }
    
    func capture(_ event: AnalyticsEventProtocol) {
        postHog?.capture(event.eventName, properties: attachUserProperties(to: event.properties))
    }
    
    func screen(_ event: AnalyticsScreenProtocol) {
        postHog?.screen(event.screenName.rawValue, properties: attachUserProperties(to: event.properties))
    }
    
    func updateUserProperties(_ userProperties: AnalyticsEvent.UserProperties) {
        guard let pendingUserProperties = pendingUserProperties else {
            pendingUserProperties = userProperties
            return
        }
        
        // Merge the updated user properties with the existing ones
        self.pendingUserProperties = AnalyticsEvent.UserProperties(ftueUseCaseSelection: userProperties.ftueUseCaseSelection ?? pendingUserProperties.ftueUseCaseSelection,
                                                                   numFavouriteRooms: userProperties.numFavouriteRooms ?? pendingUserProperties.numFavouriteRooms,
                                                                   numSpaces: userProperties.numSpaces ?? pendingUserProperties.numSpaces,
                                                                   allChatsActiveFilter: userProperties.allChatsActiveFilter ?? pendingUserProperties.allChatsActiveFilter)
    }
    
    // MARK: - Private
    
    /// Given a dictionary containing properties from an event, this method will return those properties
    /// with any pending user properties included under the `$set` key.
    /// - Parameter properties: A dictionary of properties from an event.
    /// - Returns: The `properties` dictionary with any user properties included.
    private func attachUserProperties(to properties: [String: Any]) -> [String: Any] {
        guard isRunning, let userProperties = pendingUserProperties else { return properties }
        
        var properties = properties
        
        // As user properties overwrite old ones via $set, compactMap the dictionary to avoid resetting any missing properties
        properties["$set"] = userProperties.properties.compactMapValues { $0 }
        pendingUserProperties = nil
        return properties
    }
}
