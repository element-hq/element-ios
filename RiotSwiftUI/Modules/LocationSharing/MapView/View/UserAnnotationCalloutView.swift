//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Mapbox

class UserAnnotationCalloutView: UIView, MGLCalloutView, Themable {
    // MARK: - Constants
    
    private enum Constants {
        static let animationDuration: TimeInterval = 0.2
        static let bottomMargin: CGFloat = 3.0
    }
 
    // MARK: - Properties
    
    // MARK: Overrides
    
    var representedObject: MGLAnnotation
    
    lazy var leftAccessoryView = UIView()
    
    lazy var rightAccessoryView = UIView()
    
    var delegate: MGLCalloutViewDelegate?
    
    // Allow the callout to remain open during panning.
    let dismissesAutomatically = false
    
    let isAnchoredToAnnotation = true
    
    // https://github.com/mapbox/mapbox-gl-native/issues/9228
    override var center: CGPoint {
        set {
            var newCenter = newValue
            newCenter.y -= bounds.midY + Constants.bottomMargin
            super.center = newCenter
        }
        get {
            super.center
        }
    }
    
    // MARK: Private
    
    lazy var contentView = UserAnnotationCalloutContentView.instantiate()
    
    // MARK: - Setup
    
    required init(userLocationAnnotation: UserLocationAnnotation) {
        representedObject = userLocationAnnotation
        
        super.init(frame: .zero)
                        
        vc_addSubViewMatchingParent(contentView)
        
        update(theme: ThemeService.shared().theme)
        
        let size = UserAnnotationCalloutContentView.contentViewSize()

        frame = CGRect(origin: .zero, size: size)
    }
    
    @available(*, unavailable)
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public
    
    func update(theme: Theme) {
        contentView.update(theme: theme)
    }
    
    // MARK: - Overrides

    func presentCallout(from rect: CGRect, in view: UIView, constrainedTo constrainedRect: CGRect, animated: Bool) {
        // Set callout above the marker view
        
        center = view.center.applying(CGAffineTransform(translationX: 0, y: view.bounds.height / 2 + bounds.height))
        
        delegate?.calloutViewWillAppear?(self)
        
        view.addSubview(self)
        
        if isCalloutTappable() {
            // Handle taps and eventually try to send them to the delegate (usually the map view).
            contentView.shareButton.addTarget(self, action: #selector(UserAnnotationCalloutView.calloutTapped), for: .touchUpInside)
        } else {
            // Disable tapping and highlighting.
            contentView.shareButton.isUserInteractionEnabled = false
        }
        
        if animated {
            alpha = 0
            
            UIView.animate(withDuration: Constants.animationDuration) { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                
                strongSelf.alpha = 1
                strongSelf.delegate?.calloutViewDidAppear?(strongSelf)
            }
        } else {
            delegate?.calloutViewDidAppear?(self)
        }
    }
    
    func dismissCallout(animated: Bool) {
        if superview != nil {
            if animated {
                UIView.animate(withDuration: Constants.animationDuration, animations: { [weak self] in
                    self?.alpha = 0
                }, completion: { [weak self] _ in
                    self?.removeFromSuperview()
                })
            } else {
                removeFromSuperview()
            }
        }
    }

    // MARK: - Callout interaction handlers

    func isCalloutTappable() -> Bool {
        if let delegate = delegate {
            if delegate.responds(to: #selector(MGLCalloutViewDelegate.calloutViewShouldHighlight)) {
                return delegate.calloutViewShouldHighlight!(self)
            }
        }
        return false
    }

    @objc func calloutTapped() {
        if isCalloutTappable(), delegate!.responds(to: #selector(MGLCalloutViewDelegate.calloutViewTapped)) {
            delegate!.calloutViewTapped!(self)
        }
    }
}
