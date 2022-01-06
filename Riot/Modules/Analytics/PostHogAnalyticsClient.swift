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
        postHog?.identify(id)
    }
    
    func reset() {
        postHog?.reset()
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
        postHog?.capture(event.eventName, properties: event.properties)
    }
    
    func screen(_ event: AnalyticsScreenProtocol) {
        postHog?.screen(event.screenName.rawValue, properties: event.properties)
    }
    
}
