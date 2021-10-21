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

/// A subclass of `UITableViewHeaderFooterView` that conforms to `Themable`
/// to create a consistent looking custom footer inside of the app. If using gesture
/// recognizers on the view, be aware that these will be automatically removed on reuse.
@objcMembers
class SectionFooterView: UITableViewHeaderFooterView, NibLoadable, Themable {
    
    // MARK: - Properties
    
    static var defaultReuseIdentifier: String {
        String(describing: Self.self)
    }
    
    static var nib: UINib {
        // Copy paste from NibReusable in order to expose to ObjC
        UINib(nibName: String(describing: self), bundle: Bundle(for: self))
    }
    
    /// The amount to inset the footer label on its leading side, relative to the safe area insets.
    var leadingInset: CGFloat {
        get { footerLabelLeadingConstraint.constant }
        set { footerLabelLeadingConstraint.constant = newValue }
    }
    
    /// The text label added in the xib file. Using our own label was necessary due to the behaviour
    /// on iOS 12-14 where any customisation to the existing text label is wiped out after being
    /// set in `tableView:viewForFooterInSection`. This behaviour is fixed in iOS 15.
    @IBOutlet private weak var footerLabel: UILabel!
    /// The label's leading constraint, relative to the safe area insets.
    @IBOutlet private weak var footerLabelLeadingConstraint: NSLayoutConstraint!
    
    // MARK: - Public
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        for recognizer in gestureRecognizers ?? [] {
            removeGestureRecognizer(recognizer)
        }
    }
    
    func update(theme: Theme) {
        footerLabel.textColor = theme.colors.secondaryContent
        footerLabel.font = theme.fonts.subheadline
        footerLabel.numberOfLines = 0
    }
    
    /// Update the footer with new text.
    func update(withText text: String) {
        footerLabel.text = text
    }
    
    /// Update the footer with attributed text. Be sure to call this after calling `update(theme:)`
    /// otherwise any color or font attributes will be wiped out by the theme.
    func update(withAttributedText attributedText: NSAttributedString) {
        footerLabel.attributedText = attributedText
    }
}
