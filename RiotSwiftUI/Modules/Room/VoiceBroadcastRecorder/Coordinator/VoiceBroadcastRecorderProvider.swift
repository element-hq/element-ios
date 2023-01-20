//
// Copyright 2022 New Vector Ltd
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

import Foundation

@objc public class VoiceBroadcastRecorderProvider: NSObject {
    
    // MARK: - Constants
    @objc public static let shared = VoiceBroadcastRecorderProvider()
    
    // MARK: - Properties
    // MARK: Public
    var session: MXSession? {
        willSet {
            guard let currentSession = self.session else { return }
            
            if currentSession != newValue {
                // Clear all stored coordinators on new session
                coordinatorsForEventIdentifiers.removeAll()
            }
        }
        didSet {
            sessionState = session?.state
        }
    }
    private var coordinatorsForEventIdentifiers = [String: VoiceBroadcastRecorderCoordinator]() {
        didSet {
            if !self.coordinatorsForEventIdentifiers.isEmpty && self.redactionsListener == nil {
                redactionsListener = session?.listenToEvents([MXEventType(identifier: kMXEventTypeStringRoomRedaction)], self.handleRedactedEvent)
            }
            
            if self.coordinatorsForEventIdentifiers.isEmpty && self.redactionsListener != nil {
                session?.removeListener(self.redactionsListener)
                self.redactionsListener = nil
            }
        }
    }
    private var redactionsListener: Any?
    
    // MARK: Private
    private var currentEventIdentifier: String?
    private var sessionState: MXSessionState?
    
    private var sessionStateDidChangeObserver: Any?
    
    // MARK: - Setup
    private override init() {
        super.init()
        self.registerNotificationObservers()
    }
    
    deinit {
        unregisterNotificationObservers()
    }
    
    // MARK: - Public
    
    /// Create or retrieve the voiceBroadcast timeline coordinator for this event and return
    /// a view to be displayed in the timeline
    func buildVoiceBroadcastRecorderViewForEvent(_ event: MXEvent, senderDisplayName: String?) -> UIView? {
        guard let session = session,
              let room = session.room(withRoomId: event.roomId) else {
            return nil
        }
        
        self.currentEventIdentifier = event.eventId
        
        if let coordinator = coordinatorsForEventIdentifiers[event.eventId] {
            return coordinator.toPresentable().view
        }
        
        let parameters = VoiceBroadcastRecorderCoordinatorParameters(session: session,
                                                                     room: room,
                                                                     voiceBroadcastStartEvent: event,
                                                                     senderDisplayName: senderDisplayName)
        let coordinator = VoiceBroadcastRecorderCoordinator(parameters: parameters)
        
        coordinatorsForEventIdentifiers[event.eventId] = coordinator
        
        return coordinator.toPresentable().view
    }
    
    /// Pause current voice broadcast recording.
    @objc public func pauseRecording() {
        voiceBroadcastRecorderCoordinatorForCurrentEvent()?.pauseRecording()
    }
    
    /// Pause current voice broadcast recording without sending pending events.
    @objc public func pauseRecordingOnError() {
        voiceBroadcastRecorderCoordinatorForCurrentEvent()?.pauseRecordingOnError()
    }
    
    @objc public func isVoiceBroadcastRecording() -> Bool {
        guard let coordinator = voiceBroadcastRecorderCoordinatorForCurrentEvent() else {
            return false
        }
        
        return coordinator.isVoiceBroadcastRecording()
    }
    
    // MARK: - Private
    
    /// Retrieve the voiceBroadcast recorder coordinator for the current event or nil if it hasn't been created yet
    private func voiceBroadcastRecorderCoordinatorForCurrentEvent() -> VoiceBroadcastRecorderCoordinator? {
        guard let currentEventIdentifier = currentEventIdentifier else {
            return nil
        }
        
        return coordinatorsForEventIdentifiers[currentEventIdentifier]
    }
    
    private func handleRedactedEvent(event: MXEvent, direction: MXTimelineDirection, customObject: Any?) {
        if direction == .backwards {
            //  ignore backwards events
            return
        }
        
        var coordinator = coordinatorsForEventIdentifiers.removeValue(forKey: event.redacts)
        
        coordinator?.toPresentable().dismiss(animated: false) {
            coordinator = nil
        }
    }
    
    // MARK: - Notification handling
    
    private func registerNotificationObservers() {
        self.sessionStateDidChangeObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.mxSessionStateDidChange, object: session, queue: nil) { [weak self] notification in
            guard let self else { return }
            guard let concernedSession = notification.object as? MXSession, self.session === concernedSession  else { return }
            
            self.update(sessionState: concernedSession.state)
        }
    }
    
    private func unregisterNotificationObservers() {
        if let observer = self.sessionStateDidChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Session state
    private func update(sessionState: MXSessionState) {
        let oldState = self.sessionState
        self.sessionState = sessionState
        
        switch (oldState, sessionState) {
        case (_, .homeserverNotReachable):
            pauseRecordingOnError()
        case (_, .running):
            pauseRecording()
        default:
            break
        }
    }
}
