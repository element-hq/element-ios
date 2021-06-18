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

import UIKit

protocol VoiceMessageToolbarViewDelegate: AnyObject {
    func voiceMessageToolbarViewDidRequestRecordingStart(_ toolbarView: VoiceMessageToolbarView)
    func voiceMessageToolbarViewDidRequestRecordingCancel(_ toolbarView: VoiceMessageToolbarView)
    func voiceMessageToolbarViewDidRequestRecordingFinish(_ toolbarView: VoiceMessageToolbarView)
    func voiceMessageToolbarViewDidRequestLockedModeRecording(_ toolbarView: VoiceMessageToolbarView)
}

enum VoiceMessageToolbarViewUIState {
    case idle
    case record
    case lockedModeRecord
    case lockedModePlayback
}

struct VoiceMessageToolbarViewDetails {
    var state: VoiceMessageToolbarViewUIState = .idle
    var elapsedTime: String = ""
    var audioSamples: [Float] = []
}

class VoiceMessageToolbarView: PassthroughView, Themable, UIGestureRecognizerDelegate {
    @IBOutlet private var backgroundView: UIView!
    
    @IBOutlet private var recordingContainerView: UIView!
    
    @IBOutlet private var recordButtonsContainerView: UIView!
    @IBOutlet private var primaryRecordButton: UIButton!
    @IBOutlet private var secondaryRecordButton: UIButton!
    
    @IBOutlet private var recordingChromeContainerView: UIView!
    @IBOutlet private var recordingIndicatorView: UIView!
    
    @IBOutlet private var elapsedTimeLabel: UILabel!
    
    @IBOutlet private var slideToCancelContainerView: UIView!
    @IBOutlet private var slideToCancelLabel: UILabel!
    @IBOutlet private var slideToCancelChevron: UIImageView!
    @IBOutlet private var slideToCancelGradient: UIImageView!
    
    @IBOutlet private var lockContainerView: UIView!
    @IBOutlet private var lockContainerBackgroundView: UIView!
    @IBOutlet private var primaryLockButton: UIButton!
    @IBOutlet private var secondaryLockButton: UIButton!
    @IBOutlet private var lockChevron: UIView!
    
    @IBOutlet private var lockedModeContainerView: UIView!
    @IBOutlet private var deleteButton: UIButton!
    @IBOutlet private var playbackViewContainerView: UIView!
    @IBOutlet private var sendButton: UIButton!
    
    private var playbackView: VoiceMessagePlaybackView!
    
    private var cancelLabelToRecordButtonDistance: CGFloat = 0.0
    private var lockChevronToRecordButtonDistance: CGFloat = 0.0
    private var lockChevronToLockButtonDistance: CGFloat = 0.0
    private var panDirection: UISwipeGestureRecognizer.Direction?
    
    private var details: VoiceMessageToolbarViewDetails?
    
    private var currentTheme: Theme? {
        didSet {
            updateUIWithDetails(details, animated: true)
        }
    }
    
    weak var delegate: VoiceMessageToolbarViewDelegate?
        
    @objc static func instanceFromNib() -> VoiceMessageToolbarView {
        let nib = UINib(nibName: "VoiceMessageToolbarView", bundle: nil)
        guard let view = nib.instantiate(withOwner: nil, options: nil).first as? Self else {
          fatalError("The nib \(nib) expected its root view to be of type \(self)")
        }
        return view
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        slideToCancelGradient.image = Asset.Images.voiceMessageCancelGradient.image.withRenderingMode(.alwaysTemplate)
        lockContainerBackgroundView.layer.cornerRadius = lockContainerBackgroundView.bounds.width / 2.0
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPressGesture.delegate = self
        longPressGesture.minimumPressDuration = 0.1
        recordButtonsContainerView.addGestureRecognizer(longPressGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        longPressGesture.delegate = self
        recordButtonsContainerView.addGestureRecognizer(panGesture)
        
        playbackView = VoiceMessagePlaybackView.instanceFromNib()
        playbackViewContainerView.vc_addSubViewMatchingParent(playbackView)
        
        updateUIWithDetails(VoiceMessageToolbarViewDetails(), animated: false)
    }
    
    func configureWithDetails(_ details: VoiceMessageToolbarViewDetails) {
        elapsedTimeLabel.text = details.elapsedTime
        
        UIView.animate(withDuration: 0.25) {
            self.updatePlaybackViewWithDetails(details)
        }
        
        if self.details?.state != details.state {
            switch details.state {
            case .record:
                var convertedFrame = self.convert(slideToCancelLabel.frame, from: slideToCancelContainerView)
                cancelLabelToRecordButtonDistance = recordButtonsContainerView.frame.minX - convertedFrame.maxX
                
                convertedFrame = self.convert(lockChevron.frame, from: lockContainerView)
                lockChevronToRecordButtonDistance = recordButtonsContainerView.frame.midY + convertedFrame.maxY
                
                lockChevronToLockButtonDistance = lockChevron.frame.minY - primaryLockButton.frame.midY
                
                startAnimatingRecordingIndicator()
            default:
                cancelDrag()
            }
            
            if details.state == .lockedModeRecord && self.details?.state == .record {
                UIView.animate(withDuration: 0.25) {
                    self.secondaryLockButton.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                    self.secondaryLockButton.alpha = 0.0
                } completion: { _ in
                    self.updateUIWithDetails(details, animated: true)
                }
            } else {
                updateUIWithDetails(details, animated: true)
            }
        }
        
        self.details = details
    }
    
    func getRequiredNumberOfSamples() -> Int {
        return playbackView.getRequiredNumberOfSamples()
    }
    
    // MARK: - Themable
    
    func update(theme: Theme) {
        currentTheme = theme
    }
    
    // MARK: - UIGestureRecognizerDelegate
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // MARK: - Private
    
    @objc private func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        switch gestureRecognizer.state {
        case UIGestureRecognizer.State.began:
            delegate?.voiceMessageToolbarViewDidRequestRecordingStart(self)
        case UIGestureRecognizer.State.ended:
            // delegate?.voiceMessageToolbarViewDidRequestRecordingFinish(self)
            delegate?.voiceMessageToolbarViewDidRequestRecordingCancel(self)
        default:
            break
        }
    }
    
    @objc private func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard details?.state == .record && gestureRecognizer.state == .changed else {
            return
        }
        
        let translation = gestureRecognizer.translation(in: self)
        
        if abs(translation.x) <= 20.0 && abs(translation.y) <= 20.0 {
            panDirection = nil
        } else if panDirection == nil {
            if abs(translation.x) >= abs(translation.y) {
                panDirection = .left
            } else {
                panDirection = .up
            }
        }
        
        if panDirection == .left {
            secondaryRecordButton.transform = CGAffineTransform(translationX: min(translation.x, 0.0), y: 0.0)
            slideToCancelContainerView.transform = CGAffineTransform(translationX: min(translation.x + cancelLabelToRecordButtonDistance, 0.0), y: 0.0)
            
            if abs(translation.x - recordButtonsContainerView.frame.width / 2.0) > self.bounds.width / 2.0 {
                delegate?.voiceMessageToolbarViewDidRequestRecordingCancel(self)
            }
        } else if panDirection == .up {
            secondaryRecordButton.transform = CGAffineTransform(translationX: 0.0, y: min(0.0, translation.y))
            
            let yTranslation = min(max(translation.y + lockChevronToRecordButtonDistance, -lockChevronToLockButtonDistance), 0.0)
            lockChevron.transform = CGAffineTransform(translationX: 0.0, y: yTranslation)
            
            let transitionPercentage = abs(yTranslation) / lockChevronToLockButtonDistance
            
            lockChevron.alpha = 1.0 - transitionPercentage
            secondaryRecordButton.alpha = 1.0 - transitionPercentage
            primaryLockButton.alpha = 1.0 - transitionPercentage
            lockContainerBackgroundView.alpha = 1.0 - transitionPercentage
            secondaryLockButton.alpha = transitionPercentage
            
            if transitionPercentage >= 1.0 {
                self.delegate?.voiceMessageToolbarViewDidRequestLockedModeRecording(self)
            }
            
        } else {
            secondaryRecordButton.transform = CGAffineTransform(translationX: min(0.0, translation.x), y: min(0.0, translation.y))
        }
    }
    
    private func cancelDrag() {
        recordButtonsContainerView.gestureRecognizers?.forEach { gestureRecognizer in
            gestureRecognizer.isEnabled = false
            gestureRecognizer.isEnabled = true
        }
    }
    
    private func updateUIWithDetails(_ details: VoiceMessageToolbarViewDetails?, animated: Bool) {
        guard let details = details else {
            return
        }
        
        UIView.animate(withDuration: (animated ? 0.25 : 0.0), delay: 0.0, options: .beginFromCurrentState) {
            switch details.state {
            case .record:
                self.backgroundView.alpha = 1.0
                self.primaryRecordButton.alpha = 0.0
                self.secondaryRecordButton.alpha = 1.0
                self.recordingChromeContainerView.alpha = 1.0
                self.lockContainerView.alpha = 1.0
                self.lockContainerBackgroundView.alpha = 1.0
                self.lockedModeContainerView.alpha = 0.0
                self.recordingContainerView.alpha = 1.0
            case .lockedModeRecord:
                self.backgroundView.alpha = 1.0
                self.primaryRecordButton.alpha = 0.0
                self.secondaryRecordButton.alpha = 0.0
                self.recordingChromeContainerView.alpha = 0.0
                self.lockContainerView.alpha = 0.0
                self.lockedModeContainerView.alpha = 1.0
                self.recordingContainerView.alpha = 0.0
            default:
                self.backgroundView.alpha = 0.0
                self.primaryRecordButton.alpha = 1.0
                self.secondaryRecordButton.alpha = 0.0
                self.recordingChromeContainerView.alpha = 0.0
                self.lockContainerView.alpha = 0.0
                self.lockContainerBackgroundView.alpha = 1.0
                self.primaryLockButton.alpha = 1.0
                self.secondaryLockButton.alpha = 0.0
                self.lockChevron.alpha = 1.0
                self.lockedModeContainerView.alpha = 0.0
                self.recordingContainerView.alpha = 1.0
            }
            
            guard let theme = self.currentTheme else {
                return
            }
            
            self.backgroundView.backgroundColor = theme.backgroundColor
            self.slideToCancelGradient.tintColor = theme.backgroundColor
            
            self.primaryRecordButton.tintColor = theme.textTertiaryColor
            self.slideToCancelLabel.textColor = theme.textSecondaryColor
            self.slideToCancelChevron.tintColor = theme.textSecondaryColor
            self.elapsedTimeLabel.textColor = theme.textSecondaryColor
        } completion: { _ in
            switch details.state {
            case .idle:
                self.secondaryRecordButton.transform = .identity
                self.slideToCancelContainerView.transform = .identity
                self.lockChevron.transform = .identity
                self.secondaryLockButton.transform = .identity
            default:
                break
            }
        }
    }
    
    private func updatePlaybackViewWithDetails(_ details: VoiceMessageToolbarViewDetails) {
        var playbackViewDetails = VoiceMessagePlaybackViewDetails()
        playbackViewDetails.recording = (details.state == .record || details.state == .lockedModeRecord)
        playbackViewDetails.currentTime = details.elapsedTime
        playbackViewDetails.samples = details.audioSamples
        playbackViewDetails.playbackEnabled = true
        playbackViewDetails.progress = 0.0
        playbackView.configureWithDetails(playbackViewDetails)
    }
    
    private func startAnimatingRecordingIndicator() {
        if self.details?.state != .record {
            return
        }
        
        UIView.animate(withDuration: 0.5) {
            if self.recordingIndicatorView.alpha > 0.0 {
                self.recordingIndicatorView.alpha = 0.0
            } else {
                self.recordingIndicatorView.alpha = 1.0
            }
        } completion: { [weak self] _ in
            self?.startAnimatingRecordingIndicator()
        }
        
    }
    
    @IBAction private func onTrashButtonTap(_ sender: UIBarItem) {
        delegate?.voiceMessageToolbarViewDidRequestRecordingCancel(self)
    }
    
    @IBAction private func onSendButtonTap(_ sender: UIBarItem) {
        delegate?.voiceMessageToolbarViewDidRequestRecordingFinish(self)
    }
}
