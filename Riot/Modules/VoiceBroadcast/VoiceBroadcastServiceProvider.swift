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
    
    // VoiceBroadcastService in the current session
    public var voiceBroadcastService: VoiceBroadcastService? = nil
    
    // MARK: - Setup
    
    private init() {}
    
    // MARK: - Public
    
    public func getOrCreateVoiceBroadcastService(for room: MXRoom, completion: @escaping (VoiceBroadcastService?) -> Void) {
        guard let voiceBroadcastService = self.voiceBroadcastService else {
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
                
        self.voiceBroadcastService = nil

        MXLog.debug("Stop monitoring voice broadcast recording")
    }
    
    // MARK: - Private
    
    // MARK: VoiceBroadcastService setup
    
    private func createVoiceBroadcastService(for room: MXRoom, state: VoiceBroadcastService.State) {
                
        let voiceBroadcastService = VoiceBroadcastService(room: room, state: VoiceBroadcastService.State.stopped)
        
        self.voiceBroadcastService = voiceBroadcastService
        
        MXLog.debug("Start monitoring voice broadcast recording")
    }
    
    private func setupVoiceBroadcastService(for room: MXRoom, completion: @escaping (VoiceBroadcastService?) -> Void) {
        self.getLastVoiceBroadcastInfo(for: room) { event in
            guard let voiceBroadcastInfoEvent = event else {
                self.createVoiceBroadcastService(for: room, state: VoiceBroadcastService.State.stopped)
                completion(self.voiceBroadcastService)
                return
            }
            
            guard let voiceBroadcastInfoEventContent = VoiceBroadcastEventContent(fromJSON: voiceBroadcastInfoEvent.content) else {
                self.createVoiceBroadcastService(for: room, state: VoiceBroadcastService.State.stopped)
                completion(self.voiceBroadcastService)
                return
            }
            
            if voiceBroadcastInfoEventContent.state == VoiceBroadcastService.State.stopped.rawValue {
                self.createVoiceBroadcastService(for: room, state: VoiceBroadcastService.State.stopped)
                completion(self.voiceBroadcastService)
            } else if voiceBroadcastInfoEvent.stateKey == room.mxSession.myUserId {
                self.createVoiceBroadcastService(for: room, state: VoiceBroadcastService.State(rawValue: voiceBroadcastInfoEventContent.state) ?? VoiceBroadcastService.State.stopped)
                completion(self.voiceBroadcastService)
            } else {
                completion(nil)
            }
        }
    }
    
    /// Get latest voice broadcast info in a room
    /// - Parameters:
    ///   - roomId: The room id of the room
    ///   - completion: Give the lastest voice broadcast info of the room.
    private func getLastVoiceBroadcastInfo(for room: MXRoom, completion: @escaping (MXEvent?) -> Void) {
        room.state { roomState in
            completion(roomState?.stateEvents(with: .custom(VoiceBroadcastSettings.eventType))?.last ?? nil)
        }
    }
}
