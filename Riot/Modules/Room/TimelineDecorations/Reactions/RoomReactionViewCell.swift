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

import Reusable
import UIKit

final class RoomReactionViewCell: UICollectionViewCell, NibReusable, Themable {
    // MARK: - Constants
    
    private enum Constants {
        static let selectedBorderWidth: CGFloat = 1.0
    }
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private var reactionBackgroundView: UIView!
    @IBOutlet private var emojiLabel: UILabel!
    @IBOutlet private var countLabel: UILabel!
    
    // MARK: Private
    
    private var theme: Theme?
    
    // MARK: Public
    
    private var isReactionSelected = false
    
    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        reactionBackgroundView.layer.masksToBounds = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        reactionBackgroundView.layer.cornerRadius = reactionBackgroundView.frame.size.height / 2.0
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        /*
         On iOS 12, there are issues with self-sizing cells as described in Apple release notes (https://developer.apple.com/documentation/ios_release_notes/ios_12_release_notes) :
         "You might encounter issues with systemLayoutSizeFitting(_:) when using a UICollectionViewCell subclass that requires updateConstraints().
         (42138227) — Workaround: Don't call the cell's setNeedsUpdateConstraints() method unless you need to support live constraint changes.
         If you need to support live constraint changes, call updateConstraintsIfNeeded() before calling systemLayoutSizeFitting(_:)."
         */
        updateConstraintsIfNeeded()

        return super.preferredLayoutAttributesFitting(layoutAttributes)
    }
    
    // MARK: - Public
    
    func fill(viewData: RoomReactionViewData) {
        emojiLabel.text = viewData.emoji
        countLabel.text = viewData.countString
        isReactionSelected = viewData.isCurrentUserReacted
        
        updateViews()
    }
    
    func update(theme: Theme) {
        self.theme = theme
        reactionBackgroundView.layer.borderColor = theme.tintColor.cgColor
        emojiLabel.textColor = theme.textPrimaryColor
        countLabel.textColor = theme.textPrimaryColor
        updateViews()
    }
    
    // MARK: - Private
    
    private func updateViews() {
        let reactionBackgroundColor: UIColor?
        let reactionBackgroundBorderWidth: CGFloat
        
        if isReactionSelected {
            reactionBackgroundColor = theme?.tintBackgroundColor
            reactionBackgroundBorderWidth = Constants.selectedBorderWidth
        } else {
            reactionBackgroundColor = theme?.headerBackgroundColor
            reactionBackgroundBorderWidth = 0.0
        }
        
        reactionBackgroundView.layer.borderWidth = reactionBackgroundBorderWidth
        reactionBackgroundView.backgroundColor = reactionBackgroundColor
    }
}
