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

/// A class responsible for managing a variety of analytics clients
/// and sending events through these clients.
///
/// Events may include user activity, or app health data such as crashes,
/// non-fatal issues and performance. `Analytics` class serves as a façade
/// to all these use cases.
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
    
    /// The monitoring client to track crashes, issues and performance
    private var monitoringClient = SentryMonitoringClient()
    
    /// The service used to interact with account data settings.
    private var service: AnalyticsService?
    
    private var viewRoomActiveSpace: AnalyticsViewRoomActiveSpace = .home
    
    /// Whether or not the object is enabled and sending events to the server.
    var isRunning: Bool { client.isRunning }
    
    /// Whether to show the user the analytics opt in prompt.
    var shouldShowAnalyticsPrompt: Bool {
        // Only show the prompt once, and when analytics are enabled in BuildSettings.
        !RiotSettings.shared.hasSeenAnalyticsPrompt && BuildSettings.analyticsConfiguration.isEnabled
    }
    
    /// Indicates whether the user previously accepted Matomo analytics and should be shown the upgrade prompt.
    var promptShouldDisplayUpgradeMessage: Bool {
        RiotSettings.shared.hasAcceptedMatomoAnalytics
    }
    
    /// Used to defined the trigger of the next potential `JoinedRoom` event
    var joinedRoomTrigger: AnalyticsJoinedRoomTrigger = .unknown
    
    /// Used to defined the trigger of the next potential `ViewRoom` event
    var viewRoomTrigger: AnalyticsViewRoomTrigger = .unknown
    
    /// Used to defined the actual space activated by the user.
    var activeSpace: MXSpace? {
        didSet {
            updateViewRoomActiveSpace()
        }
    }
    
    /// Used to defined the currently visible space in explore rooms.
    var exploringSpace: MXSpace? {
        didSet {
            updateViewRoomActiveSpace()
        }
    }

    // MARK: - Private
    
    /// keep an instance of `AnalyticsSpaceTracker` to track space metrics when space graph is built.
    private let spaceTracker: AnalyticsSpaceTracker = AnalyticsSpaceTracker()
    
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
        monitoringClient.stop()
        
        MXLog.debug("[Analytics] Stopped.")
    }
    
    /// Starts the analytics client if the user has opted in, otherwise does nothing.
    func startIfEnabled() {
        guard RiotSettings.shared.enableAnalytics, !isRunning else { return }
        
        client.start()
        monitoringClient.start()
        
        // Sanity check in case something went wrong.
        guard client.isRunning else { return }
        
        MXLog.debug("[Analytics] Started.")
        
        if Bundle.main.isShareExtension {
            // Don't log crashes in the share extension
        } else {
            // Catch and log crashes
            MXLogger.logCrashes(true)
        }
        
        MXLogger.setBuildVersion(AppInfo.current.buildInfo.readableBuildVersion)
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
        monitoringClient.reset()
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
    
    /// Update `viewRoomActiveSpace` property according to the current value of `exploringSpace` and `activeSpace` properties.
    private func updateViewRoomActiveSpace() {
        let space = exploringSpace ?? activeSpace
        guard let spaceRoom = space?.room else {
            viewRoomActiveSpace = .home
            return
        }
        
        spaceRoom.state { roomState in
            self.viewRoomActiveSpace = roomState?.isJoinRulePublic == true ? .public : .private
        }
    }
}

// MARK: - Public tracking methods
// The following methods are exposed for compatibility with Objective-C as
// the `capture` method and the generated events cannot be bridged from Swift.
extension Analytics {
    /// Updates any user properties to help with creating cohorts.
    /// 
    /// Only non-nil properties will be updated when calling this method.
    func updateUserProperties(ftueUseCase: UserSessionProperties.UseCase? = nil, numFavouriteRooms: Int? = nil, numSpaces: Int? = nil, allChatsActiveFilter: UserSessionProperties.AllChatsActiveFilter? = nil) {
        let userProperties = AnalyticsEvent.UserProperties(ftueUseCaseSelection: ftueUseCase?.analyticsName,
                                                           numFavouriteRooms: numFavouriteRooms,
                                                           numSpaces: numSpaces,
                                                           allChatsActiveFilter: allChatsActiveFilter?.analyticsName)
        client.updateUserProperties(userProperties)
    }
    
    /// Track the registration of a new user.
    /// - Parameter authenticationType: The type of authentication that was used.
    func trackSignup(authenticationType: AnalyticsEvent.Signup.AuthenticationType) {
        let event = AnalyticsEvent.Signup(authenticationType: authenticationType)
        capture(event: event)
    }
    
    /// Track the presentation of a screen
    /// - Parameters:
    ///   - screen: The screen that was shown.
    ///   - milliseconds: An optional value representing how long the screen was shown for in milliseconds.
    func trackScreen(_ screen: AnalyticsScreen, duration milliseconds: Int?) {
        let event = AnalyticsEvent.MobileScreen(durationMs: milliseconds, screenName: screen.screenName)
        client.screen(event)
    }
    
    /// The the presentation of a screen without including a duration
    /// - Parameter screen: The screen that was shown
    func trackScreen(_ screen: AnalyticsScreen) {
        trackScreen(screen, duration: nil)
    }
    
    /// Track an element that has been interacted with
    /// - Parameters:
    ///   - uiElement: The element that was interacted with
    ///   - interactionType: The way in with the element was interacted with
    ///   - index: The index of the element, if it's in a list of elements
    func trackInteraction(_ uiElement: AnalyticsUIElement, interactionType: AnalyticsEvent.Interaction.InteractionType, index: Int?) {
        let event = AnalyticsEvent.Interaction(index: index, interactionType: interactionType, name: uiElement.name)
        client.capture(event)
    }
    
    /// Track an element that has been tapped without including an index
    /// - Parameters:
    ///   - uiElement: The element that was tapped
    func trackInteraction(_ uiElement: AnalyticsUIElement) {
        trackInteraction(uiElement, interactionType: .Touch, index: nil)
    }
    
    /// Track an E2EE error that occurred
    /// - Parameters:
    ///   - reason: The error that occurred.
    ///   - context: Additional context of the error that occured
    func trackE2EEError(_ reason: DecryptionFailureReason, context: String) {
        let event = AnalyticsEvent.Error(context: context, domain: .E2EE, name: reason.errorName)
        capture(event: event)
    }
    
    /// Track when a user becomes unauthenticated without pressing the `sign out` button.
    /// - Parameters:
    ///   - softLogout: Wether it was a soft/hard logout that was triggered.
    ///   - refreshTokenAuth: Wether it was either an access-token-based or refresh-token-based auth mechanism enabled.
    ///   - errorCode: The error code as returned by the homeserver that triggered the logout.
    ///   - errorReason: The reason for the error as returned by the homeserver that triggered the logout.
    func trackAuthUnauthenticatedError(softLogout: Bool, refreshTokenAuth: Bool, errorCode: String, errorReason: String) {
        let errorCode = AnalyticsEvent.UnauthenticatedError.ErrorCode(rawValue: errorCode) ?? .M_UNKNOWN
        let event = AnalyticsEvent.UnauthenticatedError(errorCode: errorCode, errorReason: errorReason, refreshTokenAuth: refreshTokenAuth, softLogout: softLogout)
        client.capture(event)
    }
    
    /// Track whether the user accepted or declined the terms to an identity server.
    /// **Note** This method isn't currently implemented.
    /// - Parameter accepted: Whether the terms were accepted.
    func trackIdentityServerAccepted(_ accepted: Bool) {
        // Do we still want to track this?
    }
    
    /// Track view room event triggered when the user changes rooms.
    /// - Parameters:
    ///   - room: the room being viewed
    func trackViewRoom(_ room: MXRoom) {
        trackViewRoom(asDM: room.isDirect, isSpace: room.summary?.roomType == .space)
    }
    
    /// Track view room event triggered when the user changes rooms.
    /// - Parameters:
    ///   - isDM: Whether the room is a DM.
    ///   - isSpace: Whether the room is a Space.
    func trackViewRoom(asDM isDM: Bool, isSpace: Bool) {
        let event = AnalyticsEvent.ViewRoom(activeSpace: viewRoomActiveSpace.space,
                                            isDM: isDM,
                                            isSpace: isSpace,
                                            trigger: viewRoomTrigger.trigger,
                                            viaKeyboard: nil)
        viewRoomTrigger = .unknown
        capture(event: event)
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
    
    func startDurationTracking(forName name: String, operation: String) -> StopDurationTracking {
        return monitoringClient.startPerformanceTracking(name: name, operation: operation)
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
    
    func trackJoinedRoom(asDM isDM: Bool, isSpace: Bool, memberCount: UInt) {
        guard let roomSize = AnalyticsEvent.JoinedRoom.RoomSize(memberCount: memberCount) else {
            MXLog.warning("[Analytics] Attempt to capture joined room with invalid member count: \(memberCount)")
            return
        }
        
        let event = AnalyticsEvent.JoinedRoom(isDM: isDM, isSpace: isSpace, roomSize: roomSize, trigger: joinedRoomTrigger.trigger)
        capture(event: event)
        
        self.joinedRoomTrigger = .unknown
    }
    
    /// **Note** This method isn't currently implemented.
    func trackContactsAccessGranted(_ granted: Bool) {
        // Do we still want to track this?
    }

    func trackComposerEvent(inThread: Bool, isEditing: Bool, isReply: Bool, startsThread: Bool) {
        let event = AnalyticsEvent.Composer(inThread: inThread,
                                            isEditing: isEditing,
                                            isReply: isReply,
                                            startsThread: startsThread)
        capture(event: event)
    }

    func trackNonFatalIssue(_ issue: String, details: [String: Any]?) {
        monitoringClient.trackNonFatalIssue(issue, details: details)
    }
}
