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

final class EmojiPickerViewCell: UICollectionViewCell, NibReusable, Themable {

    // MARK: - Constants
    
    private enum Constants {
        static let selectedBorderWidth: CGFloat = 1.0
        static let selectedBackgroundRadius: CGFloat = 5.0
        static let emojiHighlightedAlpha: CGFloat = 0.3
    }
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var reactionBackgroundView: UIView!
    @IBOutlet private weak var emojiLabel: UILabel!
    
    // MARK: Private
    
    private var theme: Theme?
    
    // MARK: Public
    
    private var isReactionSelected: Bool = false
    
    override var isHighlighted: Bool {
        didSet {
            self.emojiLabel.alpha = isHighlighted ? Constants.emojiHighlightedAlpha : 1.0
        }
    }
    
    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.reactionBackgroundView.layer.masksToBounds = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.reactionBackgroundView.layer.cornerRadius = self.reactionBackgroundView.frame.width/4.0
    }
    
    // MARK: - Public
    
    func fill(viewData: EmojiPickerItemViewData) {
        self.emojiLabel.text = viewData.emoji
        self.isReactionSelected = viewData.isSelected
        
        self.updateViews()
    }
    
    func update(theme: Theme) {
        self.theme = theme
        self.reactionBackgroundView.layer.borderColor = theme.tintColor.cgColor
        self.emojiLabel.textColor = theme.textPrimaryColor
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
            reactionBackgroundColor = self.theme?.backgroundColor
            reactionBackgroundBorderWidth = 0.0
        }
        
        self.reactionBackgroundView.layer.borderWidth = reactionBackgroundBorderWidth
        self.reactionBackgroundView.backgroundColor = reactionBackgroundColor
    }

}
