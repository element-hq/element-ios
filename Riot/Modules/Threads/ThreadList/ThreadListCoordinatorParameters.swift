// File created from ScreenTemplate
// $ createScreen.sh Threads/ThreadList ThreadList
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// ThreadListCoordinator input parameters
struct ThreadListCoordinatorParameters {
    
    /// The Matrix session
    let session: MXSession
    
    /// Room identifier
    let roomId: String
}
