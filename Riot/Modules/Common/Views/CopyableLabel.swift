// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

/// Enables to copy text content of the label
/// https://stackoverflow.com/a/62978837
class CopyableLabel: UILabel {

    // MARK: - Setup
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.sharedInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.sharedInit()
    }

    func sharedInit() {
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(self.showMenu)))
    }
    
    // MARK: - Public
    
    @objc func showMenu(sender: AnyObject?) {
        self.becomeFirstResponder()

        let menu = UIMenuController.shared

        if !menu.isMenuVisible {
            if #available(iOS 13.0, *) {
                menu.showMenu(from: self, rect: self.bounds)
            } 
        }
    }
    
    // MARK: - Overrides

    override func copy(_ sender: Any?) {
        let board = UIPasteboard.general

        board.string = self.text
        
        // Note that the UIMenuController will be dismissed by itself after copying the text
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return action == #selector(UIResponderStandardEditActions.copy)
    }        
}
