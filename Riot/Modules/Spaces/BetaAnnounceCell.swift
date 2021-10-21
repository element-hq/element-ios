// 
// Copyright 2021 New Vector Ltd
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

@objc protocol BetaAnnounceCellDelegate: AnyObject {
    func betaAnnounceCellDidTapCloseButton(_ cell: BetaAnnounceCell)
}

/// BetaAnnounceCell enables to show coming beta feature
final class BetaAnnounceCell: UITableViewCell, Themable {
    
    // MARK: - Constants
    
    private enum Constants {
        static let cardBackgroundViewCornersRadius: CGFloat = 8.0
    }
    
    // MARK: - Properties
        
    @IBOutlet private weak var cardBackgroundView: UIView!
    @IBOutlet private weak var closeButton: CloseButton!
    @IBOutlet private weak var badgeView: UIView!
    @IBOutlet private weak var badgeLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var informationLabel: UILabel!
    
    @objc weak var delegate: BetaAnnounceCellDelegate?
    
    // MARK: - Life cycle
        
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.badgeLabel.text = VectorL10n.spaceBetaAnnounceBadge
        self.titleLabel.text = VectorL10n.spaceBetaAnnounceTitle
        self.subtitleLabel.text = VectorL10n.spaceBetaAnnounceSubtitle
        self.informationLabel.text = VectorL10n.spaceBetaAnnounceInformation
                
        self.badgeView.layer.masksToBounds = true
        self.cardBackgroundView.layer.masksToBounds = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.cardBackgroundView.layer.cornerRadius = Constants.cardBackgroundViewCornersRadius
        self.badgeView.layer.cornerRadius = self.badgeView.frame.height/2
    }
        
    // MARK: - Public
    
    func update(theme: Theme) {
        self.closeButton.update(theme: theme)
        self.titleLabel.textColor = theme.textPrimaryColor
        self.subtitleLabel.textColor = theme.textPrimaryColor
        self.informationLabel.textColor = theme.textSecondaryColor
        self.cardBackgroundView.backgroundColor = theme.baseColor
        self.contentView.backgroundColor = theme.backgroundColor
    }
    
    // MARK: - Actions
    
    @IBAction private func closeButtonAction(_ sender: Any) {
        self.delegate?.betaAnnounceCellDidTapCloseButton(self)
    }
}

// Copy paste from NibReusable in order to expose these methods to ObjC
extension BetaAnnounceCell {
    @objc static var reuseIdentifier: String {
      return String(describing: self)
    }
    
    @objc static var nib: UINib {
      return UINib(nibName: String(describing: self), bundle: Bundle(for: self))
    }
}
