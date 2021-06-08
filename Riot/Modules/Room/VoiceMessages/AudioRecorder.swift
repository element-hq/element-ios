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
import AVFoundation

protocol AudioRecorderDelegate: AnyObject {
    func audioRecorderDidStartRecording(_ audioRecorder: AudioRecorder)
    func audioRecorderDidFinishRecording(_ audioRecorder: AudioRecorder)
    func audioRecorder(_ audioRecorder: AudioRecorder, didFailWithError: Error)
}

enum AudioRecorderError: Error {
    case genericError
}

class AudioRecorder: NSObject, AVAudioRecorderDelegate {
    
    private var audioRecorder: AVAudioRecorder?
    
    var url: URL? {
        return audioRecorder?.url
    }
    
    var currentTime: TimeInterval {
        return audioRecorder?.currentTime ?? 0
    }
    
    weak var delegate: AudioRecorderDelegate?
    
    func recordWithOuputURL(_ url: URL) {
        
        let settings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                        AVSampleRateKey: 12000,
                        AVNumberOfChannelsKey: 1,
                        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default)
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            delegate?.audioRecorderDidStartRecording(self)
        } catch {
            delegate?.audioRecorder(self, didFailWithError: AudioRecorderError.genericError)
        }
        
    }
    
    func stopRecording() {
        audioRecorder?.stop()
    }
    
    // MARK: - AVAudioRecorderDelegate
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully success: Bool) {
        if success {
            delegate?.audioRecorderDidFinishRecording(self)
        } else {
            delegate?.audioRecorder(self, didFailWithError: AudioRecorderError.genericError)
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        delegate?.audioRecorder(self, didFailWithError: AudioRecorderError.genericError)
    }
}

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}
