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
    func voiceMessageController(_ voiceMessageController: VoiceMessageController, didRequestSendForFileAtURL url: URL, duration: UInt, samples: [Float]?, completion: @escaping (Bool) -> Void)
}

public class VoiceMessageController: NSObject, VoiceMessageToolbarViewDelegate, VoiceMessageAudioRecorderDelegate, VoiceMessageAudioPlayerDelegate {
    
    private enum Constants {
        static let maximumAudioRecordingDuration: TimeInterval = 120.0
        static let maximumAudioRecordingLengthReachedThreshold: TimeInterval = 10.0
        static let elapsedTimeFormat = "m:ss"
        static let fileNameFormat = "'Voice message - 'MM.dd.yyyy HH.mm.ss"
        static let minimumRecordingDuration = 1.0
    }
    
    private let themeService: ThemeService
    private let mediaServiceProvider: VoiceMessageMediaServiceProvider
    private var temporaryFileURL: URL!
    
    private let _voiceMessageToolbarView: VoiceMessageToolbarView
    private var displayLink: CADisplayLink!
    
    private var audioRecorder: VoiceMessageAudioRecorder?
    
    private var audioPlayer: VoiceMessageAudioPlayer?
    private var waveformAnalyser: WaveformAnalyzer?
    
    private var audioSamples: [Float] = []
    private var isInLockedMode: Bool = false
    private var notifiedRemainingTime = false
    
    private static let elapsedTimeFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = Constants.elapsedTimeFormat
        return dateFormatter
    }()
    
    private static let fileNameDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = Constants.fileNameFormat
        return dateFormatter
    }()
    
    @objc public weak var delegate: VoiceMessageControllerDelegate?
    
    @objc public var isRecordingAudio: Bool {
        return audioRecorder?.isRecording ?? false || isInLockedMode
    }
    
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        
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
        // dispatch after at least 100ms recordWithOutputURL call
        if #available(iOS 13.0, *) {
            try? AVAudioSession.sharedInstance().setCategory(.playAndRecord)
            try? AVAudioSession.sharedInstance().setAllowHapticsAndSystemSoundsDuringRecording(true)
        }
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        audioRecorder = mediaServiceProvider.audioRecorder()
        audioRecorder?.registerDelegate(self)
        
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let fileName = VoiceMessageController.fileNameDateFormatter.string(from: Date())
        temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(fileName).appendingPathExtension("m4a")
        
        audioRecorder?.recordWithOutputURL(temporaryFileURL)
    }
    
    func voiceMessageToolbarViewDidRequestRecordingFinish(_ toolbarView: VoiceMessageToolbarView) {
        finishRecording()
    }
    
    func voiceMessageToolbarViewDidRequestRecordingCancel(_ toolbarView: VoiceMessageToolbarView) {
        isInLockedMode = false
        audioPlayer?.stop()
        audioRecorder?.stopRecording()
        deleteRecordingAtURL(temporaryFileURL)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        updateUI()
    }
    
    func voiceMessageToolbarViewDidRequestLockedModeRecording(_ toolbarView: VoiceMessageToolbarView) {
        isInLockedMode = true
        updateUI()
    }
    
    func voiceMessageToolbarViewDidRequestPlaybackToggle(_ toolbarView: VoiceMessageToolbarView) {
        guard let audioPlayer = audioPlayer else {
            return
        }
        
        if audioPlayer.url != nil {
            if audioPlayer.isPlaying {
                audioPlayer.pause()
            } else {
                audioPlayer.play()
            }
        } else {
            audioPlayer.loadContentFromURL(temporaryFileURL)
            audioPlayer.play()
        }
    }
    
    func voiceMessageToolbarViewDidRequestSend(_ toolbarView: VoiceMessageToolbarView) {
        audioPlayer?.stop()
        audioRecorder?.stopRecording()
        
        sendRecordingAtURL(temporaryFileURL)
        
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
        let recordDuration = audioRecorder?.currentTime
        audioRecorder?.stopRecording()

        guard isInLockedMode else {
            if recordDuration ?? 0 >= Constants.minimumRecordingDuration {
                sendRecordingAtURL(temporaryFileURL)
            }
            return
        }
        
        audioPlayer = mediaServiceProvider.audioPlayerForIdentifier(UUID().uuidString)
        audioPlayer?.registerDelegate(self)
        audioPlayer?.loadContentFromURL(temporaryFileURL)

        audioSamples = []
        
        updateUI()
    }
    
    private func sendRecordingAtURL(_ sourceURL: URL) {
        
        let dispatchGroup = DispatchGroup()
        
        var duration = 0.0
        var invertedSamples: [Float]?
        var finalURL: URL?
        
        dispatchGroup.enter()
        VoiceMessageAudioConverter.mediaDurationAt(sourceURL) { result in
            switch result {
            case .success:
                if let someDuration = try? result.get() {
                    duration = someDuration
                } else {
                    MXLog.error("[VoiceMessageController] Failed retrieving media duration")
                }
            case .failure(let error):
                MXLog.error("[VoiceMessageController] Failed getting audio duration with: \(error)")
            }
            
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        let analyser = WaveformAnalyzer(audioAssetURL: sourceURL)
        analyser?.samples(count: 100, completionHandler: { samples in
            // Dispatch back from the WaveformAnalyzer's internal queue
            DispatchQueue.main.async {
                if let samples = samples {
                    invertedSamples = samples.compactMap { return 1.0 - $0 } // linearly normalized to [0, 1] (1 -> -50 dB)
                } else {
                    MXLog.error("[VoiceMessageController] Failed sampling recorder voice message.")
                }
                
                dispatchGroup.leave()
            }
        })
        
        dispatchGroup.enter()
        let destinationURL = sourceURL.deletingPathExtension().appendingPathExtension("ogg")
        VoiceMessageAudioConverter.convertToOpusOgg(sourceURL: sourceURL, destinationURL: destinationURL) { result in
            switch result {
            case .success:
                finalURL = destinationURL
            case .failure(let error):
                MXLog.error("Failed failed encoding audio message with: \(error)")
            }
            
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            guard let url = finalURL else {
                return
            }
            
            self.delegate?.voiceMessageController(self, didRequestSendForFileAtURL: url,
                                                  duration: UInt(duration * 1000),
                                                  samples: invertedSamples) { [weak self] success in
                UINotificationFeedbackGenerator().notificationOccurred((success ? .success : .error))
                self?.deleteRecordingAtURL(sourceURL)
                self?.deleteRecordingAtURL(destinationURL)
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
    
    @objc private func applicationWillResignActive() {
        finishRecording()
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
        let isRecording = audioRecorder?.isRecording ?? false
        
        displayLink.isPaused = !isRecording
        
        let requiredNumberOfSamples = _voiceMessageToolbarView.getRequiredNumberOfSamples()
        
        if audioSamples.count != requiredNumberOfSamples {
            padSamplesArrayToSize(requiredNumberOfSamples)
        }
        
        let sample = audioRecorder?.averagePowerForChannelNumber(0) ?? 0.0
        audioSamples.insert(sample, at: 0)
        audioSamples.removeLast()
        
        let currentTime = audioRecorder?.currentTime ?? 0.0
        
        if currentTime >= Constants.maximumAudioRecordingDuration {
            finishRecording()
            return
        }
        
        var details = VoiceMessageToolbarViewDetails()
        details.state = (isRecording ? (isInLockedMode ? .lockedModeRecord : .record) : (isInLockedMode ? .lockedModePlayback : .idle))
        details.elapsedTime = VoiceMessageController.elapsedTimeFormatter.string(from: Date(timeIntervalSinceReferenceDate: currentTime))
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
        guard let audioPlayer = audioPlayer else {
            return
        }
        
        displayLink.isPaused = !audioPlayer.isPlaying
        
        let requiredNumberOfSamples = _voiceMessageToolbarView.getRequiredNumberOfSamples()
        if audioSamples.count != requiredNumberOfSamples  && requiredNumberOfSamples > 0 {
            padSamplesArrayToSize(requiredNumberOfSamples)
            
            waveformAnalyser = WaveformAnalyzer(audioAssetURL: temporaryFileURL)
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
        details.elapsedTime = VoiceMessageController.elapsedTimeFormatter.string(from: Date(timeIntervalSinceReferenceDate: (audioPlayer.isPlaying ? audioPlayer.currentTime : audioPlayer.duration)))
        details.audioSamples = audioSamples
        details.isPlaying = audioPlayer.isPlaying
        details.progress = (audioPlayer.isPlaying ? (audioPlayer.duration > 0.0 ? audioPlayer.currentTime / audioPlayer.duration : 0.0) : 0.0)
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
