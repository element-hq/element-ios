// File created from ScreenTemplate
// $ createScreen.sh Rooms/ShowDirectory ShowDirectory
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// ShowDirectoryViewController view state
enum ShowDirectoryViewState {
    case loading
    case loaded(_ sections: [ShowDirectorySection])
    case error(Error)
}
