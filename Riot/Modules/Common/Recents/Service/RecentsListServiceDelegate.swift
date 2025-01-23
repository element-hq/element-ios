// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

@objc
public protocol RecentsListServiceDelegate: AnyObject {
    
    /// Delegate method to be called when service data updated
    /// - Parameter service: service object
    /// - Parameter totalCountsChanged: true if total rooms count changed
    @objc optional func recentsListServiceDidChangeData(_ service: RecentsListServiceProtocol,
                                                        totalCountsChanged: Bool)
    
    /// Delegate method to be called when a specific section data updated. Called for each updated section before `recentsListServiceDidChangeData` if implemented.
    /// - Parameter service: service object
    /// - Parameter section: updated section
    /// - Parameter totalCountsChanged: true if total rooms count changed for the section
    @objc optional func recentsListServiceDidChangeData(_ service: RecentsListServiceProtocol,
                                                        forSection section: RecentsListServiceSection,
                                                        totalCountsChanged: Bool)
}
