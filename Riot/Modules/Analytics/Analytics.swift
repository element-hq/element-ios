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

/// A class responsible for managing an analytics client
/// and sending events through this client.
///
/// ## Creating Analytics Events
///
/// Events are managed in a shared repo for all Element clients https://github.com/matrix-org/matrix-analytics-events
/// To add a new event create a PR to that repo with the new/updated schema. Element's Podfile has
/// a local version of the pod (commented out) for development purposes.
/// Once merged into `main`, follow the steps below to integrate the changes into the project:
/// 1. Check if `main` contains any source breaking changes to the events. If so, please
/// wait until you are ready to merge your work into element-ios.
/// 2. Merge `main` into the `release/swift` branch.
/// 3. Run `bundle exec pod update AnalyticsEvents` to update the pod.
/// 4. Make sure to commit `Podfile.lock` with the new commit hash.
///
@objcMembers class Analytics: NSObject {
    
    // MARK: - Properties
    
    /// The singleton instance to be used within the Riot target.
    static let shared = Analytics()
    
    /// The analytics client to send events with.
    private var client: AnalyticsClientProtocol = PostHogAnalyticsClient()
    
    /// The service used to interact with account data settings.
    private var service: AnalyticsService?
    
    /// Whether or not the object is enabled and sending events to the server.
    var isRunning: Bool { client.isRunning }
    
    /// Whether to show the user the analytics opt in prompt.
    var shouldShowAnalyticsPrompt: Bool {
        // Only show the prompt once, and when analytics are configured in BuildSettings.
        !RiotSettings.shared.hasSeenAnalyticsPrompt && PHGPostHogConfiguration.standard != nil
    }
    
    /// Indicates whether the user previously accepted Matomo analytics and should be shown the upgrade prompt.
    var promptShouldDisplayUpgradeMessage: Bool {
        RiotSettings.shared.hasAcceptedMatomoAnalytics
    }
    
    // MARK: - Public
    
    /// Opts in to analytics tracking with the supplied session.
    /// - Parameter session: An optional session to use to when reading/generating the analytics ID.
    ///  The session will be ignored if not running.
    func optIn(with session: MXSession?) {
        RiotSettings.shared.enableAnalytics = true
        startIfEnabled()
        
        guard let session = session else { return }
        useAnalyticsSettings(from: session)
    }
    
    /// Stops analytics tracking and calls `reset` to clear any IDs and event queues.
    func optOut() {
        RiotSettings.shared.enableAnalytics = false
        
        // The order is important here. PostHog ignores the reset if stopped.
        reset()
        client.stop()
        
        MXLog.debug("[Analytics] Stopped.")
    }
    
    /// Starts the analytics client if the user has opted in, otherwise does nothing.
    func startIfEnabled() {
        guard RiotSettings.shared.enableAnalytics, !isRunning else { return }
        
        client.start()
        
        // Sanity check in case something went wrong.
        guard client.isRunning else { return }
        
        MXLog.debug("[Analytics] Started.")
        
        // Catch and log crashes
        MXLogger.logCrashes(true)
        MXLogger.setBuildVersion(AppDelegate.theDelegate().build)
    }
    
    /// Use the analytics settings from the supplied session to configure analytics.
    /// For now this is only used for (pseudonymous) identification.
    /// - Parameter session: The session to read analytics settings from.
    func useAnalyticsSettings(from session: MXSession) {
        guard
            RiotSettings.shared.enableAnalytics,
            !RiotSettings.shared.isIdentifiedForAnalytics
        else { return }
        
        let service = AnalyticsService(session: session)
        self.service = service
        
        service.settings { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let settings):
                self.identify(with: settings)
                self.service = nil
            case .failure:
                MXLog.error("[Analytics] Failed to use analytics settings. Will continue to run without analytics ID.")
                self.service = nil
            }
        }
    }
    
    /// Resets the any IDs and event queues in the analytics client. This method should
    /// be called on sign-out to maintain opt-in status, whilst ensuring the next
    /// account used isn't associated with the previous one.
    /// Note: **MUST** be called before stopping PostHog or the reset is ignored.
    func reset() {
        client.reset()
        MXLog.debug("[Analytics] Reset.")
        RiotSettings.shared.isIdentifiedForAnalytics = false
        
        // Stop collecting crash logs
        MXLogger.logCrashes(false)
    }
    
    /// Flushes the event queue in the analytics client, uploading all pending events.
    /// Normally events are sent in batches. Call this method when you need an event
    /// to be sent immediately.
    func forceUpload() {
        client.flush()
    }
    
    // MARK: - Private
    
    /// Identify (pseudonymously) any future events with the ID from the analytics account data settings.
    /// - Parameter settings: The settings to use for identification. The ID must be set *before* calling this method.
    private func identify(with settings: AnalyticsSettings) {
        guard let id = settings.id else {
            MXLog.error("[Analytics] identify(with:) called before an ID has been generated.")
            return
        }
        
        client.identify(id: id)
        MXLog.debug("[Analytics] Identified.")
        RiotSettings.shared.isIdentifiedForAnalytics = true
    }
    
    /// Capture an event in the `client`.
    /// - Parameter event: The event to capture.
    private func capture(event: AnalyticsEventProtocol) {
        client.capture(event)
    }
}

// MARK: - Public tracking methods
// The following methods are exposed for compatibility with Objective-C as
// the `capture` method and the generated events cannot be bridged from Swift.
extension Analytics {
    /// Track the presentation of a screen
    /// - Parameters:
    ///   - screen: The screen that was shown.
    ///   - milliseconds: An optional value representing how long the screen was shown for in milliseconds.
    func trackScreen(_ screen: AnalyticsScreen, duration milliseconds: Int?) {
        let event = AnalyticsEvent.Screen(durationMs: milliseconds, screenName: screen.screenName)
        client.screen(event)
    }
    
    /// The the presentation of a screen without including a duration
    /// - Parameter screen: The screen that was shown
    func trackScreen(_ screen: AnalyticsScreen) {
        trackScreen(screen, duration: nil)
    }
    
    /// Track an element that has been tapped
    /// - Parameters:
    ///   - tap: The element that was tapped
    ///   - index: The index of the element, if it's in a list of elements
    func trackTap(_ tap: AnalyticsUIElement, index: Int?) {
        let event = AnalyticsEvent.Click(index: index, name: tap.elementName)
        client.capture(event)
    }
    
    /// Track an element that has been tapped without including an index
    /// - Parameters:
    ///   - tap: The element that was tapped
    func trackTap(_ tap: AnalyticsUIElement) {
        trackTap(tap, index: nil)
    }
    
    /// Track an E2EE error that occurred
    /// - Parameters:
    ///   - reason: The error that occurred.
    ///   - count: The number of times that error occurred.
    func trackE2EEError(_ reason: DecryptionFailureReason, count: Int) {
        for _ in 0..<count {
            let event = AnalyticsEvent.Error(context: nil, domain: .E2EE, name: reason.errorName)
            capture(event: event)
        }
    }
    
    /// Track whether the user accepted or declined the terms to an identity server.
    /// **Note** This method isn't currently implemented.
    /// - Parameter accepted: Whether the terms were accepted.
    func trackIdentityServerAccepted(_ accepted: Bool) {
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
    
    /// **Note** This method isn't currently implemented.
    func trackContactsAccessGranted(_ granted: Bool) {
        // Do we still want to track this?
    }
}
