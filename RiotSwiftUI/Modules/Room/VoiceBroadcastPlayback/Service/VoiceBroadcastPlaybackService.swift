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

class VoiceBroadcastPlaybackService: VoiceBroadcastPlaybackServiceProtocol {
    
    // MARK: - Properties
    
    private(set) var voiceBroadcastChunks: [VoiceBroadcastChunk] = []
    private let roomId: String
    
    // MARK: Private
    
    
    // MARK: Public
    
    var didUpdateVoiceBroadcastChunks: (([VoiceBroadcastChunk]) -> Void)?
    
    // MARK: - Setup
    
    init(roomId: String) {
        self.roomId = roomId
        
        updateVoiceBroadcastChunks(notifyUpdate: false)
    }
    
    // MARK: - Public
    
    func startPlayingVoiceBroadcast() {
        
    }
    
    func pausePlayingVoiceBroadcast() {

    }
    
    // MARK: - Private
    
    private func updateVoiceBroadcastChunks(notifyUpdate: Bool) {
        // TODO: VB udpate voicebroadcast chunks. We already have a listener on voicebroadcast events in VoiceBroadcastAggregator
        
        if notifyUpdate {
            didUpdateVoiceBroadcastChunks?(voiceBroadcastChunks)
        }
    }
}

