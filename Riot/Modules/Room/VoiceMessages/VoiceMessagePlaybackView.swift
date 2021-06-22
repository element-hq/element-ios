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

protocol VoiceMessagePlaybackViewDelegate: AnyObject {
    func voiceMessagePlaybackViewDidRequestPlaybackToggle()
}

struct VoiceMessagePlaybackViewDetails {
    var currentTime: String = ""
    var progress = 0.0
    var samples: [Float] = []
    var playing: Bool = false
    var playbackEnabled = false
    var recording: Bool = false
}

class VoiceMessagePlaybackView: UIView {
    
    private var _waveformView: VoiceMessageWaveformView!
    
    @IBOutlet private var backgroundView: UIView!
    @IBOutlet private var recordingIcon: UIView!
    @IBOutlet private var playButton: UIButton!
    @IBOutlet private var elapsedTimeLabel: UILabel!
    @IBOutlet private var waveformContainerView: UIView!
    
    weak var delegate: VoiceMessagePlaybackViewDelegate?
    
    var details: VoiceMessagePlaybackViewDetails?
    
    var waveformView: UIView {
        return _waveformView
    }
    
    static func instanceFromNib() -> VoiceMessagePlaybackView {
        let nib = UINib(nibName: "VoiceMessagePlaybackView", bundle: nil)
        guard let view = nib.instantiate(withOwner: nil, options: nil).first as? Self else {
          fatalError("The nib \(nib) expected its root view to be of type \(self)")
        }
        return view
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleThemeDidChange), name: .themeServiceDidChangeTheme, object: nil)
        
        backgroundView.layer.cornerRadius = 12.0
        
        _waveformView = VoiceMessageWaveformView(frame: waveformContainerView.bounds)
        waveformContainerView.vc_addSubViewMatchingParent(_waveformView)
    }
    
    func configureWithDetails(_ details: VoiceMessagePlaybackViewDetails?) {
        guard let details = details else {
            return
        }
        
        playButton.isEnabled = details.playbackEnabled
        
        UIView.performWithoutAnimation {
            // UIStackView doesn't respond well to re-setting hidden states https://openradar.appspot.com/22819594
            if playButton.isHidden != details.recording {
                playButton.isHidden = details.recording
            }
            
            // UIStackView doesn't respond well to re-setting hidden states https://openradar.appspot.com/22819594
            if recordingIcon.isHidden != !details.recording {
                recordingIcon.isHidden = !details.recording
            }
        }
        
        elapsedTimeLabel.text = details.currentTime
        _waveformView.progress = details.progress
        
        if ThemeService.shared().isCurrentThemeDark() {
            playButton.setImage((details.playing ? Asset.Images.voiceMessagePauseButtonDark.image : Asset.Images.voiceMessagePlayButtonDark.image), for: .normal)
            backgroundView.backgroundColor = UIColor(rgb: 0x394049)
            _waveformView.primarylineColor =  ThemeService.shared().theme.colors.quarterlyContent
            _waveformView.secondaryLineColor = ThemeService.shared().theme.colors.secondaryContent
            elapsedTimeLabel.textColor = UIColor(rgb: 0x8E99A4)
        } else {
            playButton.setImage((details.playing ? Asset.Images.voiceMessagePauseButtonLight.image : Asset.Images.voiceMessagePlayButtonLight.image), for: .normal)
            backgroundView.backgroundColor = UIColor(rgb: 0xE3E8F0)
            _waveformView.primarylineColor = ThemeService.shared().theme.colors.quarterlyContent
            _waveformView.secondaryLineColor = ThemeService.shared().theme.colors.secondaryContent
            elapsedTimeLabel.textColor = UIColor(rgb: 0x737D8C)
        }
        
        _waveformView.setSamples(details.samples)
        
        self.details = details
    }
    
    func getRequiredNumberOfSamples() -> Int {
        _waveformView.setNeedsLayout()
        _waveformView.layoutIfNeeded()
        return _waveformView.requiredNumberOfSamples
    }
    
    // MARK: - Private
        
    @IBAction private func onPlayButtonTap() {
        delegate?.voiceMessagePlaybackViewDidRequestPlaybackToggle()
    }
    
    @objc private func handleThemeDidChange() {
        configureWithDetails(details)
    }
}
