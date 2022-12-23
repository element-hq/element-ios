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

@objcMembers
class TimelinePollProvider: NSObject {
    static let shared = TimelinePollProvider()
    
    private var decryptionErrorsObserver: NSObjectProtocol?
    
    var session: MXSession? {
        willSet {
            guard newValue != session else {
                return
            }
            
            reset()
            updateDecryptionErrorsObserver(newSession: newValue)
        }
    }
    var coordinatorsForEventIdentifiers = [String: TimelinePollCoordinator]()
    var erroredEventIdsByRelatedEvent = [String: Set<String>]()
    
    /// Create or retrieve the poll timeline coordinator for this event and return
    /// a view to be displayed in the timeline
    func buildTimelinePollVCForEvent(_ event: MXEvent) -> UIViewController? {
        guard let session = session, let room = session.room(withRoomId: event.roomId) else {
            return nil
        }
        
        let coordinator: TimelinePollCoordinator
        
        if let cachedCoordinator = coordinatorsForEventIdentifiers[event.eventId] {
            coordinator = cachedCoordinator
        } else {
            let parameters = TimelinePollCoordinatorParameters(session: session, room: room, pollStartEvent: event)
            guard let newCoordinator = try? TimelinePollCoordinator(parameters: parameters) else {
                return nil
            }
            coordinator = newCoordinator
            coordinatorsForEventIdentifiers[event.eventId] = newCoordinator
        }
        
        coordinator.handleErroredRelatedEventsIds(erroredEventIdsByRelatedEvent[event.eventId], to: event.eventId)
        
        return coordinator.toPresentable()
    }
    
    /// Retrieve the poll timeline coordinator for the given event or nil if it hasn't been created yet
    func timelinePollCoordinatorForEventIdentifier(_ eventIdentifier: String) -> TimelinePollCoordinator? {
        coordinatorsForEventIdentifiers[eventIdentifier]
    }
    
    func reset() {
        coordinatorsForEventIdentifiers.removeAll()
        erroredEventIdsByRelatedEvent.removeAll()
        removeObserverIfNeeded()
    }
}

private extension TimelinePollProvider {
    func updateDecryptionErrorsObserver(newSession: MXSession?) {
        removeObserverIfNeeded()
        
        guard let session = newSession else {
            return
        }
        
        decryptionErrorsObserver = NotificationCenter.default.addObserver(forName: .mxSessionDidFailToDecryptEvents, object: session, queue: .main) { [weak self] notification in
            guard
                let self = self,
                notification.object as? MXSession == session,
                let failedEvents = notification.userInfo?[kMXSessionNotificationEventsArrayKey] as? [MXEvent]
            else {
                return
            }
            
            self.storeErroredEvents(failedEvents)
        }
    }
    
    func removeObserverIfNeeded() {
        decryptionErrorsObserver.map(NotificationCenter.default.removeObserver(_:))
    }
    
    func storeErroredEvents(_ events: [MXEvent]) {
        let groupedByParentEvents = events.group(by: \.relatesTo?.eventId)
        
        for (parentEvent, childrenEvents) in groupedByParentEvents {
            guard let parentEvent = parentEvent else {
                continue
            }
            
            let currentEvents = erroredEventIdsByRelatedEvent[parentEvent] ?? []
            let updatedEvents = currentEvents.union(childrenEvents.map(\.eventId))
            self.erroredEventIdsByRelatedEvent[parentEvent] = updatedEvents
            coordinatorsForEventIdentifiers[parentEvent]?.handleErroredRelatedEventsIds(updatedEvents, to: parentEvent)
        }
    }
}
