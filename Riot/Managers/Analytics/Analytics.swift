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
    
    private var postHog: PHGPostHog?
    
    private(set) var isRunning = false
    
    var shouldShowAnalyticsPrompt: Bool {
        // Show an analytics prompt when the user hasn't seen the PostHog prompt before
        // so long as they haven't previously declined the Matomo analytics prompt.
        !RiotSettings.shared.hasSeenAnalyticsPrompt && !RiotSettings.shared.hasDeclinedMatomoAnalytics
    }
    
    var promptShouldDisplayUpgradeMessage: Bool {
        // Show an analytics prompt when the user hasn't seen the PostHog prompt before
        // so long as they haven't previously declined the Matomo analytics prompt.
        RiotSettings.shared.hasAcceptedMatomoAnalytics
    }
    
    // MARK: - Public
    
    func optIn(with session: MXSession?) {
        guard let session = session else { return }
        RiotSettings.shared.enableAnalytics = true
        
        var settings = AnalyticsSettings(session: session)
        
        if settings.id == nil {
            settings.generateID()
            
            session.setAccountData(settings.dictionary, forType: AnalyticsSettings.eventType) {
                MXLog.debug("[Analytics] Successfully updated analytics settings in account data.")
            } failure: { error in
                MXLog.error("[Analytics] Failed to update analytics settings.")
            }
        }
        
        startIfEnabled()
        
        if !RiotSettings.shared.isIdentifiedForAnalytics {
            identify(with: settings)
        }
    }
    
    func optOut() {
        RiotSettings.shared.enableAnalytics = false
        reset()
    }
    
    func startIfEnabled() {
        guard RiotSettings.shared.enableAnalytics, !isRunning else { return }
        
        postHog = PHGPostHog(configuration: PHGPostHogConfiguration.standard)
        postHog?.enable()
        isRunning = true
        MXLog.debug("[Analytics] Started.")
        
        // Catch and log crashes
        MXLogger.logCrashes(true)
        MXLogger.setBuildVersion(AppDelegate.theDelegate().build)
    }
    
    private func identify(with settings: AnalyticsSettings) {
        guard let id = settings.id else {
            MXLog.warning("[Analytics] identify(with:) called before an ID has been generated.")
            return
        }
        
        postHog?.identify(id)
        MXLog.debug("[Analytics] Identified.")
        RiotSettings.shared.isIdentifiedForAnalytics = true
    }
    
    func reset() {
        guard isRunning else { return }
        
        postHog?.disable()
        isRunning = false
        MXLog.debug("[Analytics] Stopped.")
        
        postHog?.reset()
        RiotSettings.shared.isIdentifiedForAnalytics = false
        
        postHog = nil
        
        MXLogger.logCrashes(false)
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
    @objc func trackDuration(_ seconds: TimeInterval, category: String, name: String) {
//        postHog?.capture("\(category):\(name)", properties: ["duration": seconds])
    }
    
    @objc func trackValue(_ value: NSNumber, category: String, name: String) {
//        postHog?.capture("\(category):\(name)", properties: ["value": value])
    }
}
