//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// VoiceBroadcastService handles voice broadcast.
/// Note: Cannot use a protocol because of Objective-C compatibility
@objcMembers
public class VoiceBroadcastService: NSObject {
    
    // MARK: - Properties
    
    public let room: MXRoom
    public private(set) var voiceBroadcastId: String?
    public private(set) var state: VoiceBroadcastInfoState
    // Mechanism to process one call of sendVoiceBroadcastInfo() at a time
    private let asyncTaskQueue: MXAsyncTaskQueue
    
    // MARK: - Setup
    
    public init(room: MXRoom, state: VoiceBroadcastInfoState) {
        self.room = room
        self.state = state
        self.asyncTaskQueue = MXAsyncTaskQueue(label: "VoiceBroadcastServiceQueueEventSerialQueue-" + MXTools.generateSecret())
    }

    // MARK: - Constants
    
    // MARK: - Public
    
    // MARK: Voice broadcast info
        
    /// Start a voice broadcast.
    /// - Parameters:
    ///   - completion: A closure called when the operation completes. Provides the event id of the event generated on the home server on success.
    func startVoiceBroadcast(completion: @escaping (MXResponse<String?>) -> Void) {
        sendVoiceBroadcastInfo(state: VoiceBroadcastInfoState.started) { [weak self] response in
            guard let self = self else { return }
            
            switch response {
            case .success((let eventIdResponse)):
                self.voiceBroadcastId = eventIdResponse
                completion(.success(eventIdResponse))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Pause a voice broadcast.
    /// - Parameters:
    ///   - lastChunkSequence: The last sent chunk number.
    ///   - completion: A closure called when the operation completes. Provides the event id of the event generated on the home server on success.
    func pauseVoiceBroadcast(lastChunkSequence: Int, completion: @escaping (MXResponse<String?>) -> Void) {
        sendVoiceBroadcastInfo(lastChunkSequence: lastChunkSequence, state: VoiceBroadcastInfoState.paused, completion: completion)
    }
    
    /// resume a voice broadcast.
    /// - Parameters:
    ///   - completion: A closure called when the operation completes. Provides the event id of the event generated on the home server on success.
    func resumeVoiceBroadcast(completion: @escaping (MXResponse<String?>) -> Void) {
        sendVoiceBroadcastInfo(state: VoiceBroadcastInfoState.resumed, completion: completion)
    }
    
    /// stop a voice broadcast info.
    /// - Parameters:
    ///   - lastChunkSequence: The last sent chunk number.
    ///   - voiceBroadcastId: The VoiceBroadcast identifier to stop. Use it only to force stop a specific VoiceBroadcast.
    ///   - completion: A closure called when the operation completes. Provides the event id of the event generated on the home server on success.
    func stopVoiceBroadcast(lastChunkSequence: Int,
                            voiceBroadcastId: String? = nil,
                            completion: @escaping (MXResponse<String?>) -> Void) {
        if let voiceBroadcastId = voiceBroadcastId {
            self.voiceBroadcastId = voiceBroadcastId
        }
        sendVoiceBroadcastInfo(lastChunkSequence: lastChunkSequence, state: VoiceBroadcastInfoState.stopped, completion: completion)
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
                                   sequence: UInt,
                                   success: @escaping ((String?) -> Void),
                                   failure: @escaping ((Error?) -> Void)) {
        guard let voiceBroadcastId = self.voiceBroadcastId else {
            return failure(VoiceBroadcastServiceError.notStarted)
        }
        
        self.room.sendChunkOfVoiceBroadcast(localURL: audioFileLocalURL,
                                            voiceBroadcastId: voiceBroadcastId,
                                            mimeType: mimeType,
                                            duration: duration,
                                            sequence: sequence,
                                            success: success,
                                            failure: failure)
    }
    
    // MARK: - Private
    
    private func allowedStates(from state: VoiceBroadcastInfoState) -> [VoiceBroadcastInfoState] {
        switch state {
        case .started:
            return [.paused, .stopped]
        case .paused:
            return [.resumed, .stopped]
        case .resumed:
            return [.paused, .stopped]
        case .stopped:
            return [.started, .stopped]
        }
    }
    
    private func sendVoiceBroadcastInfo(lastChunkSequence: Int = 0,
                                        state: VoiceBroadcastInfoState,
                                        completion: @escaping (MXResponse<String?>) -> Void) {
        guard let userId = self.room.mxSession.myUserId else {
            completion(.failure(VoiceBroadcastServiceError.missingUserId))
            return
        }
        
        asyncTaskQueue.async { (taskCompleted) in
            guard self.allowedStates(from: self.state).contains(state) else {
                MXLog.warning("[VoiceBroadcastService] sendVoiceBroadcastInfo: unexpected state change \(self.state) -> \(state)")
                completion(.failure(VoiceBroadcastServiceError.unexpectedState))
                taskCompleted()
                return
            }
            
            let stateKey = userId
            
            let voiceBroadcastInfo = VoiceBroadcastInfo()
            
            voiceBroadcastInfo.deviceId = self.room.mxSession.myDeviceId
            
            voiceBroadcastInfo.state = state.rawValue
            
            voiceBroadcastInfo.lastChunkSequence = lastChunkSequence
            
            if state != VoiceBroadcastInfoState.started {
                guard let voiceBroadcastId = self.voiceBroadcastId else {
                    completion(.failure(VoiceBroadcastServiceError.notStarted))
                    taskCompleted()
                    return
                }
                
                voiceBroadcastInfo.voiceBroadcastId = voiceBroadcastId
            } else {
                voiceBroadcastInfo.chunkLength = BuildSettings.voiceBroadcastChunkLength
            }
            
            guard let stateEventContent = voiceBroadcastInfo.jsonDictionary() as? [String: Any] else {
                completion(.failure(VoiceBroadcastServiceError.unknown))
                taskCompleted()
                return
            }
            
            let httpOperation = self.room.sendStateEvent(.custom(VoiceBroadcastSettings.voiceBroadcastInfoContentKeyType),
                                     content: stateEventContent, stateKey: stateKey) { [weak self] response in
                guard let self = self else { return }
                
                switch response {
                case .success(let object):
                    self.state = state
                    completion(.success(object))
                case .failure(let error):
                    completion(.failure(error))
                }
                taskCompleted()
            }
            
            // No retry to send the request
            httpOperation.maxNumberOfTries = 0
        }
    }
}

// MARK: - Objective-C interface
extension VoiceBroadcastService {
    
    /// Start a voice broadcast.
    /// - Parameters:
    ///   - success: A closure called when the operation is complete.
    ///   - failure: A closure called  when the operation fails.
    @objc public func startVoiceBroadcast(success: @escaping (String?) -> Void, failure: @escaping (Error) -> Void) {
        self.startVoiceBroadcast { response in
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
    ///   - lastChunkSequence: The last sent chunk number.
    ///   - success: A closure called when the operation is complete.
    ///   - failure: A closure called  when the operation fails.
    @objc public func pauseVoiceBroadcast(lastChunkSequence: Int,
                                          success: @escaping (String?) -> Void,
                                          failure: @escaping (Error) -> Void) {
        self.pauseVoiceBroadcast(lastChunkSequence: lastChunkSequence) { response in
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
    @objc public func resumeVoiceBroadcast(success: @escaping (String?) -> Void, failure: @escaping (Error) -> Void) {
        self.resumeVoiceBroadcast { response in
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
    ///   - lastChunkSequence: The last sent chunk number.
    ///   - success: A closure called when the operation is complete.
    ///   - failure: A closure called  when the operation fails.
    @objc public func stopVoiceBroadcast(lastChunkSequence: Int,
                                         success: @escaping (String?) -> Void,
                                         failure: @escaping (Error) -> Void) {
        self.stopVoiceBroadcast(lastChunkSequence: lastChunkSequence) { response in
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
    ///   - voiceBroadcastId: The event id of the started voice broadcast info state event
    ///   - mimeType: (optional) the mime type of the file. Defaults to `audio/ogg`.
    ///   - duration: the length of the voice message in milliseconds
    ///   - samples: an array of floating point values normalized to [0, 1]
    ///   - threadId: the id of the thread to send the message. nil by default.
    ///   - sequence: value of the chunk sequence.
    ///   - success: A closure called when the operation is complete.
    ///   - failure: A closure called  when the operation fails.
    /// - Returns: a `MXHTTPOperation` instance.
    @nonobjc @discardableResult func sendChunkOfVoiceBroadcast(localURL: URL,
                                                               voiceBroadcastId: String,
                                                               mimeType: String?,
                                                               duration: UInt,
                                                               threadId: String? = nil,
                                                               sequence: UInt,
                                                               success: @escaping ((String?) -> Void),
                                                               failure: @escaping ((Swift.Error?) -> Void)) -> MXHTTPOperation? {
        guard let relatesTo = MXEventContentRelatesTo(relationType: MXEventRelationTypeReference,
                                                      eventId: voiceBroadcastId).jsonDictionary() as? [String: Any] else {
            failure(VoiceBroadcastServiceError.unknown)
            return nil
        }
        
        let sequenceValue = [VoiceBroadcastSettings.voiceBroadcastContentKeyChunkSequence: sequence]

        return __sendVoiceMessage(localURL,
                                  additionalContentParams: [kMXEventRelationRelatesToKey: relatesTo,
                                                            VoiceBroadcastSettings.voiceBroadcastContentKeyChunkType: sequenceValue],
                                  mimeType: mimeType,
                                  duration: duration,
                                  samples: nil,
                                  threadId: threadId,
                                  localEcho: nil,
                                  success: success,
                                  failure: failure,
                                  keepActualFilename: false)
    }
}
