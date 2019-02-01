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

@objc protocol KeyBackupBannerCellDelegate: class {
    func keyBackupBannerCellDidTapCloseAction(_ cell: KeyBackupBannerCell)
}

@objcMembers
final class KeyBackupBannerCell: MXKTableViewCell {
    
    // MARK: - Properties

    // MARK: Outlets

    @IBOutlet private weak var shieldImageView: UIImageView!
    @IBOutlet private weak var informationLabel: UILabel!
    @IBOutlet private weak var closeButton: UIButton!
    
    // MARK: Public
    
    weak var delegate: KeyBackupBannerCellDelegate?
    
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
        
        self.shieldImageView.tintColor = theme.textPrimaryColor
        self.closeButton.tintColor = theme.textPrimaryColor
        
        let attributedTitle = NSMutableAttributedString(string: VectorL10n.keyBackupSetupBannerTitlePart1, attributes: [.foregroundColor: theme.tintColor])
        attributedTitle.append(NSAttributedString(string: VectorL10n.keyBackupSetupBannerTitlePart2, attributes: [.foregroundColor: theme.textPrimaryColor]))
        self.informationLabel.attributedText = attributedTitle
    }
    
    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let shieldImage = Asset.Images.shield.image.withRenderingMode(.alwaysTemplate)
        self.shieldImageView.image = shieldImage
        
        let closeImage = Asset.Images.closeBanner.image.withRenderingMode(.alwaysTemplate)
        self.closeButton.setImage(closeImage, for: .normal)
    }
    
    // MARK: - Public
    
    func configure(for banner: KeyBackupBanner) {
        let attributedTitle: NSAttributedString?
        let theme = ThemeService.shared().theme
        
        switch banner {
        case .setup:
            let setupAttributedTitle = NSMutableAttributedString(string: VectorL10n.keyBackupSetupBannerTitlePart1, attributes: [.foregroundColor: theme.tintColor])
            setupAttributedTitle.append(NSAttributedString(string: VectorL10n.keyBackupSetupBannerTitlePart2, attributes: [.foregroundColor: theme.textPrimaryColor]))
            attributedTitle = setupAttributedTitle
        case .recover:
            let recoverAttributedTitle = NSMutableAttributedString(string: VectorL10n.keyBackupRecoverBannerTitlePart1, attributes: [.foregroundColor: theme.tintColor])
            recoverAttributedTitle.append(NSAttributedString(string: VectorL10n.keyBackupRecoverBannerTitlePart2, attributes: [.foregroundColor: theme.textPrimaryColor]))
            attributedTitle = recoverAttributedTitle
        case .none:
            attributedTitle = nil
        }
        
        self.informationLabel.attributedText = attributedTitle
    }
    
    // MARK: - Actions
    
    @IBAction private func closeButtonAction(_ sender: Any) {
        self.delegate?.keyBackupBannerCellDidTapCloseAction(self)
    }
}
