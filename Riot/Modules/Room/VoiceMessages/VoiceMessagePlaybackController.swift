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
    
    private let mediaServiceProvider: VoiceMessageMediaServiceProvider
    private let cacheManager: VoiceMessageAttachmentCacheManager
    
    private var audioPlayer: VoiceMessageAudioPlayer?
    private var displayLink: CADisplayLink!
    private var samples: [Float] = []
    private var duration: TimeInterval = 0
    private var urlToLoad: URL?
    private var loading: Bool = false
    
    private var state: VoiceMessagePlaybackControllerState = .stopped {
        didSet {
            updateUI()
            displayLink.isPaused = (state != .playing)
        }
    }
    
    private static let timeFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = Constants.elapsedTimeFormat
        return dateFormatter
    }()

    
    let playbackView: VoiceMessagePlaybackView
    
    init(mediaServiceProvider: VoiceMessageMediaServiceProvider, cacheManager: VoiceMessageAttachmentCacheManager) {
        self.mediaServiceProvider = mediaServiceProvider
        self.cacheManager = cacheManager
        
        playbackView = VoiceMessagePlaybackView.loadFromNib()
        playbackView.delegate = self
        
        displayLink = CADisplayLink(target: WeakTarget(self, selector: #selector(handleDisplayLinkTick)), selector: WeakTarget.triggerSelector)
        displayLink.isPaused = true
        displayLink.add(to: .current, forMode: .common)
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateTheme), name: .themeServiceDidChangeTheme, object: nil)
        updateTheme()
        updateUI()
    }
    
    var attachment: MXKAttachment? {
        didSet {
            loadAttachmentData()
        }
    }
    
    // MARK: - VoiceMessagePlaybackViewDelegate
    
    func voiceMessagePlaybackViewDidRequestPlaybackToggle() {
        guard let audioPlayer = audioPlayer else {
            return
        }
        
        if audioPlayer.url != nil {
            if audioPlayer.isPlaying {
                audioPlayer.pause()
            } else {
                audioPlayer.play()
            }
        } else if let url = urlToLoad {
            audioPlayer.loadContentFromURL(url, displayName: attachment?.originalFileName)
            audioPlayer.play()
        }
    }
    
    func voiceMessagePlaybackViewDidRequestSeek(to progress: CGFloat) {
        guard let audioPlayer = audioPlayer else {
            return
        }
        
        if audioPlayer.url == nil,
           let url = urlToLoad {
            audioPlayer.loadContentFromURL(url, displayName: attachment?.originalFileName)
        }
        
        audioPlayer.seekToTime(self.duration * Double(progress)) { [weak self] _ in
            guard let self = self else { return }
            self.updateUI()
        }
    }
    
    func voiceMessagePlaybackViewDidChangeWidth() {
        loadAttachmentData()
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
        MXLog.error("Failed playing voice message", context: error)
    }
    
    func audioPlayerDidFinishPlaying(_ audioPlayer: VoiceMessageAudioPlayer) {
        audioPlayer.seekToTime(0.0) { [weak self] _ in
            guard let self = self else { return }
            self.state = .stopped
        }
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
        // Show the current time if the player is paused, show duration when at 0.
        let duration = self.duration
        let currentTime = audioPlayer?.currentTime ?? 0
        let displayTime = currentTime > 0 ? currentTime : duration
        details.currentTime = VoiceMessagePlaybackController.timeFormatter.string(from: Date(timeIntervalSinceReferenceDate: displayTime))
        details.progress = duration > 0 ? currentTime / duration : 0
        details.loading = self.loading
        playbackView.configureWithDetails(details)
    }
        
    private func loadAttachmentData() {
        guard let attachment = attachment else {
            return
        }
        
        self.state = .stopped
        updateUI()
        
        let requiredNumberOfSamples = playbackView.getRequiredNumberOfSamples()
        
        cacheManager.loadAttachment(attachment, numberOfSamples: requiredNumberOfSamples) { [weak self] result in
            guard let self = self else {
                return
            }
            
            switch result {
            case .success(let result):
                guard result.eventIdentifier == attachment.eventId else {
                    return
                }
                
                // Avoid listening to old audio player delegates if the attachment for this playbackController/cell changes
                self.audioPlayer?.deregisterDelegate(self)
                
                self.audioPlayer = self.mediaServiceProvider.audioPlayerForIdentifier(result.eventIdentifier)
                self.audioPlayer?.registerDelegate(self)
                
                self.loading = false
                self.urlToLoad = result.url
                self.duration = result.duration
                self.samples = result.samples
                
                if let audioPlayer = self.audioPlayer {
                    if audioPlayer.isPlaying {
                        self.state = .playing
                    } else if audioPlayer.currentTime > 0 {
                        self.state = .paused
                    } else {
                        self.state = .stopped
                    }
                }
            case .failure:
                self.state = .error
            }
        }
    }
    
    @objc private func updateTheme() {
        playbackView.update(theme: ThemeService.shared().theme)
    }
}
