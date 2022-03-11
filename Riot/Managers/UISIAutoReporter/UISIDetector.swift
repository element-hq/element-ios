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

import MatrixSDK
import Foundation

protocol UISIDetectorDelegate: AnyObject {
    var reciprocateToDeviceEventType: String { get }
    func uisiDetected(source: E2EMessageDetected)
    func uisiReciprocateRequest(source: MXEvent)
}

enum UISIEventSource: String {
    case initialSync = "INITIAL_SYNC"
    case incrementalSync = "INCREMENTAL_SYNC"
    case pagination = "PAGINATION"
}

extension UISIEventSource: Equatable, Codable { }

struct E2EMessageDetected {
    let eventId: String
    let roomId: String
    let senderUserId: String
    let senderDeviceId: String
    let senderKey: String
    let sessionId: String
    let source: UISIEventSource
    
    static func fromEvent(event: MXEvent, roomId: String, source: UISIEventSource) -> E2EMessageDetected {
        return E2EMessageDetected(
            eventId: event.eventId ?? "",
            roomId: roomId,
            senderUserId: event.sender,
            senderDeviceId: event.wireContent["device_id"] as? String ?? "",
            senderKey: event.wireContent["sender_key"] as? String ?? "",
            sessionId: event.wireContent["session_id"] as? String ?? "",
            source: source
        )
    }
}

extension E2EMessageDetected: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(eventId)
        hasher.combine(roomId)
    }
}


class UISIDetector: MXLiveEventListener {
    
    weak var delegate: UISIDetectorDelegate?
    var enabled = false
    
    private var trackedEvents = [String: (E2EMessageDetected, DispatchSourceTimer)]()
    private let dispatchQueue = DispatchQueue(label: "io.element.UISIDetector.queue")
    private static let timeoutSeconds = 30
    
    
    func onLiveEvent(roomId: String, event: MXEvent) {
        guard enabled, event.isEncrypted, event.clear == nil else { return }
        dispatchQueue.async {
            self.handleEventReceived(detectorEvent: E2EMessageDetected.fromEvent(event: event, roomId: roomId, source: .incrementalSync))
        }
    }
    
    func onPaginatedEvent(roomId: String, event: MXEvent) {
        guard enabled, event.isEncrypted, event.clear == nil else { return }
        dispatchQueue.async {
            self.handleEventReceived(detectorEvent: E2EMessageDetected.fromEvent(event: event, roomId: roomId, source: .pagination))
        }
    }
    
    func onEventDecrypted(eventId: String, roomId: String, clearEvent: [AnyHashable: Any]) {
        guard enabled else { return }
        dispatchQueue.async {
            self.unTrack(eventId: eventId, roomId: roomId)
        }
    }
    
    func onEventDecryptionError(eventId: String, roomId: String, error: Error) {
        guard enabled else { return }
        dispatchQueue.async {
            if let event = self.unTrack(eventId: eventId, roomId: roomId) {
                self.triggerUISI(source: event)
            }
        }
    }
    
    func onLiveToDeviceEvent(event: MXEvent) {
        guard enabled, event.type == delegate?.reciprocateToDeviceEventType else { return }
        delegate?.uisiReciprocateRequest(source: event)
    }
    
    private func handleEventReceived(detectorEvent: E2EMessageDetected) {
        guard enabled else { return }
        let trackedId = Self.trackedEventId(roomId: detectorEvent.roomId, eventId: detectorEvent.eventId)
        guard trackedEvents[trackedId] == nil else {
            MXLog.warning("## UISIDetector: Event \(detectorEvent.eventId) is already tracked")
            return
        }
        // track it and start timer
        let timer = DispatchSource.makeTimerSource(queue: dispatchQueue)
        timer.schedule(deadline: .now() + .seconds(Self.timeoutSeconds))
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            self.unTrack(eventId: detectorEvent.eventId, roomId: detectorEvent.roomId)
            MXLog.verbose("## UISIDetector: Timeout on \(detectorEvent.eventId)")
            self.triggerUISI(source: detectorEvent)
        }
        trackedEvents[trackedId] = (detectorEvent, timer)
        timer.activate()
    }
    
    private func triggerUISI(source: E2EMessageDetected) {
        guard enabled else { return }
        MXLog.info("## UISIDetector: Unable To Decrypt \(source)")
        self.delegate?.uisiDetected(source: source)
    }

    @discardableResult private func unTrack(eventId: String, roomId: String) -> E2EMessageDetected? {
        let trackedId = Self.trackedEventId(roomId: roomId, eventId: eventId)
        guard let (event, timer) = trackedEvents[trackedId]
        else {
            return nil
        }
        trackedEvents[trackedId] = nil
        timer.cancel()
        return event
    }
    
    static func trackedEventId(roomId: String, eventId: String) -> String {
        return "\(roomId)-\(eventId)"
    }
                                        
}
