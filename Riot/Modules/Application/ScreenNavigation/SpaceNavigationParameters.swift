// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Navigation parameters to display a space with a provided identifier in a specific matrix session.
@objcMembers
class SpaceNavigationParameters: NSObject {
    
    // MARK: - Properties

    /// The room identifier
    let roomId: String
    
    /// The Matrix session in which the room should be available.
    let mxSession: MXSession
    
    /// Screen presentation parameters.
    let presentationParameters: ScreenPresentationParameters
    
    // MARK: - Setup
    
    init(roomId: String,
         mxSession: MXSession,
         presentationParameters: ScreenPresentationParameters) {
        self.roomId = roomId
        self.mxSession = mxSession
        self.presentationParameters = presentationParameters
        
        super.init()
    }
}
