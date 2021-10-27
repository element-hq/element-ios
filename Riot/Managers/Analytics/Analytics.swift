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

@objcMembers class Analytics: NSObject {
    
    // MARK: - Properties
    
    static let shared = Analytics()
    
    private(set) var isRunning = false
    
    private var postHog: PHGPostHog?
    
    // MARK: - Public
    
    func shouldShowPseudonymousAnalyticsPrompt(for session: MXSession) -> Bool {
        return AnalyticsSettings(session: session).showPseudonymousAnalyticsPrompt
    }
    
    func optIn(with session: MXSession?) {
        guard let session = session else { return }
        
        var settings = AnalyticsSettings(session: session)
        settings.generateIDIfMissing()
        settings.pseudonymousAnalyticsOptIn = true
        settings.showPseudonymousAnalyticsPrompt = false
        
        session.setAccountData(settings.dictionary, forType: AnalyticsSettings.eventType) {
            MXLog.debug("[Analytics] Successfully updated analytics settings in account data.")
        } failure: { error in
            MXLog.error("[Analytics] Failed to update analytics settings.")
        }
    }
    
    func optOut(with session: MXSession) {
        var settings = AnalyticsSettings(session: session)
        settings.id = nil
        settings.pseudonymousAnalyticsOptIn = false
        settings.showPseudonymousAnalyticsPrompt = false
        
        session.setAccountData(settings.dictionary, forType: AnalyticsSettings.eventType, success: nil) { error in
            MXLog.error("[Analytics] Failed to update analytics settings.")
        }
    }
    
    private func start(with pseudonymousID: String) {
        guard !isRunning else { return }
        
        postHog = PHGPostHog(configuration: PHGPostHogConfiguration.standard)
        postHog?.enable()
        isRunning = true
        MXLog.debug("[Analytics] Started.")
        
        if !RiotSettings.shared.hasPseudonymousAnalyticsIdentified {
            postHog?.identify(pseudonymousID)
            MXLog.debug("[Analytics] Identified.")
            RiotSettings.shared.hasPseudonymousAnalyticsIdentified = true
        }
        
        postHog?.capture("analyticsDidStart")
        forceUpload()
    }
    
    func reset() {
        guard isRunning else { return }
        
        postHog?.disable()
        isRunning = false
        MXLog.debug("[Analytics] Stopped.")
        
        postHog?.reset()
        RiotSettings.shared.hasPseudonymousAnalyticsIdentified = false
        
        postHog = nil
    }
    
    func forceUpload() {
        postHog?.flush()
    }
    
    func log(event: String) {
        postHog?.capture(event)
    }
}


// MARK: - Legacy compatibility
extension Analytics {
    #warning("Use enums instead")
    static let NotificationsCategory = "notifications"
    static let NotificationsTimeToDisplayContent = "timelineDisplay"
    static let ContactsIdentityServerAccepted = "identityServerAccepted"
    static let PerformanceCategory = "Performance"
    static let MetricsCategory = "Metrics"
    
    @objc func trackScreen(_ screenName: String) {
//        postHog?.capture("screen:\(screenName)")
    }
}

extension Analytics: MXAnalyticsDelegate {
    var settingsEventType: String { AnalyticsSettings.eventType }
    
    func handleSettingsEvent(_ event: [AnyHashable: Any]) {
        guard event["type"] as? String == AnalyticsSettings.eventType,
              let content = event["content"] as? [AnyHashable: Any]
        else {
            MXLog.error("[Analytics] handleSettingsEvent: invalid event")
            return
        }
        
        let settings = AnalyticsSettings(dictionary: content)
        
        if !settings.showPseudonymousAnalyticsPrompt,
           settings.pseudonymousAnalyticsOptIn == true,
           let id = settings.id {
            start(with: id)
        } else {
            reset()
        }
    }
    
    @objc func trackDuration(_ seconds: TimeInterval, category: String, name: String) {
//        postHog?.capture("\(category):\(name)", properties: ["duration": seconds])
    }
    
    @objc func trackValue(_ value: NSNumber, category: String, name: String) {
//        postHog?.capture("\(category):\(name)", properties: ["value": value])
    }
}
