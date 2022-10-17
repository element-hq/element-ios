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

public protocol VoiceBroadcastAggregatorDelegate: AnyObject {
    func voiceBroadcastAggregatorDidStartLoading(_ aggregator: VoiceBroadcastAggregator)
    func voiceBroadcastAggregatorDidEndLoading(_ aggregator: VoiceBroadcastAggregator)
    func voiceBroadcastAggregator(_ aggregator: VoiceBroadcastAggregator, didFailWithError: Error)
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
    
    private var referenceEventsListener: Any?
    
    private var events: [MXEvent] = []
    
    public private(set) var voiceBroadcast: VoiceBroadcastProtocol! {
        didSet {
            delegate?.voiceBroadcastAggregatorDidUpdateData(self)
        }
    }
    
    public var delegate: VoiceBroadcastAggregatorDelegate?
    
    deinit {
        if let referenceEventsListener = referenceEventsListener {
            room.removeListener(referenceEventsListener)
        }
    }
    
    public init(session: MXSession, room: MXRoom, voiceBroadcastStartEventId: String) throws {
        self.session = session
        self.room = room
        self.voiceBroadcastStartEventId = voiceBroadcastStartEventId
        self.voiceBroadcastBuilder = VoiceBroadcastBuilder()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleRoomDataFlush), name: NSNotification.Name.mxRoomDidFlushData, object: self.room)
        
        try buildVoiceBroadcastStartContent()
    }
    
    private func buildVoiceBroadcastStartContent() throws {
        guard let event = session.store.event(withEventId: voiceBroadcastStartEventId, inRoom: room.roomId),
              let eventContent = VoiceBroadcastInfo(fromJSON: event.content)
        else {
            throw VoiceBroadcastAggregatorError.invalidVoiceBroadcastStartEvent
        }
        
        voiceBroadcastInfoStartEventContent = eventContent
        
        voiceBroadcast = voiceBroadcastBuilder.build(voiceBroadcastStartEventContent: eventContent,
                                 events: events,
                                 currentUserIdentifier: session.myUserId)
        
        reloadVoiceBroadcastData()
    }
    
    @objc private func handleRoomDataFlush(sender: Notification) {
        guard let room = sender.object as? MXRoom, room == self.room else {
            return
        }
        
        reloadVoiceBroadcastData()
    }
    
    private func reloadVoiceBroadcastData() {
        delegate?.voiceBroadcastAggregatorDidStartLoading(self)
        
        session.aggregations.referenceEvents(forEvent: voiceBroadcastStartEventId, inRoom: room.roomId, from: nil, limit: -1) { [weak self] response in
            guard let self = self else {
                return
            }
            
            self.events.removeAll()
            
            self.events.append(contentsOf: response.chunk)
            
            
            let eventTypes = [VoiceBroadcastSettings.eventType, kMXEventTypeStringRoomMessage]
            self.referenceEventsListener = self.room.listen(toEventsOfTypes: eventTypes) { [weak self] event, direction, state in
                // TODO: check sender id to block fake voice broadcast chunk
                guard let self = self,
                      let relatedEventId = event.relatesTo?.eventId,
                      relatedEventId == self.voiceBroadcastStartEventId,
                      event.content[VoiceBroadcastSettings.voiceBroadcastContentKeyChunkType] != nil else {
                    return
                }
                
                self.events.append(event)
                
                self.voiceBroadcast = self.voiceBroadcastBuilder.build(voiceBroadcastStartEventContent: self.voiceBroadcastInfoStartEventContent,
                                                   events: self.events,
                                                   currentUserIdentifier: self.session.myUserId)
            } as Any
            
            self.voiceBroadcast = self.voiceBroadcastBuilder.build(voiceBroadcastStartEventContent: self.voiceBroadcastInfoStartEventContent,
                                               events: self.events,
                                               currentUserIdentifier: self.session.myUserId)
            
            self.delegate?.voiceBroadcastAggregatorDidEndLoading(self)
            
        } failure: { [weak self] error in
            guard let self = self else {
                return
            }
            
            self.delegate?.voiceBroadcastAggregator(self, didFailWithError: error)
        }
    }
}
