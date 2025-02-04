// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit
import Reusable

final class TextMessageBubbleCellContentView: UIView, NibLoadable {
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private(set) weak var bubbleBackgroundView: RoomMessageBubbleBackgroundView!
    
    @IBOutlet weak var bubbleBackgroundViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var bubbleBackgroundViewTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet private(set) weak var textView: UITextView!
    
    // MARK: - Setup
    
    static func instantiate() -> TextMessageBubbleCellContentView {
        return TextMessageBubbleCellContentView.loadFromNib()
    }
}
