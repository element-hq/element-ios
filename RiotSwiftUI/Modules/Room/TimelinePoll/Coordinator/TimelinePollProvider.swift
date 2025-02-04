//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI

@objcMembers
class TimelinePollProvider: NSObject {
    static let shared = TimelinePollProvider()
    
    var session: MXSession? {
        willSet {
            guard let currentSession = self.session else { return }
            
            if currentSession != newValue {
                // Clear all stored coordinators on new session
                coordinatorsForEventIdentifiers.removeAll()
            }
        }
    }
    var coordinatorsForEventIdentifiers = [String: TimelinePollCoordinator]()
    
    /// Create or retrieve the poll timeline coordinator for this event and return
    /// a view to be displayed in the timeline
    func buildTimelinePollVCForEvent(_ event: MXEvent) -> UIViewController? {
        guard let session = session, let room = session.room(withRoomId: event.roomId) else {
            return nil
        }
        
        if let coordinator = coordinatorsForEventIdentifiers[event.eventId] {
            return coordinator.toPresentable()
        }
        
        let parameters = TimelinePollCoordinatorParameters(session: session, room: room, pollEvent: event)
        guard let coordinator = try? TimelinePollCoordinator(parameters: parameters) else {
            return messageViewController(for: event)
        }
        
        coordinatorsForEventIdentifiers[event.eventId] = coordinator
        
        return coordinator.toPresentable()
    }
    
    /// Retrieve the poll timeline coordinator for the given event or nil if it hasn't been created yet
    func timelinePollCoordinatorForEventIdentifier(_ eventIdentifier: String) -> TimelinePollCoordinator? {
        coordinatorsForEventIdentifiers[eventIdentifier]
    }
    
    func reset() {
        coordinatorsForEventIdentifiers.removeAll()
    }
}

private extension TimelinePollProvider {
    func messageViewController(for event: MXEvent) -> UIViewController? {
        switch event.eventType {
        case .pollEnd:
            return VectorHostingController(rootView: TimelinePollMessageView(message: VectorL10n.pollTimelineReplyEndedPoll))
        default:
            return nil
        }
    }
}
