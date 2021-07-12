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
    
    private let audioPlayers: NSHashTable<VoiceMessageAudioPlayer>
    private let audioRecorders: NSHashTable<VoiceMessageAudioRecorder>
    
    @objc public static let sharedProvider = VoiceMessageMediaServiceProvider()
    
    private override init() {
        audioPlayers = NSHashTable<VoiceMessageAudioPlayer>(options: .weakMemory)
        audioRecorders = NSHashTable<VoiceMessageAudioRecorder>(options: .weakMemory)
    }
    
    @objc func audioPlayer() -> VoiceMessageAudioPlayer {
        let audioPlayer = VoiceMessageAudioPlayer()
        audioPlayer.registerDelegate(self)
        audioPlayers.add(audioPlayer)
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
        stopAllServicesExcept(audioPlayer)
    }
    
    // MARK: - VoiceMessageAudioRecorderDelegate
    
    func audioRecorderDidStartRecording(_ audioRecorder: VoiceMessageAudioRecorder) {
        stopAllServicesExcept(audioRecorder)
    }
    
    // MARK: - Private
    
    private func stopAllServicesExcept(_ service: AnyObject?) {
        for audioPlayer in audioPlayers.allObjects {
            if audioPlayer === service {
                continue
            }
            
            audioPlayer.pause()
        }
        
        for audioRecoder in audioRecorders.allObjects {
            if audioRecoder === service {
                continue
            }
            
            audioRecoder.stopRecording()
        }
    }
}
