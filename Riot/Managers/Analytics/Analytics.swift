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

@objcMembers class Analytics: NSObject {
    
    // MARK: - Properties
    
    static let shared = Analytics()
    
    private var postHog: PHGPostHog?
    
    var isRunning: Bool { postHog?.enabled ?? false }
    
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
        
        // Ensures that analytics are configured BuildSettings
        guard let configuration = PHGPostHogConfiguration.standard else { return }
        
        postHog = PHGPostHog(configuration: configuration)
        postHog?.enable()
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
        MXLog.debug("[Analytics] Stopped.")
        
        postHog?.reset()
        RiotSettings.shared.isIdentifiedForAnalytics = false
        
        postHog = nil
        
        MXLogger.logCrashes(false)
    }
    
    func forceUpload() {
        postHog?.flush()
    }
    
    private func capture(event: AnalyticsEventProtocol) {
        postHog?.capture(event.eventName, properties: event.properties)
    }
    
    func trackScreen(_ screen: AnalyticsScreen, duration milliseconds: Int?) {
        let event = AnalyticsEvent.Screen(durationMs: milliseconds, screenName: screen.screenName)
        postHog?.screen(event.screenName.rawValue, properties: event.properties)
    }
    
    func trackE2EEError(_ reason: DecryptionFailureReason, count: Int) {
        for _ in 0..<count {
            let event = AnalyticsEvent.Error(context: nil, domain: .E2EE, name: reason.errorName)
            capture(event: event)
        }
    }
    
    func trackIdentityServerAccepted(granted: Bool) {
        // Do we still want to track this?
    }
}

// MARK: - MXAnalyticsDelegate
extension Analytics: MXAnalyticsDelegate {
    func trackDuration(_ milliseconds: Int, name: MXTaskProfileName, units: UInt) {
        guard let analyticsName = name.analyticsName else {
            MXLog.warning("[Analytics] Attempt to capture unknown profile task: \(name.rawValue)")
            return
        }
        
        let event = AnalyticsEvent.PerformanceTimer(context: nil, itemCount: Int(units), name: analyticsName, timeMs: milliseconds)
        capture(event: event)
    }
    
    func trackCallStarted(withVideo isVideo: Bool, numberOfParticipants: Int, incoming isIncoming: Bool) {
        let event = AnalyticsEvent.CallStarted(isVideo: isVideo, numParticipants: numberOfParticipants, placed: !isIncoming)
        capture(event: event)
    }
    
    func trackCallEnded(withDuration duration: Int, video isVideo: Bool, numberOfParticipants: Int, incoming isIncoming: Bool) {
        let event = AnalyticsEvent.CallEnded(durationMs: duration, isVideo: isVideo, numParticipants: numberOfParticipants, placed: !isIncoming)
        capture(event: event)
    }
    
    func trackCallError(with reason: __MXCallHangupReason, video isVideo: Bool, numberOfParticipants: Int, incoming isIncoming: Bool) {
        let callEvent = AnalyticsEvent.CallError(isVideo: isVideo, numParticipants: numberOfParticipants, placed: !isIncoming)
        let event = AnalyticsEvent.Error(context: nil, domain: .VOIP, name: reason.errorName)
        capture(event: callEvent)
        capture(event: event)
    }
    
    func trackContactsAccessGranted(_ granted: Bool) {
        // Do we still want to track this?
    }
    
    func trackCreatedRoom(asDM isDM: Bool) {
        let event = AnalyticsEvent.CreatedRoom(isDM: isDM)
        capture(event: event)
    }
    
    func trackJoinedRoom(asDM isDM: Bool, memberCount: UInt) {
        guard let roomSize = AnalyticsEvent.JoinedRoom.RoomSize(memberCount: memberCount) else {
            MXLog.warning("[Analytics] Attempt to capture joined room with invalid member count: \(memberCount)")
            return
        }
        
        let event = AnalyticsEvent.JoinedRoom(isDM: isDM, roomSize: roomSize)
        capture(event: event)
    }
}
