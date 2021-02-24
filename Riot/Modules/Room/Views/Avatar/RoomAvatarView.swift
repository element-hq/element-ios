// 
// Copyright 2020 New Vector Ltd
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

final class RoomAvatarView: UIView, NibOwnerLoadable, Themable {
    
    // MARK: - Properties

    // MARK: Outlets
    
    @IBOutlet private weak var avatarImageView: MXKImageView!
    @IBOutlet private weak var cameraBadgeContainerView: UIView!
    
    // MARK: Private

    private var theme: Theme?

    private var isHighlighted: Bool = false {
        didSet {
            self.updateView()
        }
    }
    
    // MARK: Public

    var action: (() -> Void)?
    
    // MARK: Setup
    
    private func commonInit() {
        self.setupAvatarImageView()
        self.setupGestureRecognizer()
        self.vc_setupAccessibilityTraitsButton(withTitle: VectorL10n.roomAvatarViewAccessibilityLabel, hint: VectorL10n.roomAvatarViewAccessibilityHint, isEnabled: true)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.loadNibContent()
        self.commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadNibContent()
        self.commonInit()
    }
    
    // MARK: - Lifecycle
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.avatarImageView.layer.cornerRadius = self.avatarImageView.bounds.height/2
    }
    
    // MARK: - Public
    
    func fill(with viewData: RoomAvatarViewData) {
        self.updateAvatarImageView(with: viewData)

        // Fix layoutSubviews not triggered issue
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.setNeedsLayout()
        }
    }
        
    func update(theme: Theme) {
        self.theme = theme
    }
    
    // MARK: - Private
    
    private func setupGestureRecognizer() {
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(buttonAction(_:)))
        gestureRecognizer.minimumPressDuration = 0
        self.addGestureRecognizer(gestureRecognizer)
    }
    
    private func setupAvatarImageView() {
        self.avatarImageView.defaultBackgroundColor = UIColor.clear
        self.avatarImageView.enableInMemoryCache = true
        self.avatarImageView.layer.masksToBounds = true
    }
    
    private func updateAvatarImageView(with viewData: RoomAvatarViewData) {
        guard let avatarImageView = self.avatarImageView else {
            return
        }
        
        let defaultavatarImage = AvatarGenerator.generateAvatar(forMatrixItem: viewData.roomId, withDisplayName: viewData.roomDisplayName)
                
        if let avatarUrl = viewData.avatarUrl {
            avatarImageView.setImageURI(avatarUrl,
                                        withType: nil,
                                        andImageOrientation: .up,
                                        toFitViewSize: avatarImageView.frame.size,
                                        with: MXThumbnailingMethodScale,
                                        previewImage: defaultavatarImage,
                                        mediaManager: viewData.mediaManager)
        } else {
            avatarImageView.image = defaultavatarImage
        }
        
        avatarImageView.contentMode = .scaleAspectFill
                
        self.cameraBadgeContainerView.isHidden = viewData.avatarUrl != nil
    }
    
    private func updateView() {
        // TODO: Handle highlighted state
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
