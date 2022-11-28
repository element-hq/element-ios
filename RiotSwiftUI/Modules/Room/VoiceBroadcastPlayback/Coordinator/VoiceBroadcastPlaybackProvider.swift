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

@objc class VoiceBroadcastPlaybackProvider: NSObject {
    @objc static let shared = VoiceBroadcastPlaybackProvider()
    
    var session: MXSession? {
        willSet {
            guard let currentSession = self.session else { return }
            
            if currentSession != newValue {
                // Clear all stored coordinators on new session
                coordinatorsForEventIdentifiers.removeAll()
            }
        }
    }
    var coordinatorsForEventIdentifiers = [String: VoiceBroadcastPlaybackCoordinator]()
    
    private override init() { }
    
    /// Create or retrieve the voiceBroadcast timeline coordinator for this event and return
    /// a view to be displayed in the timeline
    func buildVoiceBroadcastPlaybackVCForEvent(_ event: MXEvent, senderDisplayName: String?, voiceBroadcastState: String) -> UIViewController? {
        guard let session = session, let room = session.room(withRoomId: event.roomId) else {
            return nil
        }
        
        if let coordinator = coordinatorsForEventIdentifiers[event.eventId] {
            return coordinator.toPresentable()
        }
        
        let parameters = VoiceBroadcastPlaybackCoordinatorParameters(session: session,
                                                                     room: room,
                                                                     voiceBroadcastStartEvent: event,
                                                                     voiceBroadcastState: VoiceBroadcastInfoState(rawValue: voiceBroadcastState) ?? VoiceBroadcastInfoState.stopped,
                                                                     senderDisplayName: senderDisplayName)
        guard let coordinator = try? VoiceBroadcastPlaybackCoordinator(parameters: parameters) else {
            return nil
        }
        
        coordinatorsForEventIdentifiers[event.eventId] = coordinator
        
        return coordinator.toPresentable()

    }
    
    /// Retrieve the voiceBroadcast timeline coordinator for the given event or nil if it hasn't been created yet
    func voiceBroadcastPlaybackCoordinatorForEventIdentifier(_ eventIdentifier: String) -> VoiceBroadcastPlaybackCoordinator? {
        coordinatorsForEventIdentifiers[eventIdentifier]
    }
    
    /// Pause current voice broadcast playback.
    @objc public func pausePlaying() {
        coordinatorsForEventIdentifiers.forEach { _, coordinator in
            coordinator.pausePlaying()
        }
    }
}
