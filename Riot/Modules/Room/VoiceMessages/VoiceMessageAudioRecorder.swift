// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import AVFoundation

protocol VoiceMessageAudioRecorderDelegate: AnyObject {
    func audioRecorderDidStartRecording(_ audioRecorder: VoiceMessageAudioRecorder)
    func audioRecorderDidFinishRecording(_ audioRecorder: VoiceMessageAudioRecorder)
    func audioRecorder(_ audioRecorder: VoiceMessageAudioRecorder, didFailWithError: Error)
}

enum VoiceMessageAudioRecorderError: Error {
    case genericError
}

class VoiceMessageAudioRecorder: NSObject, AVAudioRecorderDelegate {
    
    private enum Constants {
        static let silenceThreshold: Float = -50.0
    }
    
    private var audioRecorder: AVAudioRecorder?
    private let delegateContainer = DelegateContainer()
    
    var url: URL? {
        return audioRecorder?.url
    }
    
    var currentTime: TimeInterval {
        return audioRecorder?.currentTime ?? 0
    }
    
    var isRecording: Bool {
        return audioRecorder?.isRecording ?? false
    }
    
    func recordWithOutputURL(_ url: URL) {
        
        let settings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                        AVSampleRateKey: 48000,
                        AVEncoderBitRateKey: 128000,
                        AVNumberOfChannelsKey: 1,
                        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            delegateContainer.notifyDelegatesWithBlock { delegate in
                (delegate as? VoiceMessageAudioRecorderDelegate)?.audioRecorderDidStartRecording(self)
            }
        } catch {
            delegateContainer.notifyDelegatesWithBlock { delegate in
                (delegate as? VoiceMessageAudioRecorderDelegate)?.audioRecorder(self, didFailWithError: VoiceMessageAudioRecorderError.genericError)
            }
        }
    }

    func stopRecording(releaseAudioSession: Bool = true) {
        audioRecorder?.stop()
        
        if releaseAudioSession {
            MXLog.debug("[VoiceMessageAudioRecorder] stopRecording() - releasing audio session")
            do {
                try AVAudioSession.sharedInstance().setActive(false)
            } catch {
                delegateContainer.notifyDelegatesWithBlock { delegate in
                    (delegate as? VoiceMessageAudioRecorderDelegate)?.audioRecorder(self, didFailWithError: VoiceMessageAudioRecorderError.genericError) }
            }
        }
    }
    
    func peakPowerForChannelNumber(_ channelNumber: Int) -> Float {
        guard self.isRecording, let audioRecorder = audioRecorder else {
            return 0.0
        }
        
        audioRecorder.updateMeters()

        return self.normalizedPowerLevelFromDecibels(audioRecorder.peakPower(forChannel: channelNumber))
    }
    
    func averagePowerForChannelNumber(_ channelNumber: Int) -> Float {
        guard self.isRecording, let audioRecorder = audioRecorder else {
            return 0.0
        }
        
        audioRecorder.updateMeters()
        
        return self.normalizedPowerLevelFromDecibels(audioRecorder.averagePower(forChannel: channelNumber))
    }
    
    func registerDelegate(_ delegate: VoiceMessageAudioPlayerDelegate) {
        delegateContainer.registerDelegate(delegate)
    }
    
    func deregisterDelegate(_ delegate: VoiceMessageAudioPlayerDelegate) {
        delegateContainer.deregisterDelegate(delegate)
    }
    
    // MARK: - AVAudioRecorderDelegate
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully success: Bool) {
        if success {
            delegateContainer.notifyDelegatesWithBlock { delegate in
                (delegate as? VoiceMessageAudioRecorderDelegate)?.audioRecorderDidFinishRecording(self)
            }
        } else {
            delegateContainer.notifyDelegatesWithBlock { delegate in
                (delegate as? VoiceMessageAudioRecorderDelegate)?.audioRecorder(self, didFailWithError: VoiceMessageAudioRecorderError.genericError)
            }
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        delegateContainer.notifyDelegatesWithBlock { delegate in
            (delegate as? VoiceMessageAudioRecorderDelegate)?.audioRecorder(self, didFailWithError: VoiceMessageAudioRecorderError.genericError)
        }
    }
    
    private func normalizedPowerLevelFromDecibels(_ decibels: Float) -> Float {
        return decibels / Constants.silenceThreshold
    }
}

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}

extension VoiceMessageAudioRecorderDelegate {
    func audioRecorderDidStartRecording(_ audioRecorder: VoiceMessageAudioRecorder) { }

    func audioRecorderDidFinishRecording(_ audioRecorder: VoiceMessageAudioRecorder) { }
    
    func audioRecorder(_ audioRecorder: VoiceMessageAudioRecorder, didFailWithError: Error) { }
}
