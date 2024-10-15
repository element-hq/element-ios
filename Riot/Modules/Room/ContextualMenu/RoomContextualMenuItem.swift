/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

@objcMembers
final class RoomContextualMenuItem: NSObject {
    
    // MARK: - Properties
    
    let title: String
    let image: UIImage?
    
    var isEnabled: Bool = true
    var action: (() -> Void)?
    
    // MARK: - Setup
    
    init(menuAction: RoomContextualMenuAction) {
        self.title = menuAction.title
        self.image = menuAction.image
        super.init()
    }
}
