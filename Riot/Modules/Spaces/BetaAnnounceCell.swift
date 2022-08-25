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

import Reusable
import UIKit

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
        
    @IBOutlet private var cardBackgroundView: UIView!
    @IBOutlet private var closeButton: CloseButton!
    @IBOutlet private var badgeView: UIView!
    @IBOutlet private var badgeLabel: UILabel!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!
    @IBOutlet private var informationLabel: UILabel!
    
    @objc weak var delegate: BetaAnnounceCellDelegate?
    
    // MARK: - Life cycle
        
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        badgeLabel.text = VectorL10n.spaceBetaAnnounceBadge
        titleLabel.text = VectorL10n.spaceBetaAnnounceTitle
        subtitleLabel.text = VectorL10n.spaceBetaAnnounceSubtitle
        informationLabel.text = VectorL10n.spaceBetaAnnounceInformation
                
        badgeView.layer.masksToBounds = true
        cardBackgroundView.layer.masksToBounds = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        cardBackgroundView.layer.cornerRadius = Constants.cardBackgroundViewCornersRadius
        badgeView.layer.cornerRadius = badgeView.frame.height / 2
    }
        
    // MARK: - Public
    
    func update(theme: Theme) {
        closeButton.update(theme: theme)
        titleLabel.textColor = theme.textPrimaryColor
        subtitleLabel.textColor = theme.textPrimaryColor
        informationLabel.textColor = theme.textSecondaryColor
        cardBackgroundView.backgroundColor = theme.baseColor
        contentView.backgroundColor = theme.backgroundColor
    }
    
    // MARK: - Actions
    
    @IBAction private func closeButtonAction(_ sender: Any) {
        delegate?.betaAnnounceCellDidTapCloseButton(self)
    }
}

// Copy paste from NibReusable in order to expose these methods to ObjC
extension BetaAnnounceCell {
    @objc static var reuseIdentifier: String {
        String(describing: self)
    }
    
    @objc static var nib: UINib {
        UINib(nibName: String(describing: self), bundle: Bundle(for: self))
    }
}
