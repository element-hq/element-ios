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
    
    private enum Constants {
        static let maximumAudioRecordingDuration: TimeInterval = 120.0
        static let maximumAudioRecordingLengthReachedThreshold: TimeInterval = 10.0
        static let elapsedTimeFormat = "m:ss"
        static let minimumRecordingDuration = 1.0
    }
    
    private static let timeFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = Constants.elapsedTimeFormat
        return dateFormatter
    }()
    
    private let themeService: ThemeService
    private let mediaServiceProvider: VoiceMessageMediaServiceProvider
    
    private let _voiceMessageToolbarView: VoiceMessageToolbarView
    private var displayLink: CADisplayLink!
    
    private var waveformAnalyser: WaveformAnalyzer?
    
    private var audioSamples: [Float] = []
    private var isInLockedMode: Bool = false
    private var notifiedRemainingTime = false
    
    @objc public weak var delegate: VoiceMessageControllerDelegate?
    
    @objc public var voiceMessageToolbarView: UIView {
        return _voiceMessageToolbarView
    }
    
    @objc public init(themeService: ThemeService, mediaServiceProvider: VoiceMessageMediaServiceProvider) {
        self.themeService = themeService
        self.mediaServiceProvider = mediaServiceProvider
        
        _voiceMessageToolbarView = VoiceMessageToolbarView.loadFromNib()
        
        super.init()
        
        _voiceMessageToolbarView.delegate = self
        
        displayLink = CADisplayLink(target: WeakTarget(self, selector: #selector(handleDisplayLinkTick)), selector: WeakTarget.triggerSelector)
        displayLink.isPaused = true
        displayLink.add(to: .current, forMode: .common)
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateTheme), name: .themeServiceDidChangeTheme, object: nil)
        updateTheme()
        
        updateUI()
    }
    
    // MARK: - VoiceMessageToolbarViewDelegate
    
    func voiceMessageToolbarViewDidRequestRecordingStart(_ toolbarView: VoiceMessageToolbarView) {
        guard AVAudioSession.sharedInstance().recordPermission == .granted else {
            delegate?.voiceMessageControllerDidRequestMicrophonePermission(self)
            return
        }
        
        // Haptic are not played during record on iOS by default. This fix works
        // only since iOS 13. A workaround for iOS 12 and earlier would be to
        // dispatch after at least 100ms recordWithOuputURL call
        if #available(iOS 13.0, *) {
            try? AVAudioSession.sharedInstance().setCategory(.playAndRecord)
            try? AVAudioSession.sharedInstance().setAllowHapticsAndSystemSoundsDuringRecording(true)
        }
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(ProcessInfo().globallyUniqueString).appendingPathExtension("m4a")
        
        mediaServiceProvider.audioRecorder.registerDelegate(self)
        mediaServiceProvider.audioRecorder.recordWithOuputURL(temporaryFileURL)
    }
    
    func voiceMessageToolbarViewDidRequestRecordingFinish(_ toolbarView: VoiceMessageToolbarView) {
        finishRecording()
    }
    
    func voiceMessageToolbarViewDidRequestRecordingCancel(_ toolbarView: VoiceMessageToolbarView) {
        isInLockedMode = false
        mediaServiceProvider.audioRecorder.stopRecording()
        deleteRecordingAtURL(mediaServiceProvider.audioRecorder.url)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        updateUI()
    }
    
    func voiceMessageToolbarViewDidRequestLockedModeRecording(_ toolbarView: VoiceMessageToolbarView) {
        isInLockedMode = true
        updateUI()
    }
    
    func voiceMessageToolbarViewDidRequestPlaybackToggle(_ toolbarView: VoiceMessageToolbarView) {
        if mediaServiceProvider.audioPlayer.isPlaying {
            mediaServiceProvider.audioPlayer.pause()
        } else {
            mediaServiceProvider.audioPlayer.play()
        }
    }
    
    func voiceMessageToolbarViewDidRequestSend(_ toolbarView: VoiceMessageToolbarView) {
        guard let url = mediaServiceProvider.audioRecorder.url else {
            MXLog.error("Invalid audio recording URL")
            return
        }
        
        mediaServiceProvider.audioPlayer.stop()
        mediaServiceProvider.audioRecorder.stopRecording()
        
        sendRecordingAtURL(url)
        
        isInLockedMode = false
        updateUI()
    }
    
    // MARK: - AudioRecorderDelegate
    
    func audioRecorderDidStartRecording(_ audioRecorder: VoiceMessageAudioRecorder) {
        notifiedRemainingTime = false
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
    
    func audioPlayerDidPausePlaying(_ audioPlayer: VoiceMessageAudioPlayer) {
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
    
    private func finishRecording() {
        let recordDuration = mediaServiceProvider.audioRecorder.currentTime
        mediaServiceProvider.audioRecorder.stopRecording()

        guard let url = mediaServiceProvider.audioRecorder.url else {
            MXLog.error("Invalid audio recording URL")
            return
        }
        
        guard isInLockedMode else {
            if recordDuration >= Constants.minimumRecordingDuration {
                sendRecordingAtURL(url)
            }
            return
        }
        
        mediaServiceProvider.audioPlayer.registerDelegate(self)
        mediaServiceProvider.audioPlayer.loadContentFromURL(url)
        audioSamples = []
        
        updateUI()
    }
    
    private func sendRecordingAtURL(_ sourceURL: URL) {
        
        let destinationURL = sourceURL.deletingPathExtension().appendingPathExtension("opus")
        
        VoiceMessageAudioConverter.convertToOpusOgg(sourceURL: sourceURL, destinationURL: destinationURL) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                self.delegate?.voiceMessageController(self, didRequestSendForFileAtURL: destinationURL) { [weak self] success in
                    UINotificationFeedbackGenerator().notificationOccurred((success ? .success : .error))
                    self?.deleteRecordingAtURL(sourceURL)
                    self?.deleteRecordingAtURL(destinationURL)
                }
            case .failure(let error):
                MXLog.error("Failed failed encoding audio message with: \(error)")
            }
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
    
    @objc private func updateTheme() {
        _voiceMessageToolbarView.update(theme: themeService.theme)
    }
    
    @objc private func handleDisplayLinkTick() {
        updateUI()
    }
    
    private func updateUI() {
        
        let shouldUpdateFromAudioPlayer = isInLockedMode && !mediaServiceProvider.audioRecorder.isRecording

        if shouldUpdateFromAudioPlayer {
            updateUIFromAudioPlayer()
        } else {
            updateUIFromAudioRecorder()
        }
    }
    
    private func updateUIFromAudioRecorder() {
        let isRecording = mediaServiceProvider.audioRecorder.isRecording
        
        displayLink.isPaused = !isRecording
        
        let requiredNumberOfSamples = _voiceMessageToolbarView.getRequiredNumberOfSamples()
        
        if audioSamples.count != requiredNumberOfSamples {
            padSamplesArrayToSize(requiredNumberOfSamples)
        }
        
        let sample = mediaServiceProvider.audioRecorder.averagePowerForChannelNumber(0)
        audioSamples.insert(sample, at: 0)
        audioSamples.removeLast()
        
        let currentTime = mediaServiceProvider.audioRecorder.currentTime
        
        if currentTime >= Constants.maximumAudioRecordingDuration {
            finishRecording()
            return
        }
        
        var details = VoiceMessageToolbarViewDetails()
        details.state = (isRecording ? (isInLockedMode ? .lockedModeRecord : .record) : (isInLockedMode ? .lockedModePlayback : .idle))
        details.elapsedTime = VoiceMessageController.timeFormatter.string(from: Date(timeIntervalSinceReferenceDate: currentTime))
        details.audioSamples = audioSamples
        
        if isRecording {
            if currentTime >= Constants.maximumAudioRecordingDuration - Constants.maximumAudioRecordingLengthReachedThreshold {
                
                if !self.notifiedRemainingTime {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
                
                notifiedRemainingTime = true

                let remainingTime = ceil(Constants.maximumAudioRecordingDuration - currentTime)
                details.toastMessage = VectorL10n.voiceMessageRemainingRecordingTime(String(remainingTime))
            } else {
                details.toastMessage = (isInLockedMode ? VectorL10n.voiceMessageStopLockedModeRecording : VectorL10n.voiceMessageReleaseToSend)
            }
        }
        
        _voiceMessageToolbarView.configureWithDetails(details)
    }
    
    private func updateUIFromAudioPlayer() {
        guard let url = mediaServiceProvider.audioPlayer.url else {
            MXLog.error("Invalid audio player url.")
            return
        }
        
        displayLink.isPaused = !mediaServiceProvider.audioPlayer.isPlaying
        
        let requiredNumberOfSamples = _voiceMessageToolbarView.getRequiredNumberOfSamples()
        if audioSamples.count != requiredNumberOfSamples  && requiredNumberOfSamples > 0 {
            padSamplesArrayToSize(requiredNumberOfSamples)
            
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
        details.state = (mediaServiceProvider.audioRecorder.isRecording ? (isInLockedMode ? .lockedModeRecord : .record) : (isInLockedMode ? .lockedModePlayback : .idle))
        details.elapsedTime = VoiceMessageController.timeFormatter.string(from: Date(timeIntervalSinceReferenceDate: (mediaServiceProvider.audioPlayer.isPlaying ? mediaServiceProvider.audioPlayer.currentTime : mediaServiceProvider.audioPlayer.duration)))
        details.audioSamples = audioSamples
        details.isPlaying = mediaServiceProvider.audioPlayer.isPlaying
        details.progress = (mediaServiceProvider.audioPlayer.duration > 0.0 ? mediaServiceProvider.audioPlayer.currentTime / mediaServiceProvider.audioPlayer.duration : 0.0)
        _voiceMessageToolbarView.configureWithDetails(details)
    }
    
    private func padSamplesArrayToSize(_ size: Int) {
        let delta = size - audioSamples.count
        guard delta > 0 else {
            return
        }
        
        audioSamples = audioSamples + [Float](repeating: 0.0, count: delta)
    }
}
