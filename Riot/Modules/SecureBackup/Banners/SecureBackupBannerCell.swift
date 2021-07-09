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
