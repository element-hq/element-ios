//
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import Reusable

/// `RootTabEmptyViewDisplayMode` defines the way image and text should be displayed
enum RootTabEmptyViewDisplayMode {
    /// Default display: fitted for big images
    case `default`
    /// The image is shrinked to fit icon size and is rendered as templated.
    case icon
}

/// `RootTabEmptyView` is a view to display when there is no UI item to display on a screen.
@objcMembers
final class RootTabEmptyView: UIView, NibLoadable {
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var iconBackgroundView: UIView!
    @IBOutlet private weak var iconView: UIImageView!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var informationLabel: UILabel!
    @IBOutlet private(set) weak var contentView: UIView!

    // MARK: Private
    
    private var theme: Theme!
    
    // MARK: Public
    
    // MARK: - Setup
    
    class func instantiate() -> RootTabEmptyView {
        let view = RootTabEmptyView.loadFromNib()
        view.theme = ThemeService.shared().theme
        return view
    }
    
    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.informationLabel.text = VectorL10n.homeEmptyViewInformation
        
        self.iconBackgroundView.layer.masksToBounds = true
        self.iconBackgroundView.layer.cornerRadius = self.iconBackgroundView.bounds.width / 2
        self.iconBackgroundView.isHidden = true
    }
    
    // MARK: - Public
    
    func fill(with image: UIImage, title: String, informationText: String) {
        fill(with: image, title: title, informationText: informationText, displayMode: .default)
    }
    
    func fill(with image: UIImage, title: String, informationText: String, displayMode: RootTabEmptyViewDisplayMode) {
        self.imageView.image = image
        self.iconView.image = image.withRenderingMode(.alwaysTemplate)
        self.titleLabel.text = title
        self.informationLabel.text = informationText
        self.imageView.isHidden = displayMode != .default
        self.iconBackgroundView.isHidden = displayMode != .icon
    }
}

// MARK: - Themable
extension RootTabEmptyView: Themable {
    
    func update(theme: Theme) {
        self.theme = theme
        
        self.backgroundColor = theme.backgroundColor
        
        self.titleLabel.textColor = theme.textPrimaryColor
        self.informationLabel.textColor = theme.textSecondaryColor
        self.iconBackgroundView.backgroundColor = theme.colors.quinaryContent
        self.iconView.tintColor = theme.textSecondaryColor
    }
}
