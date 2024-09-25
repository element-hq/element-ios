/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit
import Reusable

final class RoomReactionImageViewCell: UICollectionViewCell, NibReusable, Themable {
    
    // MARK: - Constants

    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private weak var reactionBackgroundView: UIView!
    @IBOutlet private weak var imageView: UIImageView!
    
    // MARK: Private
    
    private var theme: Theme?
    
    // MARK: Public
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.reactionBackgroundView.layer.masksToBounds = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        self.reactionBackgroundView.layer.cornerRadius = self.reactionBackgroundView.bounds.midY
    }

    // MARK: - Life cycle
    
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
    
    func fill(actionIcon: UIImage) {
        imageView.image = actionIcon.withRenderingMode(.alwaysTemplate)
        self.updateViews()
    }
    
    func update(theme: Theme) {
        self.theme = theme
        self.updateViews()
    }
    
    // MARK: - Private
    
    private func updateViews() {
        self.imageView.tintColor = self.theme?.textSecondaryColor
        
        self.reactionBackgroundView.layer.borderWidth = 0.0
        self.reactionBackgroundView.backgroundColor = self.theme?.colors.system
    }
}
