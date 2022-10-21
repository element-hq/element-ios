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

/// VoiceBroadcastService handles voice broadcast.
/// Note: Cannot use a protocol because of Objective-C compatibility
@objcMembers
public class VoiceBroadcastService: NSObject {
    
    // MARK: - Properties
    
    public private(set) var voiceBroadcastInfoEventId: String?
    public let room: MXRoom
    public private(set) var state: VoiceBroadcastInfo.State
    
    // MARK: - Setup
    
    public init(room: MXRoom, state: VoiceBroadcastInfo.State) {
        self.room = room
        self.state = state
    }

    // MARK: - Constants
    
    // MARK: - Public
    
    // MARK: Voice broadcast info
        
    /// Start a voice broadcast.
    /// - Parameters:
    ///   - completion: A closure called when the operation completes. Provides the event id of the event generated on the home server on success.
    /// - Returns: a `MXHTTPOperation` instance.
    func startVoiceBroadcast(completion: @escaping (MXResponse<String?>) -> Void) -> MXHTTPOperation? {
        return sendVoiceBroadcastInfo(state: VoiceBroadcastInfo.State.started) { [weak self] response in
            guard let self = self else { return }
            
            switch response {
            case .success((let eventIdResponse)):
                self.voiceBroadcastInfoEventId = eventIdResponse
                completion(.success(eventIdResponse))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Pause a voice broadcast.
    /// - Parameters:
    ///   - completion: A closure called when the operation completes. Provides the event id of the event generated on the home server on success.
    /// - Returns: a `MXHTTPOperation` instance.
    func pauseVoiceBroadcast(completion: @escaping (MXResponse<String?>) -> Void) -> MXHTTPOperation? {
        return sendVoiceBroadcastInfo(state: VoiceBroadcastInfo.State.paused, completion: completion)
    }
    
    /// resume a voice broadcast.
    /// - Parameters:
    ///   - completion: A closure called when the operation completes. Provides the event id of the event generated on the home server on success.
    /// - Returns: a `MXHTTPOperation` instance.
    func resumeVoiceBroadcast(completion: @escaping (MXResponse<String?>) -> Void) -> MXHTTPOperation? {
        return sendVoiceBroadcastInfo(state: VoiceBroadcastInfo.State.resumed, completion: completion)
    }
    
    /// stop a voice broadcast info.
    /// - Parameters:
    ///   - completion: A closure called when the operation completes. Provides the event id of the event generated on the home server on success.
    /// - Returns: a `MXHTTPOperation` instance.
    func stopVoiceBroadcast(completion: @escaping (MXResponse<String?>) -> Void) -> MXHTTPOperation? {
        return sendVoiceBroadcastInfo(state: VoiceBroadcastInfo.State.stopped, completion: completion)
    }
    
    func getState() -> String {
        return self.state.rawValue
    }
    
    // MARK: Voice broadcast chunk
    
    /// Send a bunch of a voice broadcast.
    ///
    /// While sending, a fake event will be echoed in the messages list.
    /// Once complete, this local echo will be replaced by the event saved by the homeserver.
    ///
    /// - Parameters:
    ///   - audioFileLocalURL: the local filesystem path of the audio file to send.
    ///   - mimeType: (optional) the mime type of the file. Defaults to `audio/ogg`
    ///   - duration: the length of the voice message in milliseconds
    ///   - samples: an array of floating point values normalized to [0, 1], boxed within NSNumbers
    ///   - sequence: value of the chunk sequence.
    ///   - success: A block object called when the operation succeeds. It returns the event id of the event generated on the homeserver
    ///   - failure: A block object called when the operation fails.
    func sendChunkOfVoiceBroadcast(audioFileLocalURL: URL,
                                   mimeType: String?,
                                   duration: UInt,
                                   samples: [Float]?,
                                   sequence: UInt,
                                   success: @escaping ((String?) -> Void),
                                   failure: @escaping ((Error?) -> Void)) {
        guard let voiceBroadcastInfoEventId = self.voiceBroadcastInfoEventId else {
            return failure(VoiceBroadcastServiceError.notStarted)
        }
        
        self.room.sendChunkOfVoiceBroadcast(localURL: audioFileLocalURL,
                                            voiceBroadcastInfoEventId: voiceBroadcastInfoEventId,
                                            mimeType: mimeType,
                                            duration: duration,
                                            samples: samples,
                                            sequence: sequence,
                                            success: success,
                                            failure: failure)
    }
    
    // MARK: - Private
    
    private func sendVoiceBroadcastInfo(state: VoiceBroadcastInfo.State, completion: @escaping (MXResponse<String?>) -> Void) -> MXHTTPOperation? {
        guard let userId = self.room.mxSession.myUserId else {
            completion(.failure(VoiceBroadcastServiceError.missingUserId))
            return nil
        }
        
        let stateKey = userId
        
        let voiceBroadcastInfo = VoiceBroadcastInfo()
        
        voiceBroadcastInfo.deviceId = self.room.mxSession.myDeviceId
        
        voiceBroadcastInfo.state = state.rawValue
        
        if state != VoiceBroadcastInfo.State.started {
            guard let voiceBroadcastInfoEventId = self.voiceBroadcastInfoEventId else {
                completion(.failure(VoiceBroadcastServiceError.notStarted))
                return nil
            }
            
            voiceBroadcastInfo.eventId = voiceBroadcastInfoEventId
        } else {
            voiceBroadcastInfo.chunkLength = BuildSettings.voiceBroadcastChunkLength
        }
        
        guard let stateEventContent = voiceBroadcastInfo.jsonDictionary() as? [String: Any] else {
            completion(.failure(VoiceBroadcastServiceError.unknown))
            return nil
        }
        
        return self.room.sendStateEvent(.custom(VoiceBroadcastSettings.voiceBroadcastInfoContentKeyType),
                                        content: stateEventContent, stateKey: stateKey) { [weak self] response in
            guard let self = self else { return }
            
            switch response {
            case .success(let object):
                self.state = state
                completion(.success(object))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Objective-C interface
extension VoiceBroadcastService {
    
    /// Start a voice broadcast.
    /// - Parameters:
    ///   - success: A closure called when the operation is complete.
    ///   - failure: A closure called  when the operation fails.
    /// - Returns: a `MXHTTPOperation` instance.
    @discardableResult
    @objc public func startVoiceBroadcast(success: @escaping (String?) -> Void, failure: @escaping (Error) -> Void) -> MXHTTPOperation? {
        return self.startVoiceBroadcast { response in
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
    ///   - success: A closure called when the operation is complete.
    ///   - failure: A closure called  when the operation fails.
    /// - Returns: a `MXHTTPOperation` instance.
    @discardableResult
    @objc public func pauseVoiceBroadcast(success: @escaping (String?) -> Void, failure: @escaping (Error) -> Void) -> MXHTTPOperation? {
        return self.pauseVoiceBroadcast { response in
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
    ///   - success: A closure called when the operation is complete.
    ///   - failure: A closure called  when the operation fails.
    /// - Returns: a `MXHTTPOperation` instance.
    @discardableResult
    @objc public func resumeVoiceBroadcast(success: @escaping (String?) -> Void, failure: @escaping (Error) -> Void) -> MXHTTPOperation? {
        return self.resumeVoiceBroadcast { response in
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
    ///   - success: A closure called when the operation is complete.
    ///   - failure: A closure called  when the operation fails.
    /// - Returns: a `MXHTTPOperation` instance.
    @discardableResult
    @objc public func stopVoiceBroadcast(success: @escaping (String?) -> Void, failure: @escaping (Error) -> Void) -> MXHTTPOperation? {
        return self.stopVoiceBroadcast { response in
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
    
    /// Send a voice broadcast to the room.
    /// - Parameters:
    ///   - localURL: the local filesystem path of the file to send.
    ///   - voiceBroadcastInfoEventId: The id of the voice broadcast info event.
    ///   - mimeType: (optional) the mime type of the file. Defaults to `audio/ogg`.
    ///   - duration: the length of the voice message in milliseconds
    ///   - samples: an array of floating point values normalized to [0, 1]
    ///   - threadId: the id of the thread to send the message. nil by default.
    ///   - sequence: value of the chunk sequence.
    ///   - success: A closure called when the operation is complete.
    ///   - failure: A closure called  when the operation fails.
    /// - Returns: a `MXHTTPOperation` instance.
    @nonobjc @discardableResult func sendChunkOfVoiceBroadcast(localURL: URL,
                                                               voiceBroadcastInfoEventId: String,
                                                               mimeType: String?,
                                                               duration: UInt,
                                                               samples: [Float]?,
                                                               threadId: String? = nil,
                                                               sequence: UInt,
                                                               success: @escaping ((String?) -> Void),
                                                               failure: @escaping ((Error?) -> Void)) -> MXHTTPOperation? {
        let boxedSamples = samples?.compactMap { NSNumber(value: $0) }
        
        
        guard let relatesTo = MXEventContentRelatesTo(relationType: MXEventRelationTypeReference,
                                                      eventId: voiceBroadcastInfoEventId).jsonDictionary() as? [String: Any] else {
            failure(VoiceBroadcastServiceError.unknown)
            return nil
        }
        
        let sequenceValue = [VoiceBroadcastSettings.voiceBroadcastContentKeyChunkSequence: sequence]

        return __sendVoiceMessage(localURL,
                                  additionalContentParams: [kMXEventRelationRelatesToKey: relatesTo,
                                                            VoiceBroadcastSettings.voiceBroadcastContentKeyChunkType: sequenceValue],
                                  mimeType: mimeType,
                                  duration: duration,
                                  samples: boxedSamples,
                                  threadId: threadId,
                                  localEcho: nil,
                                  success: success,
                                  failure: failure,
                                  keepActualFilename: false)
    }
}
