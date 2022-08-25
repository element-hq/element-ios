/*
 Copyright 2019 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Reusable
import UIKit

protocol SlidingModalContainerViewDelegate: AnyObject {
    func slidingModalContainerViewDidTapBackground(_ view: SlidingModalContainerView)
}

/// `SlidingModalContainerView` is a custom UIView used as a `UIViewControllerContextTransitioning.containerView` subview to embed a `SlidingModalPresentable` during presentation.
class SlidingModalContainerView: UIView, Themable, NibLoadable {
    // MARK: - Constants
    
    private enum Constants {
        static let cornerRadius: CGFloat = 12.0
        static let dimmingColorAlpha: CGFloat = 0.7
    }
    
    private enum Sizing {
        static let view = SlidingModalContainerView.loadFromNib()
        static var widthConstraint: NSLayoutConstraint?
        static var heightConstraint: NSLayoutConstraint?
    }
    
    // MARK: - Properties
    
    private weak var blurView: UIVisualEffectView?
    var blurBackground = false {
        didSet {
            if blurBackground {
                let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
                blurView.frame = dimmingView.bounds
                blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                dimmingView.addSubview(blurView)
                self.blurView = blurView
                dimmingView.backgroundColor = .clear
            } else {
                blurView?.removeFromSuperview()
                dimmingView.backgroundColor = UIColor.black.withAlphaComponent(Constants.dimmingColorAlpha)
            }
        }
    }
    
    var centerInScreen = false
    
    // MARK: Outlets
    
    @IBOutlet private var dimmingView: UIView!
    @IBOutlet private var contentView: UIView!
    
    @IBOutlet private var contentViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var contentViewBottomConstraint: NSLayoutConstraint!
    
    // MARK: Private
    
    private var dismissContentViewBottomConstant: CGFloat {
        let bottomSafeAreaHeight: CGFloat
        
        bottomSafeAreaHeight = contentView.safeAreaInsets.bottom
        
        return -(contentViewHeightConstraint.constant + bottomSafeAreaHeight)
    }
    
    // used to avoid changing constraint during animations
    private var lastBounds: CGRect?
    
    // MARK: Public
    
    var contentViewFrame: CGRect {
        self.contentView.frame
    }
    
    weak var delegate: SlidingModalContainerViewDelegate?
    
    // MARK: - Setup
    
    static func instantiate() -> SlidingModalContainerView {
        loadFromNib()
    }
        
    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentView.layer.masksToBounds = true
        dimmingView.backgroundColor = UIColor.black.withAlphaComponent(Constants.dimmingColorAlpha)

        setupBackgroundTapGestureRecognizer()
        
        update(theme: ThemeService.shared().theme)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        contentView.layer.cornerRadius = Constants.cornerRadius
        
        guard lastBounds != nil else {
            lastBounds = bounds
            return
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad, lastBounds != bounds {
            lastBounds = bounds
            contentViewBottomConstraint.constant = (UIScreen.main.bounds.height + dismissContentViewBottomConstant) / 2
        }
    }
    
    // MARK: - Public
    
    func preparePresentAnimation() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            contentViewBottomConstraint.constant = (UIScreen.main.bounds.height + dismissContentViewBottomConstant) / 2
        } else {
            if centerInScreen {
                contentViewBottomConstraint.constant = (bounds.height - contentViewHeightConstraint.constant) / 2
            } else {
                contentViewBottomConstraint.constant = 0
            }
        }
    }
    
    func prepareDismissAnimation() {
        contentViewBottomConstraint.constant = dismissContentViewBottomConstant
    }
    
    func update(theme: Theme) {
        contentView.backgroundColor = theme.headerBackgroundColor
    }
    
    func updateContentViewMaxHeight(_ maxHeight: CGFloat) {
        contentViewHeightConstraint.constant = maxHeight
    }
    
    func updateContentViewLayout() {
        layoutIfNeeded()
    }
    
    func setContentView(_ contentView: UIView) {
        for subView in self.contentView.subviews {
            subView.removeFromSuperview()
        }
        self.contentView.vc_addSubViewMatchingParent(contentView)
    }
    
    func updateDimmingViewAlpha(_ alpha: CGFloat) {
        dimmingView.alpha = alpha
    }
    
    func contentViewWidthFittingSize(_ size: CGSize) -> CGFloat {
        let sizingView = SlidingModalContainerView.Sizing.view
        
        if let widthConstraint = SlidingModalContainerView.Sizing.widthConstraint {
            widthConstraint.constant = size.width
        } else {
            let widthConstraint = sizingView.widthAnchor.constraint(equalToConstant: size.width)
            widthConstraint.isActive = true
            SlidingModalContainerView.Sizing.widthConstraint = widthConstraint
        }
        
        if let heightConstraint = SlidingModalContainerView.Sizing.heightConstraint {
            heightConstraint.constant = size.height
        } else {
            let heightConstraint = sizingView.heightAnchor.constraint(equalToConstant: size.width)
            heightConstraint.isActive = true
            SlidingModalContainerView.Sizing.heightConstraint = heightConstraint
        }
        
        sizingView.setNeedsLayout()
        sizingView.layoutIfNeeded()
        
        return sizingView.contentViewFrame.width
    }
    
    // MARK: - Private
    
    private func setupBackgroundTapGestureRecognizer() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap(_:)))
        dimmingView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc private func handleBackgroundTap(_ gestureRecognizer: UITapGestureRecognizer) {
        delegate?.slidingModalContainerViewDidTapBackground(self)
    }
}
