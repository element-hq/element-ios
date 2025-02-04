// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// CrossSigningSetupCoordinator input parameters
@objcMembers
class CrossSigningSetupCoordinatorParameters: NSObject {
    
    /// The Matrix session
    let session: MXSession
        
    /// The presenter used to show authentication screen(s).
    /// Note: Use UIViewController instead of Presentable for ObjC compatibility.
    let presenter: UIViewController
    
    /// The title to use in the authentication screen if present.
    let title: String?
    
    /// The message to use in the authentication screen if present.
    let message: String?
    
    init(session: MXSession,
         presenter: UIViewController,
         title: String?,
         message: String?) {
        self.session = session
        self.presenter = presenter
        self.title = title
        self.message = message
        
        super.init()
    }
}
