// 
// Copyright 2022 New Vector Ltd
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
