// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// VoiceBroadcastAggregator errors
public enum VoiceBroadcastAggregatorError: Error {
    case invalidVoiceBroadcastStartEvent
}

public enum VoiceBroadcastAggregatorLaunchState {
    case idle
    case starting
    case loaded
    case error
}

public protocol VoiceBroadcastAggregatorDelegate: AnyObject {
    func voiceBroadcastAggregatorDidStartLoading(_ aggregator: VoiceBroadcastAggregator)
    func voiceBroadcastAggregatorDidEndLoading(_ aggregator: VoiceBroadcastAggregator)
    func voiceBroadcastAggregator(_ aggregator: VoiceBroadcastAggregator, didFailWithError: Error)
    func voiceBroadcastAggregator(_ aggregator: VoiceBroadcastAggregator, didReceiveChunk: VoiceBroadcastChunk)
    func voiceBroadcastAggregator(_ aggregator: VoiceBroadcastAggregator, didReceiveState: VoiceBroadcastInfoState)
    func voiceBroadcastAggregatorDidUpdateData(_ aggregator: VoiceBroadcastAggregator)
    func voiceBroadcastAggregator(_ aggregator: VoiceBroadcastAggregator, didUpdateUndecryptableEventList events: Set<MXEvent>)
}

/**
 Responsible for building voice broadcast models out of the original voice broadcast start event and listen to replies.
 It will listen for voice broadcast chunk events on the live timline and update the built models accordingly.
 I will also listen for `mxRoomDidFlushData` and reload all data to avoid gappy sync problems
*/

public class VoiceBroadcastAggregator {
    
    private let session: MXSession
    private let room: MXRoom
    private let voiceBroadcastStartEventId: String
    private let voiceBroadcastBuilder: VoiceBroadcastBuilder
    
    private var voiceBroadcastInfoStartEventContent: VoiceBroadcastInfo!
    private var voiceBroadcastSenderId: String!
    
    public private(set) var voiceBroadcastLastChunkSequence: Int = 0
    
    private var referenceEventsListener: Any?
    
    private var events: [MXEvent] = []
    private var undecryptableEvents: Set<MXEvent> = []
    
    public private(set) var voiceBroadcast: VoiceBroadcast! {
        didSet {
            delegate?.voiceBroadcastAggregatorDidUpdateData(self)
        }
    }
    
    private(set) var launchState: VoiceBroadcastAggregatorLaunchState = .idle
    public private(set) var voiceBroadcastState: VoiceBroadcastInfoState
    public var delegate: VoiceBroadcastAggregatorDelegate?
    
    deinit {
        self.stop()
    }
    
    public init(session: MXSession, room: MXRoom, voiceBroadcastStartEventId: String, voiceBroadcastState: VoiceBroadcastInfoState) throws {
        self.session = session
        self.room = room
        self.voiceBroadcastStartEventId = voiceBroadcastStartEventId
        self.voiceBroadcastState = voiceBroadcastState
        self.voiceBroadcastBuilder = VoiceBroadcastBuilder()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleRoomDataFlush), name: NSNotification.Name.mxRoomDidFlushData, object: self.room)

        try buildVoiceBroadcastStartContent()
    }
        
    private func buildVoiceBroadcastStartContent() throws {
        guard let event = session.store.event(withEventId: voiceBroadcastStartEventId, inRoom: room.roomId),
              let eventContent = VoiceBroadcastInfo(fromJSON: event.content),
              let senderId = event.stateKey
        else {
            throw VoiceBroadcastAggregatorError.invalidVoiceBroadcastStartEvent
        }
        
        voiceBroadcastInfoStartEventContent = eventContent
        voiceBroadcastSenderId = senderId
        
        voiceBroadcast = voiceBroadcastBuilder.build(mediaManager: session.mediaManager,
                                                     voiceBroadcastStartEventId: voiceBroadcastStartEventId,
                                                     voiceBroadcastInvoiceBroadcastStartEventContent: eventContent,
                                                     events: events,
                                                     currentUserIdentifier: session.myUserId)
    }
    
    private func registerEventDidDecryptNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(eventDidDecrypt), name: NSNotification.Name.mxEventDidDecrypt, object: nil)
    }
    
    @objc private func handleRoomDataFlush(sender: Notification) {
        guard let room = sender.object as? MXRoom, room == self.room else {
            return
        }
        
        // TODO: What is the impact on room data flush on voice broadcast audio streaming?
        MXLog.warning("[VoiceBroadcastAggregator] handleRoomDataFlush is not supported yet")
    }
    
    @objc private func eventDidDecrypt(sender: Notification) {
        guard let event = sender.object as? MXEvent else { return }

        if undecryptableEvents.remove(event) != nil {
            delegate?.voiceBroadcastAggregator(self, didUpdateUndecryptableEventList: undecryptableEvents)
        }

        self.handleEvent(event: event)
    }
    
    private func handleEvent(event: MXEvent, direction: MXTimelineDirection? = nil, roomState: MXRoomState? = nil) {
        switch event.eventType {
        case .roomMessage:
            self.updateVoiceBroadcast(event: event)
        case .custom:
            if event.type == VoiceBroadcastSettings.voiceBroadcastInfoContentKeyType {
                self.updateState()
            }
        default:
            break
        }
    }
    
    private func updateVoiceBroadcast(event: MXEvent) {
        guard event.sender == self.voiceBroadcastSenderId,
              let relatedEventId = event.relatesTo?.eventId,
              relatedEventId == self.voiceBroadcastStartEventId else {
            return
        }
        
        // Handle decryption errors
        if event.decryptionError != nil {
            self.undecryptableEvents.insert(event)
            self.delegate?.voiceBroadcastAggregator(self, didUpdateUndecryptableEventList: self.undecryptableEvents)
            
            return
        }
        
        guard event.content[VoiceBroadcastSettings.voiceBroadcastContentKeyChunkType] != nil else {
            return
        }
        
        if !self.events.contains(where: { $0.eventId == event.eventId }) {
            self.events.append(event)
            MXLog.debug("[VoiceBroadcastAggregator] Got a new chunk for broadcast \(relatedEventId). Total: \(self.events.count)")
            
            if let chunk = self.voiceBroadcastBuilder.buildChunk(event: event, mediaManager: self.session.mediaManager, voiceBroadcastStartEventId: self.voiceBroadcastStartEventId) {
                self.delegate?.voiceBroadcastAggregator(self, didReceiveChunk: chunk)
            }
            
            self.voiceBroadcast = self.voiceBroadcastBuilder.build(mediaManager: self.session.mediaManager,
                                                                   voiceBroadcastStartEventId: self.voiceBroadcastStartEventId,
                                                                   voiceBroadcastInvoiceBroadcastStartEventContent: self.voiceBroadcastInfoStartEventContent,
                                                                   events: self.events,
                                                                   currentUserIdentifier: self.session.myUserId)
        }
    }
    
    private func updateState() {
        // This update is useful only in case of a live broadcast (The aggregator considers the broadcast stopped by default)
        // We will consider here only the most recent voice broadcast state event
        self.room.lastVoiceBroadcastStateEvent { event in
            guard let event = event,
                  event.stateKey == self.voiceBroadcastSenderId,
                  let voiceBroadcastInfo = VoiceBroadcastInfo(fromJSON: event.content),
                  (event.eventId == self.voiceBroadcastStartEventId || voiceBroadcastInfo.voiceBroadcastId == self.voiceBroadcastStartEventId),
                  let state = VoiceBroadcastInfoState(rawValue: voiceBroadcastInfo.state) else {
                return
            }
            // For .pause and .stopped, update the last chunk sequence
            if [.stopped, .paused].contains(state) {
                self.voiceBroadcastLastChunkSequence = voiceBroadcastInfo.lastChunkSequence
            }
            self.delegate?.voiceBroadcastAggregator(self, didReceiveState: state)
        }
    }
    
    func start() {
        guard launchState == .idle else {
            return
        }
        launchState = .starting
        
        delegate?.voiceBroadcastAggregatorDidStartLoading(self)
        
        session.aggregations.referenceEvents(forEvent: voiceBroadcastStartEventId, inRoom: room.roomId, from: nil, limit: -1) { [weak self] response in
            guard let self = self else {
                return
            }
            
            self.events.removeAll()
            self.undecryptableEvents.removeAll()
            self.voiceBroadcastLastChunkSequence = 0
            
            let filteredChunk = response.chunk.filter { event in
                event.sender == self.voiceBroadcastSenderId &&
                event.content[VoiceBroadcastSettings.voiceBroadcastContentKeyChunkType] != nil
            }
            self.events.append(contentsOf: filteredChunk)

            let decryptionFailure = response.chunk.filter { event in
                event.sender == self.voiceBroadcastSenderId &&
                event.decryptionError != nil
            }
            self.undecryptableEvents.formUnion(decryptionFailure)
            self.delegate?.voiceBroadcastAggregator(self, didUpdateUndecryptableEventList: self.undecryptableEvents)
                        
            let eventTypes = [VoiceBroadcastSettings.voiceBroadcastInfoContentKeyType, kMXEventTypeStringRoomMessage]
            self.referenceEventsListener = self.room.listen(toEventsOfTypes: eventTypes, onEvent: { [weak self] event, direction, roomState in
                self?.handleEvent(event: event, direction: direction, roomState: roomState)
            }) as Any
            self.registerEventDidDecryptNotification()
            
            self.events.forEach { event in
                guard let chunk = self.voiceBroadcastBuilder.buildChunk(event: event, mediaManager: self.session.mediaManager, voiceBroadcastStartEventId: self.voiceBroadcastStartEventId) else {
                    return
                }
                self.delegate?.voiceBroadcastAggregator(self, didReceiveChunk: chunk)
            }
            
            self.updateState()
          
            self.voiceBroadcast = self.voiceBroadcastBuilder.build(mediaManager: self.session.mediaManager,
                                                                   voiceBroadcastStartEventId: self.voiceBroadcastStartEventId,
                                                                   voiceBroadcastInvoiceBroadcastStartEventContent: self.voiceBroadcastInfoStartEventContent,
                                                                   events: self.events,
                                                                   currentUserIdentifier: self.session.myUserId)
            
            MXLog.debug("[VoiceBroadcastAggregator] Start aggregation with \(self.voiceBroadcast.chunks.count) chunks for broadcast \(self.voiceBroadcastStartEventId)")
            
            self.launchState = .loaded
            self.delegate?.voiceBroadcastAggregatorDidEndLoading(self)
            
        } failure: { [weak self] error in
            guard let self = self else {
                return
            }
            
            MXLog.error("[VoiceBroadcastAggregator] start failed", context: error)
            self.launchState = .error
            self.delegate?.voiceBroadcastAggregator(self, didFailWithError: error)
        }
    }
    
    func stop() {
        if let referenceEventsListener = referenceEventsListener {
            room.removeListener(referenceEventsListener)
        }
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.mxEventDidDecrypt, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.mxRoomDidFlushData, object: nil)
    }
}
