// 
// Copyright 2021 New Vector Ltd
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

@objc public class VoiceMessageMediaServiceProvider: NSObject, VoiceMessageAudioPlayerDelegate, VoiceMessageAudioRecorderDelegate {
    
    private let audioPlayers: NSMapTable<NSString, VoiceMessageAudioPlayer>
    private let audioRecorders: NSHashTable<VoiceMessageAudioRecorder>
    
    // Retain currently playing audio player so it doesn't stop playing on timeline cell reusage
    private var currentlyPlayingAudioPlayer: VoiceMessageAudioPlayer?
    
    @objc public static let sharedProvider = VoiceMessageMediaServiceProvider()
    
    private override init() {
        audioPlayers = NSMapTable<NSString, VoiceMessageAudioPlayer>(valueOptions: .weakMemory)
        audioRecorders = NSHashTable<VoiceMessageAudioRecorder>(options: .weakMemory)
    }
    
    @objc func audioPlayerForIdentifier(_ identifier: String) -> VoiceMessageAudioPlayer {
        if let audioPlayer = audioPlayers.object(forKey: identifier as NSString) {
            return audioPlayer
        }
        
        let audioPlayer = VoiceMessageAudioPlayer()
        audioPlayer.registerDelegate(self)
        audioPlayers.setObject(audioPlayer, forKey: identifier as NSString)
        return audioPlayer
    }
    
    @objc func audioRecorder() -> VoiceMessageAudioRecorder {
        let audioRecorder = VoiceMessageAudioRecorder()
        audioRecorder.registerDelegate(self)
        audioRecorders.add(audioRecorder)
        return audioRecorder
    }
    
    @objc func stopAllServices() {
        stopAllServicesExcept(nil)
    }
    
    // MARK: - VoiceMessageAudioPlayerDelegate
    
    func audioPlayerDidStartPlaying(_ audioPlayer: VoiceMessageAudioPlayer) {
        currentlyPlayingAudioPlayer = audioPlayer
        stopAllServicesExcept(audioPlayer)
    }
    
    func audioPlayerDidStopPlaying(_ audioPlayer: VoiceMessageAudioPlayer) {
        if currentlyPlayingAudioPlayer == audioPlayer {
            currentlyPlayingAudioPlayer = nil
        }
    }
    
    // MARK: - VoiceMessageAudioRecorderDelegate
    
    func audioRecorderDidStartRecording(_ audioRecorder: VoiceMessageAudioRecorder) {
        stopAllServicesExcept(audioRecorder)
    }
    
    // MARK: - Private
    
    private func stopAllServicesExcept(_ service: AnyObject?) {
        for audioRecoder in audioRecorders.allObjects {
            if audioRecoder === service {
                continue
            }
            
            audioRecoder.stopRecording()
        }
        
        guard let audioPlayersEnumerator = audioPlayers.objectEnumerator() else {
            return
        }
        
        for case let audioPlayer as VoiceMessageAudioPlayer in audioPlayersEnumerator {
            if audioPlayer === service {
                continue
            }
            
            audioPlayer.stop()
            audioPlayer.unloadContent()
        }
    }
}
