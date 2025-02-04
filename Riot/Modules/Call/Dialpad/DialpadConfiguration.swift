// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Dial pad configuration object, to be passed when initializing a `DialpadViewController`.
@objcMembers
class DialpadConfiguration: NSObject {
    
    /// Option for a dial pad to show the title or not.
    var showsTitle: Bool
    
    /// Option for a dial pad to show the close button or not.
    var showsCloseButton: Bool
    
    /// Option for a dial pad to show the backspace button or not.
    var showsBackspaceButton: Bool
    
    /// Option for a dial pad to show the call button or not.
    var showsCallButton: Bool
    
    /// Option for a dial pad to enable number formatting when typing or not.
    var formattingEnabled: Bool
    
    /// Option for a dial pad to enable editing on typed text or not.
    var editingEnabled: Bool
    
    /// Option for a dial pad to play tones when digits tapped or not.
    var playTones: Bool
    
    /// Default configuration object. All options are enabled by default.
    static let `default`: DialpadConfiguration = DialpadConfiguration()
    
    init(showsTitle: Bool = true,
         showsCloseButton: Bool = true,
         showsBackspaceButton: Bool = true,
         showsCallButton: Bool = true,
         formattingEnabled: Bool = true,
         editingEnabled: Bool = true,
         playTones: Bool = true) {
        self.showsTitle = showsTitle
        self.showsCloseButton = showsCloseButton
        self.showsBackspaceButton = showsBackspaceButton
        self.showsCallButton = showsCallButton
        self.formattingEnabled = formattingEnabled
        self.editingEnabled = editingEnabled
        self.playTones = playTones
        super.init()
    }
    
}
