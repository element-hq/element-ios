// File created from ScreenTemplate
// $ createScreen.sh Rooms/ShowDirectory ShowDirectory
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// ShowDirectoryViewController view actions exposed to view model
enum ShowDirectoryViewAction {
    case loadData(_ force: Bool)
    case selectRoom(_ indexPath: IndexPath)
    case joinRoom(_ indexPath: IndexPath)
    case search(_ pattern: String?)
    case createNewRoom
    case switchServer
    case cancel
}
