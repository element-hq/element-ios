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

class VoiceBroadcastPlaybackProvider {
    static let shared = VoiceBroadcastPlaybackProvider()
    
    var session: MXSession?
    var coordinatorsForEventIdentifiers = [String: VoiceBroadcastPlaybackCoordinator]()
    
    private init() { }
    
    /// Create or retrieve the voiceBroadcast timeline coordinator for this event and return
    /// a view to be displayed in the timeline
    func buildVoiceBroadcastPlaybackVCForEvent(_ event: MXEvent, senderDisplayName: String?) -> UIViewController? {
        guard let session = session, let room = session.room(withRoomId: event.roomId) else {
            return nil
        }
        
        if let coordinator = coordinatorsForEventIdentifiers[event.eventId] {
            return coordinator.toPresentable()
        }
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        var voiceBroadcastState = VoiceBroadcastInfo.State.stopped
        
        room.state { roomState in
            if let stateEvent = roomState?.stateEvents(with: .custom(VoiceBroadcastSettings.voiceBroadcastInfoContentKeyType))?.last,
               stateEvent.stateKey == event.stateKey,
               let voiceBroadcastInfo = VoiceBroadcastInfo(fromJSON: stateEvent.content),
               (stateEvent.eventId == event.eventId || voiceBroadcastInfo.eventId == event.eventId),
               let state = VoiceBroadcastInfo.State(rawValue: voiceBroadcastInfo.state) {
                   voiceBroadcastState = state
               }
            
            dispatchGroup.leave()
        }
        
        let parameters = VoiceBroadcastPlaybackCoordinatorParameters(session: session,
                                                                     room: room,
                                                                     voiceBroadcastStartEvent: event,
                                                                     voiceBroadcastState: voiceBroadcastState,
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
}
