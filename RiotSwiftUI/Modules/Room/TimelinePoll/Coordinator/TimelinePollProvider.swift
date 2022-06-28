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

import Foundation

class TimelinePollProvider {
    static let shared = TimelinePollProvider()
    
    var session: MXSession?
    var coordinatorsForEventIdentifiers = [String: TimelinePollCoordinator]()
    
    private init() {
        
    }
    
    /// Create or retrieve the poll timeline coordinator for this event and return
    /// a view to be displayed in the timeline
    func buildTimelinePollViewForEvent(_ event: MXEvent) -> UIView? {
        guard let session = session, let room = session.room(withRoomId: event.roomId) else {
            return nil
        }
        
        if let coordinator = coordinatorsForEventIdentifiers[event.eventId] {
            return coordinator.toPresentable().view
        }
        
        let parameters = TimelinePollCoordinatorParameters(session: session, room: room, pollStartEvent: event)
        guard let coordinator = try? TimelinePollCoordinator(parameters: parameters) else {
            return nil
        }
        
        coordinatorsForEventIdentifiers[event.eventId] = coordinator
        
        return coordinator.toPresentable().view
    }
    
    /// Retrieve the poll timeline coordinator for the given event or nil if it hasn't been created yet
    func timelinePollCoordinatorForEventIdentifier(_ eventIdentifier: String) -> TimelinePollCoordinator? {
        return coordinatorsForEventIdentifiers[eventIdentifier]
    }
}
