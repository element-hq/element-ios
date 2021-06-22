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
import DSWaveformImage

@objc public protocol VoiceMessageControllerDelegate: AnyObject {
    func voiceMessageControllerDidRequestMicrophonePermission(_ voiceMessageController: VoiceMessageController)
    func voiceMessageController(_ voiceMessageController: VoiceMessageController, didRequestSendForFileAtURL url: URL, completion: @escaping (Bool) -> Void)
}

public class VoiceMessageController: NSObject, VoiceMessageToolbarViewDelegate, VoiceMessageAudioRecorderDelegate, VoiceMessageAudioPlayerDelegate {
    
    private let themeService: ThemeService
    private let _voiceMessageToolbarView: VoiceMessageToolbarView
    private let timeFormatter: DateFormatter
    private var displayLink: CADisplayLink!
    
    private var audioRecorder: VoiceMessageAudioRecorder?
    
    private var audioPlayer: VoiceMessageAudioPlayer?
    private var waveformAnalyser: WaveformAnalyzer?
    
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
        
        _voiceMessageToolbarView.update(theme: themeService.theme)
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
        
        audioRecorder = VoiceMessageAudioRecorder()
        audioRecorder?.delegate = self
        audioRecorder?.recordWithOuputURL(temporaryFileURL)
    }
    
    func voiceMessageToolbarViewDidRequestRecordingFinish(_ toolbarView: VoiceMessageToolbarView) {
        audioRecorder?.stopRecording()
        
        guard let url = audioRecorder?.url else {
            MXLog.error("Invalid audio recording URL")
            return
        }
        
        guard isInLockedMode else {
            sendRecordingAtURL(url)
            return
        }
        
        audioPlayer = VoiceMessageAudioPlayer()
        audioPlayer?.delegate = self
        audioPlayer?.loadContentFromURL(url)
        audioSamples = []
        
        updateUI()
    }
    
    func voiceMessageToolbarViewDidRequestRecordingCancel(_ toolbarView: VoiceMessageToolbarView) {
        isInLockedMode = false
        audioRecorder?.stopRecording()
        deleteRecordingAtURL(audioRecorder?.url)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        updateUI()
    }
    
    func voiceMessageToolbarViewDidRequestLockedModeRecording(_ toolbarView: VoiceMessageToolbarView) {
        isInLockedMode = true
        updateUI()
    }
    
    func voiceMessageToolbarViewDidRequestPlaybackToggle(_ toolbarView: VoiceMessageToolbarView) {
        if audioPlayer?.isPlaying ?? false {
            audioPlayer?.pause()
        } else {
            audioPlayer?.play()
        }
    }
    
    func voiceMessageToolbarViewDidRequestSend(_ toolbarView: VoiceMessageToolbarView) {
        guard let url = audioRecorder?.url else {
            MXLog.error("Invalid audio recording URL")
            return
        }
        
        audioPlayer?.stop()
        audioRecorder?.stopRecording()
        
        sendRecordingAtURL(url)
        
        isInLockedMode = false
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
    
    // MARK: - VoiceMessageAudioPlayerDelegate
    
    func audioPlayerDidStartPlaying(_ audioPlayer: VoiceMessageAudioPlayer) {
        updateUI()
    }
    
    func audioPlayerDidStopPlaying(_ audioPlayer: VoiceMessageAudioPlayer) {
        updateUI()
    }
    
    func audioPlayerDidFinishPlaying(_ audioPlayer: VoiceMessageAudioPlayer) {
        audioPlayer.seekToTime(0.0)
        updateUI()
    }
    
    func audioPlayer(_ audioPlayer: VoiceMessageAudioPlayer, didFailWithError: Error) {
        updateUI()
        
        MXLog.error("Failed playing voice message.")
    }
    
    // MARK: - Private
    
    private func sendRecordingAtURL(_ url: URL) {
        delegate?.voiceMessageController(self, didRequestSendForFileAtURL: url) { [weak self] success in
            UINotificationFeedbackGenerator().notificationOccurred( (success ? .success : .error))
            self?.deleteRecordingAtURL(url)
        }
    }
    
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
        _voiceMessageToolbarView.update(theme: themeService.theme)
    }
    
    @objc private func handleDisplayLinkTick() {
        updateUI()
    }
    
    private func updateUI() {
        
        let shouldUpdateFromAudioPlayer = isInLockedMode && !(audioRecorder?.isRecording ?? false)

        if shouldUpdateFromAudioPlayer {
            updateUIFromAudioPlayer()
        } else {
            updateUIFromAudioRecorder()
        }
    }
    
    private func updateUIFromAudioRecorder() {
        displayLink.isPaused = !(self.audioRecorder?.isRecording ?? false)
        
        let requiredNumberOfSamples = _voiceMessageToolbarView.getRequiredNumberOfSamples()
        
        if audioSamples.count != requiredNumberOfSamples {
            audioSamples = [Float](repeating: 0.0, count: requiredNumberOfSamples)
        }
        
        let sample = audioRecorder?.averagePowerForChannelNumber(0) ?? 0.0
        audioSamples.append(sample)
        audioSamples.remove(at: 0)
        
        var details = VoiceMessageToolbarViewDetails()
        details.state = (self.audioRecorder?.isRecording ?? false ? (isInLockedMode ? .lockedModeRecord : .record) : (isInLockedMode ? .lockedModePlayback : .idle))
        details.elapsedTime = timeFormatter.string(from: Date(timeIntervalSinceReferenceDate: self.audioRecorder?.currentTime ?? 0.0))
        details.audioSamples = audioSamples
        _voiceMessageToolbarView.configureWithDetails(details)
    }
    
    private func updateUIFromAudioPlayer() {
        guard let audioPlayer = audioPlayer else {
            return
        }
        
        guard let url = audioPlayer.url else {
            MXLog.error("Invalid audio player url.")
            return
        }
        
        displayLink.isPaused = !audioPlayer.isPlaying
        
        let requiredNumberOfSamples = _voiceMessageToolbarView.getRequiredNumberOfSamples()
        if audioSamples.count != requiredNumberOfSamples {
            audioSamples = [Float](repeating: 0.0, count: requiredNumberOfSamples)
            
            waveformAnalyser = WaveformAnalyzer(audioAssetURL: url)
            waveformAnalyser?.samples(count: requiredNumberOfSamples, completionHandler: { [weak self] samples in
                guard let samples =  samples else {
                    MXLog.error("Could not sample audio recording.")
                    return
                }
                
                DispatchQueue.main.async {
                    self?.audioSamples = samples
                    self?.updateUIFromAudioPlayer()
                }
            })
        }
        
        var details = VoiceMessageToolbarViewDetails()
        details.state = (audioRecorder?.isRecording ?? false ? (isInLockedMode ? .lockedModeRecord : .record) : (isInLockedMode ? .lockedModePlayback : .idle))
        details.elapsedTime = timeFormatter.string(from: Date(timeIntervalSinceReferenceDate: (audioPlayer.isPlaying ? audioPlayer.currentTime : audioPlayer.duration)))
        details.audioSamples = audioSamples
        details.isPlaying = audioPlayer.isPlaying
        details.progress = (audioPlayer.duration > 0.0 ? audioPlayer.currentTime / audioPlayer.duration : 0.0)
        _voiceMessageToolbarView.configureWithDetails(details)
    }
}
