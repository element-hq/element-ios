// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import Reusable

@objcMembers
class RemoveJitsiWidgetView: UIView {
    
    private enum Constants {
        static let activationThreshold: CGFloat = 0.5
    }
    
    private enum State: Equatable {
        case notStarted
        case sliding(percentage: CGFloat)
        case completed
        
        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.notStarted, .notStarted):
                return true
            case (let .sliding(percentage1), let .sliding(percentage2)):
                return percentage1 == percentage2
            case (.completed, .completed):
                return true
            default:
                return false
            }
        }
    }
    
    @IBOutlet private weak var slidingViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var slidingView: UIView!
    @IBOutlet private weak var slidingViewLabel: UILabel! {
        didSet {
            slidingViewLabel.text = VectorL10n.roomSlideToEndGroupCall
        }
    }
    @IBOutlet private weak var arrowsView: ArrowsAnimationView!
    @IBOutlet private weak var hangupView: UIView!
    @IBOutlet private weak var hangupImage: UIImageView!
    @IBOutlet private weak var topSeparatorView: UIView!
    @IBOutlet private weak var bottomSeparatorView: UIView!
    
    private var state: State = .notStarted
    private var theme: Theme = ThemeService.shared().theme
    
    //  MARK - Private
    
    private func configure(withState state: State) {
        switch state {
        case .notStarted:
            arrowsView.isAnimating = false
            hangupView.backgroundColor = .clear
            hangupImage.tintColor = theme.noticeColor
            slidingViewLeadingConstraint.constant = 0
        case .sliding(let percentage):
            arrowsView.isAnimating = true
            if percentage < Constants.activationThreshold {
                hangupView.backgroundColor = .clear
                hangupImage.tintColor = theme.noticeColor
            } else {
                hangupView.backgroundColor = theme.noticeColor
                hangupImage.tintColor = theme.callScreenButtonTintColor
            }
            slidingViewLeadingConstraint.constant = percentage * slidingView.frame.width
        case .completed:
            arrowsView.isAnimating = false
            hangupView.backgroundColor = theme.noticeColor
            hangupImage.tintColor = theme.callScreenButtonTintColor
        }
    }
    
    private func updateState(to newState: State) {
        guard newState != state else {
            return
        }
        configure(withState: newState)
        state = newState
        
        if state == .completed {
            delegate?.removeJitsiWidgetViewDidCompleteSliding(self)
        }
    }
    
    //  MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        if state == .notStarted {
            updateState(to: .sliding(percentage: 0))
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        
        switch state {
        case .sliding:
            if let touch = touches.first {
                let touchLocation = touch.location(in: self)
                if frame.contains(touchLocation) {
                    let percentage = touchLocation.x / frame.width
                    updateState(to: .sliding(percentage: percentage))
                }
            }
        default:
            break
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        switch state {
        case .sliding(let percentage):
            if percentage < Constants.activationThreshold {
                updateState(to: .notStarted)
            } else {
                updateState(to: .completed)
            }
        default:
            break
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        
        switch state {
        case .sliding(let percentage):
            if percentage < Constants.activationThreshold {
                updateState(to: .notStarted)
            } else {
                updateState(to: .completed)
            }
        default:
            break
        }
    }
    
    //  MARK: - API
    
    weak var delegate: RemoveJitsiWidgetViewDelegate?
    
    static func instantiate() -> RemoveJitsiWidgetView {
        let view = RemoveJitsiWidgetView.loadFromNib()
        view.update(theme: ThemeService.shared().theme)
        return view
    }
    
    func reset() {
        updateState(to: .notStarted)
    }
    
}

//  MARK: - NibLoadable

extension RemoveJitsiWidgetView: NibLoadable { }

//  MARK: - Themable

extension RemoveJitsiWidgetView: Themable {
    
    func update(theme: Theme) {
        self.theme = theme
        
        self.backgroundColor = theme.headerBackgroundColor
        
        slidingViewLabel.textColor = theme.textPrimaryColor
        arrowsView.update(theme: theme)
        topSeparatorView.backgroundColor = theme.lineBreakColor
        bottomSeparatorView.backgroundColor = theme.lineBreakColor
        
        configure(withState: state)
    }
    
}
