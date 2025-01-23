//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

/// Base class to support an avatar view
/// Note: This class is made to be sublcassed
class AvatarView: UIView, Themable {
    
    // MARK: - Properties

    // MARK: Outlets
    
    @IBOutlet weak var avatarImageView: MXKImageView! {
        didSet {
            self.setupAvatarImageView()
        }
    }
    
    // MARK: Private

    private(set) var theme: Theme?
    
    // MARK: Public
    
    override var isUserInteractionEnabled: Bool {
        get {
            return super.isUserInteractionEnabled
        }
        set {
            super.isUserInteractionEnabled = newValue
            self.updateAccessibilityTraits()
        }
    }
    
    /// Indicate highlighted state
    var isHighlighted: Bool = false {
        didSet {
            self.updateView()
        }
    }

    var action: (() -> Void)?
    
    // MARK: - Setup
    
    private func commonInit() {
        self.setupGestureRecognizer()
        self.updateAccessibilityTraits()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    // MARK: - Lifecycle
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.avatarImageView.layer.cornerRadius = self.avatarImageView.bounds.height/2
    }
    
    // MARK: - Public
    
    func fill(with viewData: AvatarViewDataProtocol) {
        self.updateAvatarImageView(with: viewData)
        self.setNeedsLayout()
    }
        
    func update(theme: Theme) {
        self.theme = theme
    }
    
    func updateAccessibilityTraits() {
        // Override in subclass
    }
    
    func setupAvatarImageView() {
        self.avatarImageView.defaultBackgroundColor = UIColor.clear
        self.avatarImageView.enableInMemoryCache = true
        self.avatarImageView.layer.masksToBounds = true
    }
    
    func updateAvatarImageView(with viewData: AvatarViewDataProtocol) {
        guard let avatarImageView = self.avatarImageView else {
            MXLog.warning("[AvatarView] avatar not updated because avatarImageView is nil.")
            return
        }
        
        let (defaultAvatarImage, defaultAvatarImageContentMode) = viewData.fallbackImageParameters() ?? (nil, .scaleAspectFill)
        updateAvatarImageView(image: defaultAvatarImage, contentMode: defaultAvatarImageContentMode)
        
        if defaultAvatarImage == nil {
            MXLog.warning("[AvatarView] defaultAvatarImage is nil")
        }

        if let avatarUrl = viewData.avatarUrl {
            avatarImageView.setImageURI(avatarUrl,
                                        withType: nil,
                                        andImageOrientation: .up,
                                        toFitViewSize: avatarImageView.frame.size,
                                        with: MXThumbnailingMethodScale,
                                        previewImage: defaultAvatarImage,
                                        mediaManager: viewData.mediaManager)
            updateAvatarContentMode(contentMode: .scaleAspectFill)
            
            if avatarImageView.frame.size.width < 8 || avatarImageView.frame.size.height < 8 {
                MXLog.warning("[AvatarView] small avatarImageView frame: \(avatarImageView.frame)")
            }
        } else {
            updateAvatarImageView(image: defaultAvatarImage, contentMode: defaultAvatarImageContentMode)
        }
    }
    
    func updateView() {
        // Override in subclass if needed
        // TODO: Handle highlighted state
    }
    
    // MARK: - Private
    
    private func setupGestureRecognizer() {
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(buttonAction(_:)))
        gestureRecognizer.minimumPressDuration = 0
        self.addGestureRecognizer(gestureRecognizer)
    }
    
    private func updateAvatarImageView(image: UIImage?, contentMode: UIView.ContentMode) {
        avatarImageView?.image = image
        updateAvatarContentMode(contentMode: contentMode)
    }
    
    private func updateAvatarContentMode(contentMode: UIView.ContentMode) {
        avatarImageView?.contentMode = contentMode
        avatarImageView?.imageView?.contentMode = contentMode
    }
        
    // MARK: - Actions

    @objc private func buttonAction(_ sender: UILongPressGestureRecognizer) {

        let isBackgroundViewTouched = sender.vc_isTouchingInside()

        switch sender.state {
        case .began, .changed:
            self.isHighlighted = isBackgroundViewTouched
        case .ended:
            self.isHighlighted = false

            if isBackgroundViewTouched {
                self.action?()
            }
        case .cancelled:
            self.isHighlighted = false
        default:
            break
        }
    }
}
