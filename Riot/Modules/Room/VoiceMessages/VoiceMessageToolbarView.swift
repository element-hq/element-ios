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
import Reusable

protocol VoiceMessageToolbarViewDelegate: AnyObject {
    func voiceMessageToolbarViewDidRequestRecordingStart(_ toolbarView: VoiceMessageToolbarView)
    func voiceMessageToolbarViewDidRequestRecordingCancel(_ toolbarView: VoiceMessageToolbarView)
    func voiceMessageToolbarViewDidRequestRecordingFinish(_ toolbarView: VoiceMessageToolbarView)
    func voiceMessageToolbarViewDidRequestLockedModeRecording(_ toolbarView: VoiceMessageToolbarView)
    func voiceMessageToolbarViewDidRequestPlaybackToggle(_ toolbarView: VoiceMessageToolbarView)
    func voiceMessageToolbarViewDidRequestSeek(to progress: CGFloat)
    func voiceMessageToolbarViewDidRequestSend(_ toolbarView: VoiceMessageToolbarView)
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
    var isPlaying: Bool = false
    var progress: Double = 0.0
    var toastMessage: String?
}

class VoiceMessageToolbarView: PassthroughView, NibLoadable, Themable, UIGestureRecognizerDelegate, VoiceMessagePlaybackViewDelegate {
    
    private enum Constants {
        static let longPressMinimumDuration: TimeInterval = 0.0
        static let animationDuration: TimeInterval = 0.25
        static let lockModeTransitionAnimationDuration: TimeInterval = 0.5
        static let panDirectionChangeThreshold: CGFloat = 20.0
        static let toastContainerCornerRadii: CGFloat = 8.0
        static let toastDisplayTimeout: TimeInterval = 5.0
    }
    
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
    
    @IBOutlet private var lockButtonsContainerView: UIView!
    @IBOutlet private var primaryLockButton: UIButton!
    @IBOutlet private var secondaryLockButton: UIButton!
    @IBOutlet private var lockChevron: UIView!
    
    @IBOutlet private var lockedModeContainerView: UIView!
    @IBOutlet private var deleteButton: UIButton!
    @IBOutlet private var playbackViewContainerView: UIView!
    @IBOutlet private var sendButton: UIButton!
    
    @IBOutlet private var toastNotificationContainerView: UIView!
    @IBOutlet private var toastNotificationLabel: UILabel!
    
    @IBOutlet var containersTopConstraints: [NSLayoutConstraint]!
    
    private var playbackView: VoiceMessagePlaybackView!
    
    private var cancelLabelToRecordButtonDistance: CGFloat = 0.0
    private var lockChevronToRecordButtonDistance: CGFloat = 0.0
    private var lockChevronToLockButtonDistance: CGFloat = 0.0
    private var panDirection: UISwipeGestureRecognizer.Direction?
    private var tapGesture: UITapGestureRecognizer!
    
    private var details: VoiceMessageToolbarViewDetails?
    
    private var currentTheme: Theme? {
        didSet {
            updateUIWithDetails(details, animated: true)
        }
    }
    
    weak var delegate: VoiceMessageToolbarViewDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        lockContainerBackgroundView.layer.cornerRadius = lockContainerBackgroundView.bounds.width / 2.0
        lockButtonsContainerView.layer.cornerRadius = lockButtonsContainerView.bounds.width / 2.0
        toastNotificationContainerView.layer.cornerRadius = Constants.toastContainerCornerRadii
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPressGesture.delegate = self
        longPressGesture.minimumPressDuration = Constants.longPressMinimumDuration
        recordButtonsContainerView.addGestureRecognizer(longPressGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        longPressGesture.delegate = self
        recordButtonsContainerView.addGestureRecognizer(panGesture)
        
        playbackView = VoiceMessagePlaybackView.loadFromNib()
        playbackView.delegate = self
        playbackViewContainerView.vc_addSubViewMatchingParent(playbackView)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleWaveformTap))
        playbackView.waveformView.addGestureRecognizer(tapGesture)
        tapGesture.delegate = self
        self.tapGesture = tapGesture
        primaryRecordButton.accessibilityLabel = VectorL10n.roomAccessibilityRecordVoiceMessage
        primaryRecordButton.accessibilityHint = VectorL10n.roomAccessibilityRecordVoiceMessageHint
        
        updateUIWithDetails(VoiceMessageToolbarViewDetails(), animated: false)
    }
    
    func configureWithDetails(_ details: VoiceMessageToolbarViewDetails) {
        elapsedTimeLabel.text = details.elapsedTime
        
        self.updateToastNotificationsWithDetails(details)
        self.updatePlaybackViewWithDetails(details)
        
        if self.details?.state != details.state {
            switch details.state {
            case .record:
                var convertedFrame = self.convert(slideToCancelLabel.frame, from: slideToCancelContainerView)
                cancelLabelToRecordButtonDistance = recordButtonsContainerView.frame.minX - convertedFrame.maxX
                
                convertedFrame = self.convert(lockChevron.frame, from: lockContainerView)
                lockChevronToRecordButtonDistance = recordButtonsContainerView.frame.midY + convertedFrame.maxY
                
                lockChevronToLockButtonDistance = (lockChevron.frame.minY - lockButtonsContainerView.frame.midY) / 2
                
                startAnimatingRecordingIndicator()
            default:
                cancelDrag()
            }
            
            if details.state == .lockedModeRecord && self.details?.state == .record {
                UIView.animate(withDuration: Constants.animationDuration) {
                    self.lockButtonsContainerView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
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
        playbackView.update(theme: theme)
    }
    
    // MARK: - UIGestureRecognizerDelegate
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == self.tapGesture, self.lastUIState != .lockedModeRecord {
            return false
        }
        return true
    }
    
    // MARK: - VoiceMessagePlaybackViewDelegate
    
    func voiceMessagePlaybackViewDidRequestPlaybackToggle() {
        delegate?.voiceMessageToolbarViewDidRequestPlaybackToggle(self)
    }

    func voiceMessagePlaybackViewDidRequestSeek(to progress: CGFloat) {
        delegate?.voiceMessageToolbarViewDidRequestSeek(to: progress)
    }
    
    func voiceMessagePlaybackViewDidChangeWidth() {
        
    }
    
    // MARK: - Private
    
    @objc private func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        switch gestureRecognizer.state {
        case UIGestureRecognizer.State.began:
            delegate?.voiceMessageToolbarViewDidRequestRecordingStart(self)
        case UIGestureRecognizer.State.ended:
            delegate?.voiceMessageToolbarViewDidRequestRecordingFinish(self)
        default:
            break
        }
    }
    
    @objc private func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard details?.state == .record && gestureRecognizer.state == .changed else {
            return
        }
        
        let translation = gestureRecognizer.translation(in: self)
        
        if abs(translation.x) <= Constants.panDirectionChangeThreshold && abs(translation.y) <= Constants.panDirectionChangeThreshold {
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
        
        UIView.animate(withDuration: (animated ? Constants.animationDuration : 0.0), delay: 0.0, options: .beginFromCurrentState) {
            switch details.state {
            case .record:
                self.lockContainerBackgroundView.alpha = 1.0
            case .idle:
                self.lockContainerBackgroundView.alpha = 1.0
                self.primaryLockButton.alpha = 1.0
                self.secondaryLockButton.alpha = 0.0
                self.lockChevron.alpha = 1.0
            default:
                break
            }
            
            self.backgroundView.alpha = (details.state == .idle ? 0.0 : 1.0)
            self.primaryRecordButton.alpha = (details.state == .idle ? 1.0 : 0.0)
            self.secondaryRecordButton.alpha = (details.state == .record ? 1.0 : 0.0)
            self.recordingChromeContainerView.alpha = (details.state == .record ? 1.0 : 0.0)
            self.lockContainerView.alpha = (details.state == .record ? 1.0 : 0.0)
            self.lockedModeContainerView.alpha = (details.state == .lockedModePlayback || details.state == .lockedModeRecord ? 1.0 : 0.0)
            self.recordingContainerView.alpha = (details.state == .idle || details.state == .record ? 1.0 : 0.0)
            
            guard let theme = self.currentTheme else {
                return
            }
            
            self.backgroundView.backgroundColor = theme.colors.background
            self.slideToCancelGradient.tintColor = theme.colors.background
            
            self.primaryRecordButton.tintColor = theme.colors.tertiaryContent
            self.slideToCancelLabel.textColor = theme.colors.secondaryContent
            self.slideToCancelChevron.tintColor = theme.colors.secondaryContent
            self.elapsedTimeLabel.textColor = theme.colors.secondaryContent
            
            self.lockContainerBackgroundView.backgroundColor = theme.colors.navigation
            self.lockButtonsContainerView.backgroundColor = theme.colors.navigation
            
        } completion: { _ in
            switch details.state {
            case .idle:
                self.secondaryRecordButton.transform = .identity
                self.slideToCancelContainerView.transform = .identity
                self.lockChevron.transform = .identity
                self.lockButtonsContainerView.transform = .identity
            default:
                break
            }
        }
    }
    
    private var toastIdleTimer: Timer?
    private var lastUIState: VoiceMessageToolbarViewUIState = .idle
    
    private func updateToastNotificationsWithDetails(_ details: VoiceMessageToolbarViewDetails, animated: Bool = true) {
        
        guard self.toastNotificationLabel.text != details.toastMessage || lastUIState != details.state else {
            return
        }
        
        lastUIState = details.state
        
        let shouldShowNotification = details.state != .idle && details.toastMessage != nil
        let requiredAlpha: CGFloat = shouldShowNotification ? 1.0 : 0.0
        
        toastIdleTimer?.invalidate()
        toastIdleTimer = nil
        
        if shouldShowNotification {
            self.toastNotificationLabel.text = details.toastMessage
        }
        
        UIView.animate(withDuration: (animated ? Constants.animationDuration : 0.0)) {
            self.toastNotificationContainerView.alpha = requiredAlpha
        }
        
        if shouldShowNotification {
            toastIdleTimer = Timer.scheduledTimer(withTimeInterval: Constants.toastDisplayTimeout, repeats: false) { [weak self] timer in
                guard let self = self else {
                    return
                }
                
                self.toastIdleTimer?.invalidate()
                self.toastIdleTimer = nil
                
                UIView.animate(withDuration: Constants.animationDuration) {
                    self.toastNotificationContainerView.alpha = 0
                }
            }
        }
    }
    
    private func updatePlaybackViewWithDetails(_ details: VoiceMessageToolbarViewDetails, animated: Bool = true) {
        UIView.animate(withDuration: (animated ? Constants.animationDuration : 0.0)) {
            var playbackViewDetails = VoiceMessagePlaybackViewDetails()
            playbackViewDetails.recording = (details.state == .record || details.state == .lockedModeRecord)
            playbackViewDetails.playing = details.isPlaying
            playbackViewDetails.progress = details.progress
            playbackViewDetails.currentTime = details.elapsedTime
            playbackViewDetails.samples = details.audioSamples
            playbackViewDetails.playbackEnabled = true
            self.playbackView.configureWithDetails(playbackViewDetails)
        }
    }
    
    private func startAnimatingRecordingIndicator() {
        if self.details?.state != .record {
            return
        }
        
        UIView.animate(withDuration: Constants.lockModeTransitionAnimationDuration) {
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
        delegate?.voiceMessageToolbarViewDidRequestSend(self)
    }
    
    @objc private func handleWaveformTap(_ gestureRecognizer: UITapGestureRecognizer) {
        guard self.lastUIState == .lockedModeRecord else {
            return
        }

        delegate?.voiceMessageToolbarViewDidRequestRecordingFinish(self)
    }
}
