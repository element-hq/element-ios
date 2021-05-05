// 
// Copyright 2020 New Vector Ltd
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
