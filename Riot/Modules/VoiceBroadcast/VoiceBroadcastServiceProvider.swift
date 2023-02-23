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

/// VoiceBroadcastServiceProvider to setup VoiceBroadcastService or retrieve the existing VoiceBroadcastService.
class VoiceBroadcastServiceProvider {
    
    // MARK: - Constants
    
    static let shared = VoiceBroadcastServiceProvider()
    
    // MARK: - Properties
    
    /// VoiceBroadcastService in the current session
    public var currentVoiceBroadcastService: VoiceBroadcastService?
    
    // MARK: - Setup
    
    private init() {}
    
    // MARK: - Public
    
    public func getOrCreateVoiceBroadcastService(for room: MXRoom, completion: @escaping (VoiceBroadcastService?) -> Void) {
        guard let voiceBroadcastService = self.currentVoiceBroadcastService else {
            self.setupVoiceBroadcastService(for: room) { voiceBroadcastService in
                completion(voiceBroadcastService)
            }
            return
        }
        
        if voiceBroadcastService.room.roomId == room.roomId {
            completion(voiceBroadcastService)
        }
        
        completion(nil)
    }
    
    public func tearDownVoiceBroadcastService() {
                
        self.currentVoiceBroadcastService = nil

        MXLog.debug("Stop monitoring voice broadcast recording")
    }
    
    // MARK: - Private
    
    // MARK: VoiceBroadcastService setup
    
    /// Get latest voice broadcast info in a room
    /// - Parameters:
    ///   - room: The room.
    ///   - completion: Completion block that will return the lastest voice broadcast info state event of the room.
    private func getLastVoiceBroadcastInfo(for room: MXRoom, completion: @escaping (MXEvent?) -> Void) {
        room.state { roomState in
            completion(roomState?.stateEvents(with: .custom(VoiceBroadcastSettings.voiceBroadcastInfoContentKeyType))?.last ?? nil)
        }
    }
    
    private func createVoiceBroadcastService(for room: MXRoom, state: VoiceBroadcastInfoState) {
                
        let voiceBroadcastService = VoiceBroadcastService(room: room, state: VoiceBroadcastInfoState.stopped)
        
        self.currentVoiceBroadcastService = voiceBroadcastService
        
        MXLog.debug("Start monitoring voice broadcast recording")
    }
    
    
    /// Setup the voice broadcast service if no service is running locally.
    ///
    /// A voice broadcast service is created in the following cases :
    /// - A voice broadcast info state event doesn't exist in the room.
    /// - The last voice broadcast info state event doesn't contain a valid content.
    /// - The state of the last voice broadcast info state event is stopped.
    /// - The state of the last voice broadcast info state event started by the end user is not stopped.
    ///   This may be due the following situations the application crashed or the voice broadcast has been started from another session.
    ///     
    /// - Parameters:
    ///   - room: The room.
    ///   - completion: Completion block that will return the voice broadcast service.
    private func setupVoiceBroadcastService(for room: MXRoom, completion: @escaping (VoiceBroadcastService?) -> Void) {
        self.getLastVoiceBroadcastInfo(for: room) { event in
            guard let voiceBroadcastInfoEvent = event else {
                self.createVoiceBroadcastService(for: room, state: VoiceBroadcastInfoState.stopped)
                completion(self.currentVoiceBroadcastService)
                return
            }
            
            guard let voiceBroadcastInfo = VoiceBroadcastInfo(fromJSON: voiceBroadcastInfoEvent.content) else {
                self.createVoiceBroadcastService(for: room, state: VoiceBroadcastInfoState.stopped)
                completion(self.currentVoiceBroadcastService)
                return
            }
            
            if voiceBroadcastInfo.state == VoiceBroadcastInfoState.stopped.rawValue {
                self.createVoiceBroadcastService(for: room, state: VoiceBroadcastInfoState.stopped)
                completion(self.currentVoiceBroadcastService)
            } else if voiceBroadcastInfoEvent.stateKey == room.mxSession.myUserId {
                self.createVoiceBroadcastService(for: room, state: VoiceBroadcastInfoState(rawValue: voiceBroadcastInfo.state) ?? VoiceBroadcastInfoState.stopped)
                completion(self.currentVoiceBroadcastService)
            } else {
                completion(nil)
            }
        }
    }
}
