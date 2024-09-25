/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit

@objc protocol CrossSigningSetupBannerCellDelegate: AnyObject {
    func crossSigningSetupBannerCellDidTapCloseAction(_ cell: CrossSigningSetupBannerCell)
}

@objcMembers
final class CrossSigningSetupBannerCell: MXKTableViewCell, Themable {
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var shieldImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var closeButton: UIButton!
    
    // MARK: Public
    
    weak var delegate: CrossSigningSetupBannerCellDelegate?
    
    // MARK: - Overrides
    
    override class func defaultReuseIdentifier() -> String {
        return String(describing: self)
    }
    
    override class func nib() -> UINib {
        return UINib(nibName: String(describing: self), bundle: nil)
    }
    
    override func customizeRendering() {
        super.customizeRendering()
        
        let theme = ThemeService.shared().theme
        self.update(theme: theme)
    }
    
    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // TODO: Image size is too small, use an higher resolution one.
        let shieldImage = Asset.Images.encryptionNormal.image.withRenderingMode(.alwaysTemplate)
        self.shieldImageView.image = shieldImage
        
        let closeImage = Asset.Images.closeBanner.image.withRenderingMode(.alwaysTemplate)
        self.closeButton.setImage(closeImage, for: .normal)
        
        self.titleLabel.text = VectorL10n.crossSigningSetupBannerTitle
        self.subtitleLabel.text = VectorL10n.crossSigningSetupBannerSubtitle
    }
    
    // MARK: - Public
    
    func update(theme: Theme) {
        self.shieldImageView.tintColor = theme.textPrimaryColor
        self.closeButton.tintColor = theme.textPrimaryColor
        
        self.titleLabel.textColor = theme.textPrimaryColor
        self.subtitleLabel.textColor = theme.textPrimaryColor
    }
    
    // MARK: - Actions
    
    @IBAction private func closeButtonAction(_ sender: Any) {
        self.delegate?.crossSigningSetupBannerCellDidTapCloseAction(self)
    }
}
