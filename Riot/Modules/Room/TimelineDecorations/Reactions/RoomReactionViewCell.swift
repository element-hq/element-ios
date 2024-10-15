/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit
import Reusable

final class RoomReactionViewCell: UICollectionViewCell, NibReusable, Themable {
    
    // MARK: - Constants
    
    private enum Constants {
        static let selectedBorderWidth: CGFloat = 1.0
    }
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private weak var reactionBackgroundView: UIView!
    @IBOutlet private weak var emojiLabel: UILabel!
    @IBOutlet private weak var countLabel: UILabel!
    
    // MARK: Private
    
    private var theme: Theme?
    
    // MARK: Public
    
    private var isReactionSelected: Bool = false
    
    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.reactionBackgroundView.layer.masksToBounds = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        self.reactionBackgroundView.layer.cornerRadius = self.reactionBackgroundView.frame.size.height/2.0
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        /*
         On iOS 12, there are issues with self-sizing cells as described in Apple release notes (https://developer.apple.com/documentation/ios_release_notes/ios_12_release_notes) :
         "You might encounter issues with systemLayoutSizeFitting(_:) when using a UICollectionViewCell subclass that requires updateConstraints().
         (42138227) — Workaround: Don't call the cell's setNeedsUpdateConstraints() method unless you need to support live constraint changes.
         If you need to support live constraint changes, call updateConstraintsIfNeeded() before calling systemLayoutSizeFitting(_:)."
         */
        self.updateConstraintsIfNeeded()

        return super.preferredLayoutAttributesFitting(layoutAttributes)
    }
    
    // MARK: - Public
    
    func fill(viewData: RoomReactionViewData) {
        self.emojiLabel.text = viewData.emoji
        self.countLabel.text = viewData.countString
        self.isReactionSelected = viewData.isCurrentUserReacted
        
        self.updateViews()
    }
    
    func update(theme: Theme) {
        self.theme = theme
        self.reactionBackgroundView.layer.borderColor = theme.tintColor.cgColor
        self.emojiLabel.textColor = theme.textPrimaryColor
        self.countLabel.textColor = theme.textPrimaryColor
        self.updateViews()
    }
    
    // MARK: - Private
    
    private func updateViews() {
        
        let reactionBackgroundColor: UIColor?
        let reactionBackgroundBorderWidth: CGFloat
        
        if self.isReactionSelected {
            reactionBackgroundColor = self.theme?.tintBackgroundColor
            reactionBackgroundBorderWidth = Constants.selectedBorderWidth
        } else {
            reactionBackgroundColor = self.theme?.colors.system
            reactionBackgroundBorderWidth = 0.0
        }
        
        self.reactionBackgroundView.layer.borderWidth = reactionBackgroundBorderWidth
        self.reactionBackgroundView.backgroundColor = reactionBackgroundColor
    }
}
