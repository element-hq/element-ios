/*
Copyright 2024 New Vector Ltd.
Copyright 2020 The Matrix.org Foundation C.I.C

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation
import UIKit

@objcMembers
public class MXKPasteboardManager: NSObject {
    
    public static let shared = MXKPasteboardManager(withPasteboard: .general)
    
    private init(withPasteboard pasteboard: UIPasteboard) {
        self.pasteboard = pasteboard
        super.init()
    }
    
    /// Pasteboard to use on copy operations. Defaults to `UIPasteboard.generalPasteboard`.
    public var pasteboard: UIPasteboard
    
}
