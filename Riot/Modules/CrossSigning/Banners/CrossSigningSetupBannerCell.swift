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
    
    @IBOutlet private var shieldImageView: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!
    @IBOutlet private var closeButton: UIButton!
    
    // MARK: Public
    
    weak var delegate: CrossSigningSetupBannerCellDelegate?
    
    // MARK: - Overrides
    
    override class func defaultReuseIdentifier() -> String {
        String(describing: self)
    }
    
    override class func nib() -> UINib {
        UINib(nibName: String(describing: self), bundle: nil)
    }
    
    override func customizeRendering() {
        super.customizeRendering()
        
        let theme = ThemeService.shared().theme
        update(theme: theme)
    }
    
    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // TODO: Image size is too small, use an higher resolution one.
        let shieldImage = Asset.Images.encryptionNormal.image.withRenderingMode(.alwaysTemplate)
        shieldImageView.image = shieldImage
        
        let closeImage = Asset.Images.closeBanner.image.withRenderingMode(.alwaysTemplate)
        closeButton.setImage(closeImage, for: .normal)
        
        titleLabel.text = VectorL10n.crossSigningSetupBannerTitle
        subtitleLabel.text = VectorL10n.crossSigningSetupBannerSubtitle
    }
    
    // MARK: - Public
    
    func update(theme: Theme) {
        shieldImageView.tintColor = theme.textPrimaryColor
        closeButton.tintColor = theme.textPrimaryColor
        
        titleLabel.textColor = theme.textPrimaryColor
        subtitleLabel.textColor = theme.textPrimaryColor
    }
    
    // MARK: - Actions
    
    @IBAction private func closeButtonAction(_ sender: Any) {
        delegate?.crossSigningSetupBannerCellDidTapCloseAction(self)
    }
}
