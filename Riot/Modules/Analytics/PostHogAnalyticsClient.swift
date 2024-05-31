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
    private var postHog: PostHogSDK?
    
    /// Any user properties to be included with the next captured event.
    private(set) var pendingUserProperties: AnalyticsEvent.UserProperties?
    
    static let shared = PostHogAnalyticsClient()
    
    var isRunning: Bool { postHog != nil && !postHog!.isOptOut() }
    
    func start() {
        // Only start if analytics have been configured in BuildSettings
        guard let configuration = PostHogConfig.standard else { return }
        
        if postHog == nil {
            PostHogSDK.shared.setup(configuration)
            postHog = PostHogSDK.shared
        }
        
        postHog?.optIn()
    }
    
    func identify(id: String) {
        if let userProperties = pendingUserProperties {
            // As user properties overwrite old ones, compactMap the dictionary to avoid resetting any missing properties
            postHog?.identify(id, userProperties: userProperties.properties.compactMapValues { $0 })
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
        postHog?.optOut()
        
        self.postHog = nil
    }
    
    func flush() {
        postHog?.flush()
    }
    
    func capture(_ event: AnalyticsEventProtocol) {
        postHog?.capture(event.eventName, properties: event.properties, userProperties: pendingUserProperties?.properties.compactMapValues { $0 })
        // Pending user properties have been added
        self.pendingUserProperties = nil
    }
    
    func screen(_ event: AnalyticsScreenProtocol) {
        postHog?.screen(event.screenName.rawValue, properties: event.properties)
    }
    
    func updateUserProperties(_ userProperties: AnalyticsEvent.UserProperties) {
        guard let pendingUserProperties = pendingUserProperties else {
            pendingUserProperties = userProperties
            return
        }
        
        // Merge the updated user properties with the existing ones
        self.pendingUserProperties = AnalyticsEvent.UserProperties(allChatsActiveFilter: userProperties.allChatsActiveFilter ?? pendingUserProperties.allChatsActiveFilter,
                                                                   ftueUseCaseSelection: userProperties.ftueUseCaseSelection ?? pendingUserProperties.ftueUseCaseSelection,
                                                                   numFavouriteRooms: userProperties.numFavouriteRooms ?? pendingUserProperties.numFavouriteRooms,
                                                                   numSpaces: userProperties.numSpaces ?? pendingUserProperties.numSpaces)
    }
    
}

extension PostHogAnalyticsClient: RemoteFeaturesClientProtocol {
    func isFeatureEnabled(_ feature: String) -> Bool {
        postHog?.isFeatureEnabled(feature) == true
    }
}
