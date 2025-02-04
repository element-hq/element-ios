// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import UIKit
import GBDeviceInfo

extension RoomInputToolbarView {
    open override func sendCurrentMessage() {
        // Triggers auto-correct if needed.
        if self.isFirstResponder {
            let temp = UITextField(frame: .zero)
            temp.isHidden = true
            self.addSubview(temp)
            temp.becomeFirstResponder()
            self.becomeFirstResponder()
            temp.removeFromSuperview()
        }
        
        // Send message if any.
        if let messageToSend = self.attributedTextMessage, messageToSend.length > 0 {
            self.delegate.roomInputToolbarView(self, sendAttributedTextMessage: messageToSend)
        }
        
        // Reset message, disable view animation during the update to prevent placeholder distorsion.
        UIView.setAnimationsEnabled(false)
        self.attributedTextMessage = nil
        UIView.setAnimationsEnabled(true)
    }
}

@objc extension RoomInputToolbarView {
    func updatePlaceholder() {
        updatePlaceholderText()
    }
}

extension RoomInputToolbarViewProtocol where Self: MXKRoomInputToolbarView {
    func updatePlaceholderText() {
        // Consider the default placeholder
        
        let placeholder: String
        
        // Check the device screen size before using large placeholder
        let shouldDisplayLargePlaceholder = GBDeviceInfo.deviceInfo().family == .familyiPad || GBDeviceInfo.deviceInfo().displayInfo.display.rawValue >= GBDeviceDisplay.display5p8Inch.rawValue
        
        if !shouldDisplayLargePlaceholder {
            switch sendMode {
            case .reply:
                placeholder = VectorL10n.roomMessageReplyToShortPlaceholder
            case .createDM:
                placeholder = VectorL10n.roomFirstMessagePlaceholder
                
            default:
                placeholder = VectorL10n.roomMessageShortPlaceholder
            }
        } else {
            if isEncryptionEnabled {
                switch sendMode {
                case .reply:
                    placeholder = VectorL10n.encryptedRoomMessageReplyToPlaceholder
                    
                default:
                    placeholder = VectorL10n.encryptedRoomMessagePlaceholder
                }
            } else {
                switch sendMode {
                case .reply:
                    placeholder = VectorL10n.roomMessageReplyToPlaceholder
                    
                case .createDM:
                    placeholder = VectorL10n.roomFirstMessagePlaceholder
                default:
                    placeholder = VectorL10n.roomMessagePlaceholder
                }
            }
        }
        
        self.placeholder = placeholder
    }
}
