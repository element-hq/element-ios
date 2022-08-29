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
