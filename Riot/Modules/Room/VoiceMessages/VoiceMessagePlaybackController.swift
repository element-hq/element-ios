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
import DSWaveformImage

enum VoiceMessagePlaybackControllerState {
    case stopped
    case playing
    case paused
    case error
}

class VoiceMessagePlaybackController: VoiceMessageAudioPlayerDelegate, VoiceMessagePlaybackViewDelegate {
    
    private enum Constants {
        static let elapsedTimeFormat = "m:ss"
    }
    
    private static let timeFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = Constants.elapsedTimeFormat
        return dateFormatter
    }()

    private let audioPlayer: VoiceMessageAudioPlayer
    private var displayLink: CADisplayLink!
    private var samples: [Float] = []
    
    private var state: VoiceMessagePlaybackControllerState = .stopped {
        didSet {
            updateUI()
            displayLink.isPaused = (state != .playing)
        }
    }
    
    let playbackView: VoiceMessagePlaybackView
    
    init(mediaServiceProvider: VoiceMessageMediaServiceProvider) {
        playbackView = VoiceMessagePlaybackView.loadFromNib()
        audioPlayer = mediaServiceProvider.audioPlayer()
        
        audioPlayer.registerDelegate(self)
        playbackView.delegate = self
        
        displayLink = CADisplayLink(target: WeakObjectWrapper(self), selector: #selector(handleDisplayLinkTick))
        displayLink.isPaused = true
        displayLink.add(to: .current, forMode: .common)
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateTheme), name: .themeServiceDidChangeTheme, object: nil)
        updateTheme()
    }
 
    var attachment: MXKAttachment? {
        didSet {
            if oldValue?.contentURL == attachment?.contentURL &&
                oldValue?.eventSentState == attachment?.eventSentState {
                return
            }
            
            switch attachment?.eventSentState {
            case MXEventSentStateFailed:
                state = .error
            default:
                state = .stopped
                loadAttachmentData()
            }
        }
    }
    
    // MARK: - VoiceMessagePlaybackViewDelegate
    
    func voiceMessagePlaybackViewDidRequestPlaybackToggle() {
        if audioPlayer.isPlaying {
            audioPlayer.pause()
        } else {
            audioPlayer.play()
        }
    }
    
    // MARK: - VoiceMessageAudioPlayerDelegate
    
    func audioPlayerDidFinishLoading(_ audioPlayer: VoiceMessageAudioPlayer) {
        updateUI()
    }
    
    func audioPlayerDidStartPlaying(_ audioPlayer: VoiceMessageAudioPlayer) {
        state = .playing
    }
    
    func audioPlayerDidPausePlaying(_ audioPlayer: VoiceMessageAudioPlayer) {
        state = .paused
    }
    
    func audioPlayerDidStopPlaying(_ audioPlayer: VoiceMessageAudioPlayer) {
        state = .stopped
    }
    
    func audioPlayer(_ audioPlayer: VoiceMessageAudioPlayer, didFailWithError error: Error) {
        state = .error
        MXLog.error("Failed playing voice message with error: \(error)")
    }
    
    func audioPlayerDidFinishPlaying(_ audioPlayer: VoiceMessageAudioPlayer) {
        audioPlayer.seekToTime(0.0)
        state = .stopped
    }
    
    // MARK: - Private
    
    @objc private func handleDisplayLinkTick() {
        updateUI()
    }
    
    private func updateUI() {
        var details = VoiceMessagePlaybackViewDetails()
        
        details.playbackEnabled = (state != .error)
        details.playing = (state == .playing)
        details.samples = samples
        
        switch state {
        case .stopped:
            details.currentTime = VoiceMessagePlaybackController.timeFormatter.string(from: Date(timeIntervalSinceReferenceDate: audioPlayer.duration))
            details.progress = 0.0
        default:
            details.currentTime = VoiceMessagePlaybackController.timeFormatter.string(from: Date(timeIntervalSinceReferenceDate: audioPlayer.currentTime))
            details.progress = (audioPlayer.duration > 0.0 ? audioPlayer.currentTime / audioPlayer.duration : 0.0)
        }
        
        playbackView.configureWithDetails(details)
    }
    
    private func loadAttachmentData() {
        guard let attachment = attachment else {
            return
        }
        
        if attachment.isEncrypted {
            attachment.decrypt(toTempFile: { [weak self] filePath in
                self?.convertAndLoadFileAtPath(filePath)
            }, failure: { [weak self] error in
                // A nil error in this case is a cancellation on the MXMediaLoader
                if let error = error {
                    MXLog.error("Failed decrypting attachment with error: \(String(describing: error))")
                    self?.state = .error
                }
            })
        } else {
            attachment.prepare({ [weak self] in
                self?.convertAndLoadFileAtPath(attachment.cacheFilePath)
            }, failure: { [weak self] error in
                // A nil error in this case is a cancellation on the MXMediaLoader
                if let error = error {
                    MXLog.error("Failed preparing attachment with error: \(String(describing: error))")
                    self?.state = .error
                }
            })
        }
    }
    
    private func convertAndLoadFileAtPath(_ path: String?) {
        guard let filePath = path else {
            return
        }
        
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let newURL = temporaryDirectoryURL.appendingPathComponent(ProcessInfo().globallyUniqueString).appendingPathExtension("m4a")
        
        VoiceMessageAudioConverter.convertToMPEG4AAC(sourceURL: URL(fileURLWithPath: filePath), destinationURL: newURL) { [weak self] result in
            switch result {
            case .success:
                self?.loadFileAtURL(newURL)
            case .failure(let error):
                self?.state = .error
                MXLog.error("Failed failed decoding audio message with: \(error)")
            }
        }
    }
    
    private func loadFileAtURL(_ url: URL) {
        
        audioPlayer.loadContentFromURL(url)
        
        let requiredNumberOfSamples = playbackView.getRequiredNumberOfSamples()
        
        if requiredNumberOfSamples == 0 {
            return
        }
        
        let analyser = WaveformAnalyzer(audioAssetURL: url)
        analyser?.samples(count: requiredNumberOfSamples, completionHandler: { [weak self] samples in
            guard let samples = samples else {
                self?.state = .error
                return
            }
            
            DispatchQueue.main.async {
                self?.samples = samples
                self?.updateUI()
            }
        })
    }
    
    
    @objc private func updateTheme() {
        playbackView.update(theme: ThemeService.shared().theme)
    }
}
