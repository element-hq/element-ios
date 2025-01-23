// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
