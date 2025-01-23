//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import MatrixSDK
import Foundation

protocol UISIDetectorDelegate: AnyObject {
    var reciprocateToDeviceEventType: String { get }
    func uisiDetected(source: UISIDetectedMessage)
    func uisiReciprocateRequest(source: MXEvent)
}

struct UISIDetectedMessage {
    let eventId: String
    let roomId: String
    let senderUserId: String
    let senderDeviceId: String
    let senderKey: String
    let sessionId: String
    
    static func fromEvent(event: MXEvent) -> UISIDetectedMessage {
        return UISIDetectedMessage(
            eventId: event.eventId ?? "",
            roomId: event.roomId,
            senderUserId: event.sender,
            senderDeviceId: event.wireContent["device_id"] as? String ?? "",
            senderKey: event.wireContent["sender_key"] as? String ?? "",
            sessionId: event.wireContent["session_id"] as? String ?? ""
        )
    }
}

/// Detects decryption errors that occur and don't recover within a grace period.
/// see `UISIDetectorDelegate` for listening to detections.
class UISIDetector: MXLiveEventListener {
    
    weak var delegate: UISIDetectorDelegate?
    var enabled = false
    
    var initialSyncCompleted = false
    private var trackedUISIs = [String: DispatchSourceTimer]()
    private let dispatchQueue = DispatchQueue(label: "io.element.UISIDetector.queue")
    private static let gracePeriodSeconds = 30
    
    // MARK: - Public
    
    func onSessionStateChanged(state: MXSessionState) {
        dispatchQueue.async {
            self.initialSyncCompleted = state == .running
        }
    }
    
    func onLiveEventDecryptionAttempted(event: MXEvent, result: MXEventDecryptionResult) {
        guard enabled, let eventId = event.eventId, let roomId = event.roomId else { return }
        dispatchQueue.async {
            let trackedId = Self.trackedEventId(roomId: eventId, eventId: roomId)
            
            if let timer = self.trackedUISIs[trackedId],
               result.clearEvent != nil {
                // successfully decrypted during grace period, cancel timer.
                self.trackedUISIs[trackedId] = nil
                timer.cancel()
                return
            }
            
            guard self.initialSyncCompleted,
                  result.clearEvent == nil
            else { return }
            
            // track uisi and report it only if it is not decrypted before grade period ends
            let timer = DispatchSource.makeTimerSource(queue: self.dispatchQueue)
            timer.schedule(deadline: .now() + .seconds(Self.gracePeriodSeconds))
            timer.setEventHandler { [weak self] in
                guard let self = self else { return }
                self.trackedUISIs[trackedId] = nil
                MXLog.verbose("[UISIDetector] onLiveEventDecryptionAttempted: Timeout on \(eventId)")
                self.triggerUISI(source: UISIDetectedMessage.fromEvent(event: event))
            }
            self.trackedUISIs[trackedId] = timer
            timer.activate()
        }
    }
    
    func onLiveToDeviceEvent(event: MXEvent) {
        guard enabled, event.type == delegate?.reciprocateToDeviceEventType else { return }
        delegate?.uisiReciprocateRequest(source: event)
    }
    
    // MARK: - Private
    
    private func triggerUISI(source: UISIDetectedMessage) {
        guard enabled else { return }
        MXLog.info("[UISIDetector] triggerUISI: Unable To Decrypt \(source)")
        self.delegate?.uisiDetected(source: source)
    }
    
    // MARK: - Static
    
    private static func trackedEventId(roomId: String, eventId: String) -> String {
        return "\(roomId)-\(eventId)"
    }
}
