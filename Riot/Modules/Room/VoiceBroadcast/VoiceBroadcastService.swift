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

/// Voice Broadcast settings.
@objcMembers
final class VoiceBroadcastSettings: NSObject {
    static let eventType = "io.element.voice_broadcast_info"
    
    static let defaultChunkLength = 600
    
    static let voiceBroadcastContentKeyState = "state"
    static let voiceBroadcastContentKeyChunkLength = "chunk_length"
}

/// VoiceBroadcastService handles voice broadcast.
/// Note: Cannot use a protocol because of Objective-C compatibility
@objcMembers
public class VoiceBroadcastService: NSObject {
    
    // MARK: - Properties
    
    public var eventId: String?
    private unowned let session: MXSession
    
    // MARK: - Setup
    
    public init(session: MXSession) {
        self.session = session
    }

    // MARK: - Constants
    private enum State {
        static let started = "started"
        static let paused = "paused"
        static let resumed = "resumed"
        static let stopped = "stopped"
    }
    
    /// Start a voice broadcast.
    /// - Parameters:
    ///   - roomId: The room where the voice broadcast should be started.
    ///   - chunkLength: The length of the voice chunks in seconds.
    ///   - completion: A closure called when the operation completes. Provides the event id of the event generated on the home server on success.
    /// - Returns: a `MXHTTPOperation` instance.
    func startVoiceBroadcast(withRoomId roomId: String, chunkLength: Int? = nil, completion: @escaping (MXResponse<String>) -> Void) -> MXHTTPOperation? {
        return sendVoiceBroadcastInfo(state: State.started, chunkLength: chunkLength, inRoomWithId: roomId) { (response) in
            switch response {
            case .success((let eventIdResponse)):
                self.eventId = eventIdResponse
                completion(.success(eventIdResponse))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Pause a voice broadcast.
    /// - Parameters:
    ///   - roomId: The room where the voice broadcast should be paused.
    ///   - completion: A closure called when the operation completes. Provides the event id of the event generated on the home server on success.
    /// - Returns: a `MXHTTPOperation` instance.
    func pauseVoiceBroadcast(withRoomId roomId: String, completion: @escaping (MXResponse<String>) -> Void) -> MXHTTPOperation? {
        return sendVoiceBroadcastInfo(state: State.paused, inRoomWithId: roomId, completion: completion)
    }
    
    /// resume a voice broadcast.
    /// - Parameters:
    ///   - roomId: The room where the voice broadcast should be resumed.
    ///   - completion: A closure called when the operation completes. Provides the event id of the event generated on the home server on success.
    /// - Returns: a `MXHTTPOperation` instance.
    func resumeVoiceBroadcast(withRoomId roomId: String, completion: @escaping (MXResponse<String>) -> Void) -> MXHTTPOperation? {
        return sendVoiceBroadcastInfo(state: State.resumed, inRoomWithId: roomId, completion: completion)
    }
    
    /// stop a voice broadcast info.
    /// - Parameters:
    ///   - roomId: The room where the voice broadcast should be stopped.
    ///   - completion: A closure called when the operation completes. Provides the event id of the event generated on the home server on success.
    /// - Returns: a `MXHTTPOperation` instance.
    func stopVoiceBroadcast(withRoomId roomId: String, completion: @escaping (MXResponse<String>) -> Void) -> MXHTTPOperation? {
        return sendVoiceBroadcastInfo(state: State.stopped, inRoomWithId: roomId, completion: completion)
    }
    
    private func sendVoiceBroadcastInfo(state: String, chunkLength: Int? = nil, inRoomWithId roomId: String, completion: @escaping (MXResponse<String>) -> Void) -> MXHTTPOperation? {
        guard let userId = self.session.myUserId else {
            completion(.failure(VoiceBroadcastServiceError.missingUserId))
            return nil
        }
        
        let stateKey = userId
        
        let voiceBroadcastContent = VoiceBroadcastEventContent()
        voiceBroadcastContent.state = state
        
        if state != State.started {
            guard let eventId = self.eventId else {
                completion(.failure(VoiceBroadcastServiceError.notStarted))
                return nil
            }
            
            voiceBroadcastContent.eventId = eventId
        } else {
            voiceBroadcastContent.chunkLength = chunkLength ?? VoiceBroadcastSettings.defaultChunkLength
        }
        
        
        guard let stateEventContent = voiceBroadcastContent.jsonDictionary() as? [String: Any] else {
            completion(.failure(VoiceBroadcastServiceError.unknown))
            return nil
        }
        
        return self.session.matrixRestClient.sendStateEvent(toRoom: roomId,
                                                            eventType: .custom(VoiceBroadcastSettings.eventType),
                                                            content: stateEventContent,
                                                            stateKey: stateKey,
                                                            completion: completion)
    }
}

// MARK: - Objective-C interface
extension VoiceBroadcastService {
    
    /// Start a voice broadcast.
    /// - Parameters:
    ///   - roomId: The room where the voice broadcast should be started.
    ///   - success: A closure called when the operation is complete.
    ///   - failure: A closure called  when the operation fails.
    /// - Returns: a `MXHTTPOperation` instance.
    @discardableResult
    @objc public func startVoiceBroadcast(withRoomId roomId: String, success: @escaping (String) -> Void, failure: @escaping (Error) -> Void) -> MXHTTPOperation? {
        return self.startVoiceBroadcast(withRoomId: roomId) { (response) in
            switch response {
            case .success(let object):
                success(object)
            case .failure(let error):
                failure(error)
            }
        }
    }
    
    /// Pause a voice broadcast.
    /// - Parameters:
    ///   - roomId: The room where the voice broadcast should be paused.
    ///   - success: A closure called when the operation is complete.
    ///   - failure: A closure called  when the operation fails.
    /// - Returns: a `MXHTTPOperation` instance.
    @discardableResult
    @objc public func pauseVoiceBroadcast(withRoomId roomId: String, success: @escaping (String) -> Void, failure: @escaping (Error) -> Void) -> MXHTTPOperation? {
        return self.pauseVoiceBroadcast(withRoomId: roomId) { (response) in
            switch response {
            case .success(let object):
                success(object)
            case .failure(let error):
                failure(error)
            }
        }
    }
    
    /// Resume a voice broadcast.
    /// - Parameters:
    ///   - roomId: The room where the voice broadcast should be resumed.
    ///   - success: A closure called when the operation is complete.
    ///   - failure: A closure called  when the operation fails.
    /// - Returns: a `MXHTTPOperation` instance.
    @discardableResult
    @objc public func resumeVoiceBroadcast(withRoomId roomId: String, success: @escaping (String) -> Void, failure: @escaping (Error) -> Void) -> MXHTTPOperation? {
        return self.resumeVoiceBroadcast(withRoomId: roomId) { (response) in
            switch response {
            case .success(let object):
                success(object)
            case .failure(let error):
                failure(error)
            }
        }
    }
    
    /// Stop a voice broadcast.
    /// - Parameters:
    ///   - roomId: The room where the voice broadcast should be stopped.
    ///   - success: A closure called when the operation is complete.
    ///   - failure: A closure called  when the operation fails.
    /// - Returns: a `MXHTTPOperation` instance.
    @discardableResult
    @objc public func stopVoiceBroadcast(withRoomId roomId: String, success: @escaping (String) -> Void, failure: @escaping (Error) -> Void) -> MXHTTPOperation? {
        return self.stopVoiceBroadcast(withRoomId: roomId) { (response) in
            switch response {
            case .success(let object):
                success(object)
            case .failure(let error):
                failure(error)
            }
        }
    }
}

// MARK: - Internal room additions
extension MXRoom {
    /**
     Send a voice broadcast to the room.
     
     - parameters:
         - localURL: the local filesystem path of the file to send.
         - voiceBroadcastInfoEventId: The id of the voice broadcast info event.
         - mimeType: (optional) the mime type of the file. Defaults to `audio/ogg`.
         - duration: the length of the voice message in milliseconds
         - samples: an array of floating point values normalized to [0, 1]
         - threadId: the id of the thread to send the message. nil by default.
         - localEcho: a pointer to a MXEvent object.
     
     This pointer is set to an actual MXEvent object
     containing the local created event which should be used to echo the message in
     the messages list until the resulting event come through the server sync.
     For information, the identifier of the created local event has the prefix
     `kMXEventLocalEventIdPrefix`.
     
     You may specify nil for this parameter if you do not want this information.
     
     You may provide your own MXEvent object, in this case only its send state is updated.
     
     - completion: A block object called when the operation completes.
     - response: Provides the event id of the event generated on the home server on success.
     
     - returns: a `MXHTTPOperation` instance.
     */
    @nonobjc @discardableResult func sendVoiceBroadcast(localURL: URL,
                                                        voiceBroadcastInfoEventId: String,
                                                        mimeType: String?,
                                                        duration: UInt,
                                                        samples: [Float]?,
                                                        threadId: String? = nil,
                                                        localEcho: inout MXEvent?,
                                                        success: @escaping ((String?) -> Void),
                                                        failure: @escaping ((Error?) -> Void)) -> MXHTTPOperation? {
        let boxedSamples = samples?.compactMap { NSNumber(value: $0) }
        
        
        guard let relatesTo = MXEventContentRelatesTo(relationType: MXEventRelationTypeReference, eventId: voiceBroadcastInfoEventId).jsonDictionary() as? [String: Any] else {
            failure(VoiceBroadcastServiceError.unknown)
            return nil
        }

        return __sendVoiceMessage(localURL,
                                  additionalContentParams: [kMXEventRelationRelatesToKey: relatesTo],
                                  mimeType: mimeType,
                                  duration: duration,
                                  samples: boxedSamples,
                                  threadId: threadId,
                                  localEcho: &localEcho,
                                  success: success,
                                  failure: failure,
                                  keepActualFilename: false)
    }
}
