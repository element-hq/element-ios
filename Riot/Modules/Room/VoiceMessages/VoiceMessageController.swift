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

@objc public protocol VoiceMessageControllerDelegate: AnyObject {
    func voiceMessageControllerDidRequestMicrophonePermission(_ voiceMessageController: VoiceMessageController)
    func voiceMessageController(_ voiceMessageController: VoiceMessageController, didRequestSendForFileAtURL url: URL, completion: @escaping (Bool) -> Void)
}

public class VoiceMessageController: NSObject, VoiceMessageToolbarViewDelegate, VoiceMessageAudioRecorderDelegate {
    
    private let themeService: ThemeService
    private let _voiceMessageToolbarView: VoiceMessageToolbarView
    private let timeFormatter: DateFormatter
    private var displayLink: CADisplayLink!
    
    private var audioRecorder: VoiceMessageAudioRecorder?
    
    private var audioSamples: [Float] = []
    private var isInLockedMode: Bool = false
    
    @objc public weak var delegate: VoiceMessageControllerDelegate?
    
    @objc public var voiceMessageToolbarView: UIView {
        return _voiceMessageToolbarView
    }
    
    @objc public init(themeService: ThemeService) {
        _voiceMessageToolbarView = VoiceMessageToolbarView.instanceFromNib()
        self.themeService = themeService
        self.timeFormatter = DateFormatter()
        
        super.init()
        
        _voiceMessageToolbarView.delegate = self
        
        timeFormatter.dateFormat = "m:ss"
        
        displayLink = CADisplayLink(target: WeakObjectWrapper(self), selector: #selector(handleDisplayLinkTick))
        displayLink.isPaused = true
        displayLink.add(to: .current, forMode: .common)
        
        self._voiceMessageToolbarView.update(theme: self.themeService.theme)
        NotificationCenter.default.addObserver(self, selector: #selector(handleThemeDidChange), name: .themeServiceDidChangeTheme, object: nil)
        
        updateUI()
    }
    
    // MARK: - VoiceMessageToolbarViewDelegate
    
    func voiceMessageToolbarViewDidRequestRecordingStart(_ toolbarView: VoiceMessageToolbarView) {
        guard AVAudioSession.sharedInstance().recordPermission == .granted else {
            delegate?.voiceMessageControllerDidRequestMicrophonePermission(self)
            return
        }
                
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(ProcessInfo().globallyUniqueString).appendingPathExtension("m4a")
        
        self.audioRecorder = VoiceMessageAudioRecorder()
        self.audioRecorder?.delegate = self
        self.audioRecorder?.recordWithOuputURL(temporaryFileURL)
    }
    
    func voiceMessageToolbarViewDidRequestRecordingFinish(_ toolbarView: VoiceMessageToolbarView) {
        audioRecorder?.stopRecording()
        
        guard let url = audioRecorder?.url else {
            MXLog.error("Invalid audio recording URL")
            return
        }
        
        delegate?.voiceMessageController(self, didRequestSendForFileAtURL: url) { [weak self] success in
            UINotificationFeedbackGenerator().notificationOccurred( (success ? .success : .error))
            self?.deleteRecordingAtURL(url)
        }
    }
    
    func voiceMessageToolbarViewDidRequestRecordingCancel(_ toolbarView: VoiceMessageToolbarView) {
        isInLockedMode = false
        audioRecorder?.stopRecording()
        deleteRecordingAtURL(audioRecorder?.url)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
    
    func voiceMessageToolbarViewDidRequestLockedModeRecording(_ toolbarView: VoiceMessageToolbarView) {
        isInLockedMode = true
        updateUI()
    }
    
    // MARK: - AudioRecorderDelegate
    
    func audioRecorderDidStartRecording(_ audioRecorder: VoiceMessageAudioRecorder) {
        updateUI()
    }
    
    func audioRecorderDidFinishRecording(_ audioRecorder: VoiceMessageAudioRecorder) {
        updateUI()
    }
    
    func audioRecorder(_ audioRecorder: VoiceMessageAudioRecorder, didFailWithError: Error) {
        isInLockedMode = false
        updateUI()
        
        MXLog.error("Failed recording voice message.")
    }
    
    // MARK: - Private
    
    private func deleteRecordingAtURL(_ url: URL?) {
        guard let url = url else {
            return
        }
        
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            MXLog.error(error)
        }
    }
    
    @objc private func handleThemeDidChange() {
        self._voiceMessageToolbarView.update(theme: self.themeService.theme)
    }
    
    @objc private func handleDisplayLinkTick() {
        updateUI()
    }
    
    private func updateUI() {
        displayLink.isPaused = !(audioRecorder?.isRecording ?? false)
        
        let requiredNumberOfSamples = _voiceMessageToolbarView.getRequiredNumberOfSamples()
        
        if audioSamples.count != requiredNumberOfSamples {
            audioSamples = [Float](repeating: 0.0, count: requiredNumberOfSamples)
        }
        
        if let sample = audioRecorder?.averagePowerForChannelNumber(0) {
            audioSamples.append(sample)
            audioSamples.remove(at: 0)
        }
        
        var details = VoiceMessageToolbarViewDetails()
        details.state = (audioRecorder?.isRecording ?? false ? (isInLockedMode ? .lockedModeRecord : .record) : (isInLockedMode ? .lockedModePlayback : .idle))
        details.elapsedTime = timeFormatter.string(from: Date(timeIntervalSinceReferenceDate: audioRecorder?.currentTime ?? 0.0))
        details.audioSamples = audioSamples
        _voiceMessageToolbarView.configureWithDetails(details)
    }
}
