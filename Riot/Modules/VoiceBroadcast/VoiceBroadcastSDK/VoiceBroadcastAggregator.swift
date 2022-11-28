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
    
    private var referenceEventsListener: Any?
    
    private var events: [MXEvent] = []
    
    public private(set) var voiceBroadcast: VoiceBroadcast! {
        didSet {
            delegate?.voiceBroadcastAggregatorDidUpdateData(self)
        }
    }
    
    private(set) var launchState: VoiceBroadcastAggregatorLaunchState = .idle
    public private(set) var voiceBroadcastState: VoiceBroadcastInfoState
    public var delegate: VoiceBroadcastAggregatorDelegate?
    
    deinit {
        if let referenceEventsListener = referenceEventsListener {
            room.removeListener(referenceEventsListener)
        }
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
    
    @objc private func handleRoomDataFlush(sender: Notification) {
        guard let room = sender.object as? MXRoom, room == self.room else {
            return
        }
        
        // TODO: What is the impact on room data flush on voice broadcast audio streaming?
        MXLog.warning("[VoiceBroadcastAggregator] handleRoomDataFlush is not supported yet")
    }
    
    private func updateState() {
        self.room.state { roomState in
            guard let event = roomState?.stateEvents(with: .custom(VoiceBroadcastSettings.voiceBroadcastInfoContentKeyType))?.last,
                  event.stateKey == self.voiceBroadcastSenderId,
                  let voiceBroadcastInfo = VoiceBroadcastInfo(fromJSON: event.content),
                  (event.eventId == self.voiceBroadcastStartEventId || voiceBroadcastInfo.voiceBroadcastId == self.voiceBroadcastStartEventId),
                  let state = VoiceBroadcastInfoState(rawValue: voiceBroadcastInfo.state) else {
                return
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
            
            let filteredChunk = response.chunk.filter { event in
                event.sender == self.voiceBroadcastSenderId &&
                event.content[VoiceBroadcastSettings.voiceBroadcastContentKeyChunkType] != nil
            }
            
            self.events.append(contentsOf: filteredChunk)
            
            let eventTypes = [VoiceBroadcastSettings.voiceBroadcastInfoContentKeyType, kMXEventTypeStringRoomMessage]
            self.referenceEventsListener = self.room.listen(toEventsOfTypes: eventTypes) { [weak self] event, direction, state in
                
                guard let self = self else {
                    return
                }
                
                if event.eventType == .roomMessage {
                    guard event.sender == self.voiceBroadcastSenderId,
                          let relatedEventId = event.relatesTo?.eventId,
                          relatedEventId == self.voiceBroadcastStartEventId,
                          event.content[VoiceBroadcastSettings.voiceBroadcastContentKeyChunkType] != nil else {
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
                } else {
                    self.updateState()
                }
            } as Any
            
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
}
