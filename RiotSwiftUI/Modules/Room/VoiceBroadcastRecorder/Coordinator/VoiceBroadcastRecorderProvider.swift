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
                // Clear stored recorder coordinator on new session
                self.voiceBroadcastRecorderCoordinator = nil
                self.currentEventIdentifier = nil
            }
        }
    }
    
    // MARK: Private
    private var currentEventIdentifier: String?
    private var redactionsListener: Any?
    private var voiceBroadcastRecorderCoordinator: VoiceBroadcastRecorderCoordinator? {
        didSet {
            if self.voiceBroadcastRecorderCoordinator != nil && self.redactionsListener == nil {
                redactionsListener = session?.listenToEvents([MXEventType(identifier: kMXEventTypeStringRoomRedaction)], self.handleRedactedEvent)
            }

            if self.voiceBroadcastRecorderCoordinator == nil && self.redactionsListener != nil {
                session?.removeListener(self.redactionsListener)
                self.redactionsListener = nil
            }
        }
    }

    // MARK: - Setup
    private override init() { }
    
    // MARK: - Public
    
    /// Create or retrieve the voiceBroadcast timeline coordinator for this event and return
    /// a view to be displayed in the timeline
    func buildVoiceBroadcastRecorderViewForEvent(_ event: MXEvent, senderDisplayName: String?) -> UIView? {
        guard let session = session,
              let room = session.room(withRoomId: event.roomId) else {
            return nil
        }
        
        if self.currentEventIdentifier == event.eventId, let coordinator = voiceBroadcastRecorderCoordinator {
            return coordinator.toPresentable().view
        }
        
        let parameters = VoiceBroadcastRecorderCoordinatorParameters(session: session,
                                                                     room: room,
                                                                     voiceBroadcastStartEvent: event,
                                                                     senderDisplayName: senderDisplayName)
        let coordinator = VoiceBroadcastRecorderCoordinator(parameters: parameters)
        
        self.voiceBroadcastRecorderCoordinator = coordinator
        self.currentEventIdentifier = event.eventId
        
        return coordinator.toPresentable().view
    }
    
    /// Pause current voice broadcast recording.
    @objc public func pauseRecording() {
        voiceBroadcastRecorderCoordinator?.pauseRecording()
    }
    
    /// Pause current voice broadcast recording without sending pending events.
    @objc public func pauseRecordingOnError() {
        voiceBroadcastRecorderCoordinator?.pauseRecordingOnError()
    }
    
    @objc public func isVoiceBroadcastRecording() -> Bool {
        guard let coordinator = self.voiceBroadcastRecorderCoordinator else {
            return false
        }
        
        return coordinator.isVoiceBroadcastRecording()
    }
    
    // MARK: - Private
    
    private func handleRedactedEvent(event: MXEvent, direction: MXTimelineDirection, customObject: Any?) {
        if self.currentEventIdentifier != event.redacts, direction == .backwards {
            return
        }
        
        self.voiceBroadcastRecorderCoordinator?.toPresentable().dismiss(animated: false) {
            self.voiceBroadcastRecorderCoordinator = nil
            self.currentEventIdentifier = nil
        }
    }
}
