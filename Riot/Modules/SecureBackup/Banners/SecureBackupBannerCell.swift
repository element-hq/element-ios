/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit

@objc protocol SecureBackupBannerCellDelegate: AnyObject {
    func secureBackupBannerCellDidTapCloseAction(_ cell: SecureBackupBannerCell)
}

@objcMembers
final class SecureBackupBannerCell: MXKTableViewCell, Themable {
    
    // MARK: - Properties

    // MARK: Outlets

    @IBOutlet private weak var shieldImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var closeButton: UIButton!
    
    // MARK: Public
    
    weak var delegate: SecureBackupBannerCellDelegate?
    
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
        
        let shieldImage = Asset.Images.secretsSetupKey.image.withRenderingMode(.alwaysTemplate)
        self.shieldImageView.image = shieldImage 
        
        let closeImage = Asset.Images.closeBanner.image.withRenderingMode(.alwaysTemplate)
        self.closeButton.setImage(closeImage, for: .normal)
    }
    
    // MARK: - Public
    
    func configure(for bannerDisplay: SecureBackupBannerDisplay) {
        
        let title: String?
        let subtitle: String?
        
        switch bannerDisplay {
        case .setup:
            title = VectorL10n.secureBackupSetupBannerTitle
            subtitle = VectorL10n.secureBackupSetupBannerSubtitle
        default:
            title = nil
            subtitle = nil
        }
        
        self.titleLabel.text = title
        self.subtitleLabel.text = subtitle
    }
    
    func update(theme: Theme) {
        self.shieldImageView.tintColor = theme.textPrimaryColor
        self.closeButton.tintColor = theme.textPrimaryColor
        
        self.titleLabel.textColor = theme.textPrimaryColor
        self.subtitleLabel.textColor = theme.textPrimaryColor
    }
    
    // MARK: - Actions
    
    @IBAction private func closeButtonAction(_ sender: Any) {
        self.delegate?.secureBackupBannerCellDidTapCloseAction(self)
    }
}
