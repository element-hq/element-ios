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

private enum VoiceMessagePlaybackViewUIState {
    case stopped
    case playing
    case paused
    case error
}

class VoiceMessagePlaybackView: UIView, VoiceMessageAudioPlayerDelegate {
    
    private let audioPlayer: VoiceMessageAudioPlayer
    private var displayLink: CADisplayLink!
    private let timeFormatter: DateFormatter
    private var waveformView: VoiceMessageWaveformView!
    
    @IBOutlet private var backgroundView: UIView!
    @IBOutlet private var playButton: UIButton!
    @IBOutlet private var elapsedTimeLabel: UILabel!
    @IBOutlet private var waveformContainerView: UIView!
    
    private var state: VoiceMessagePlaybackViewUIState = .stopped {
        didSet {
            updateUI()
            displayLink.isPaused = (state != .playing)
        }
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
    
    static func instanceFromNib() -> VoiceMessagePlaybackView {
        let nib = UINib(nibName: "VoiceMessagePlaybackView", bundle: nil)
        guard let view = nib.instantiate(withOwner: nil, options: nil).first as? Self else {
          fatalError("The nib \(nib) expected its root view to be of type \(self)")
        }
        return view
    }
    
    override func didMoveToWindow() {
        if self.window == nil {
            audioPlayer.stop()
            displayLink.invalidate()
        }
    }
        
    required init?(coder: NSCoder) {
        audioPlayer = VoiceMessageAudioPlayer()
        
        timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "m:ss"

        super.init(coder: coder)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleThemeDidChange), name: .themeServiceDidChangeTheme, object: nil)
        
        audioPlayer.delegate = self
        
        displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLinkTick))
        displayLink.isPaused = true
        displayLink.add(to: .current, forMode: .common)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundView.layer.cornerRadius = 12.0
        
        waveformView = VoiceMessageWaveformView(frame: waveformContainerView.bounds)
        waveformContainerView.vc_addSubViewMatchingParent(waveformView)
        
        updateUI()
    }
    
    // MARK: - VoiceMessageAudioPlayerDelegate
    
    func audioPlayerDidFinishLoading(_ audioPlayer: VoiceMessageAudioPlayer) {
        updateUI()
    }
    
    func audioPlayerDidStartPlaying(_ audioPlayer: VoiceMessageAudioPlayer) {
        state = .playing
    }
    
    func audioPlayerDidStopPlaying(_ audioPlayer: VoiceMessageAudioPlayer) {
        state = .paused
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
    
    private func updateUI() {
        playButton.isEnabled = (state != .error)
        
        if ThemeService.shared().isCurrentThemeDark() {
            playButton.setImage((state == .playing ? Asset.Images.voiceMessagePauseButtonDark.image : Asset.Images.voiceMessagePlayButtonDark.image), for: .normal)
            backgroundView.backgroundColor = UIColor(rgb: 0x394049)
            waveformView.primarylineColor =  ThemeService.shared().theme.colors.quarterlyContent
            waveformView.secondaryLineColor = ThemeService.shared().theme.colors.secondaryContent
            elapsedTimeLabel.textColor = UIColor(rgb: 0x8E99A4)
        } else {
            playButton.setImage((state == .playing ? Asset.Images.voiceMessagePauseButtonLight.image : Asset.Images.voiceMessagePlayButtonLight.image), for: .normal)
            backgroundView.backgroundColor = UIColor(rgb: 0xE3E8F0)
            waveformView.primarylineColor = ThemeService.shared().theme.colors.quarterlyContent
            waveformView.secondaryLineColor = ThemeService.shared().theme.colors.secondaryContent
            elapsedTimeLabel.textColor = UIColor(rgb: 0x737D8C)
        }
        
        switch state {
        case .stopped:
            elapsedTimeLabel.text = timeFormatter.string(from: Date(timeIntervalSinceReferenceDate: audioPlayer.duration))
            waveformView.progress = 0.0
        default:
            elapsedTimeLabel.text = timeFormatter.string(from: Date(timeIntervalSinceReferenceDate: audioPlayer.currentTime))
            waveformView.progress = (audioPlayer.duration > 0.0 ? audioPlayer.currentTime / audioPlayer.duration : 0.0)
        }
    }
    
    @IBAction private func onPlayButtonTap() {
        if audioPlayer.isPlaying {
            audioPlayer.pause()
        } else {
            audioPlayer.play()
        }
    }
    
    @objc private func handleDisplayLinkTick() {
        updateUI()
    }
    
    private func loadAttachmentData() {
        guard let attachment = attachment else {
            return
        }
        
        if attachment.isEncrypted {
            attachment.decrypt(toTempFile: { [weak self] filePath in
                self?.loadFileAtPath(filePath)
            }, failure: { [weak self] error in
                // A nil error in this case is a cancellation on the MXMediaLoader
                if let error = error {
                    MXLog.error("Failed decrypting attachment with error: \(String(describing: error))")
                    self?.state = .error
                }
            })
        } else {
            attachment.prepare({ [weak self] in
                self?.loadFileAtPath(attachment.cacheFilePath)
            }, failure: { [weak self] error in
                MXLog.error("Failed preparing attachment with error: \(String(describing: error))")
                self?.state = .error
            })
        }
    }
    
    private func loadFileAtPath(_ path: String?) {
        guard let filePath = path else {
            return
        }
        
        let url = URL(fileURLWithPath: filePath)
        
        // AVPlayer doesn't want to play it otherwise. https://stackoverflow.com/a/9350824
        let newURL = url.appendingPathExtension("m4a")
        
        do {
            try FileManager.default.moveItem(at: url, to: newURL)
        } catch {
            self.state = .error
            MXLog.error("Failed appending voice message extension.")
            return
        }
        
        audioPlayer.loadContentFromURL(newURL)
        
        waveformView.setNeedsLayout()
        waveformView.layoutIfNeeded()
        
        if waveformView.requiredNumberOfSamples == 0 {
            return
        }
        
        let analyser = WaveformAnalyzer(audioAssetURL: newURL)
        analyser?.samples(count: waveformView.requiredNumberOfSamples, completionHandler: { [weak self] samples in
            guard let samples = samples else {
                self?.state = .error
                return
            }
            
            DispatchQueue.main.async {
                self?.waveformView.setSamples(samples)
            }
        })
    }
    
    @objc private func handleThemeDidChange() {
        updateUI()
    }
}
