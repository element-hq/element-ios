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

enum VoiceBroadcastRecordControllerState {
    case stopped
    case recording
    case paused
    case resumed
    case error
}

class VoiceBroadcastRecordController: VoiceBroadcastAudioRecorderDelegate {
    private var state: VoiceBroadcastRecordControllerState = .stopped {
        didSet {
            updateUI()
//            displayLink.isPaused = (state != .playing)
        }
    }
    
    let recordView: VoiceBroadcastRecordView
    
    init() {
        recordView = VoiceBroadcastRecordView.loadFromNib()
//        playbackView.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateTheme), name: .themeServiceDidChangeTheme, object: nil)
        updateTheme()
        updateUI()
    }
    
    // MARK: - Private
    private func updateUI() {
    }
    
    @objc private func updateTheme() {
        recordView.update(theme: ThemeService.shared().theme)
    }
    
    // MARK: - VoiceBroadcastAudioRecorderDelegate
    
    func audioRecorderDidStartRecording(_ audioRecorder: VoiceBroadcastAudioRecorder) {
        state = .recording
    }
    func audioRecorderDidPauseRecording(_ audioRecorder: VoiceBroadcastAudioRecorder) {
        state = .paused
    }
    func audioRecorderDidResumeRecording(_ audioRecorder: VoiceBroadcastAudioRecorder) {
        state = .resumed
    }
    func audioRecorderDidFinishRecording(_ audioRecorder: VoiceBroadcastAudioRecorder) {
        state = .stopped
    }
    func audioRecorder(_ audioRecorder: VoiceBroadcastAudioRecorder, didFailWithError error: Error) {
        state = .error
        MXLog.error("Failed recording voice broadcast", context: error)
    }
}
