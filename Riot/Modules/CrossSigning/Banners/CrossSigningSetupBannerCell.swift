/*
 Copyright 2020 New Vector Ltd
 
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
