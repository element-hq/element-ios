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
    
    let audioPlayer = VoiceMessageAudioPlayer()
    var mediaIdentifier: String?
    let audioRecorder = VoiceMessageAudioRecorder()

    @objc public static let sharedProvider = VoiceMessageMediaServiceProvider()
    
    private override init() {
        super.init()
        audioPlayer.registerDelegate(self)
        audioRecorder.registerDelegate(self)
    }
    
    @objc func stopAllServices() {
        audioPlayer.stop()
        audioRecorder.stopRecording()
    }
    
    // MARK: - VoiceMessageAudioPlayerDelegate
    
    func audioPlayerDidStartPlaying(_ audioPlayer: VoiceMessageAudioPlayer) {
        audioRecorder.stopRecording()
    }
    
    // MARK: - VoiceMessageAudioRecorderDelegate
    
    func audioRecorderDidStartRecording(_ audioRecorder: VoiceMessageAudioRecorder) {
        audioPlayer.stop()
    }
}
