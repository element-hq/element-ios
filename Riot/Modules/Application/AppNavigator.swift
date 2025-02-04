// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import CommonKit

/// AppNavigatorProtocol abstract a navigator at app level.
/// It enables to perform the navigation within the global app scope (open the side menu, open a room and so on)
/// Note: Presentation of the pattern here https://www.swiftbysundell.com/articles/navigation-in-swift/#where-to-navigator
protocol AppNavigatorProtocol {
    
    var sideMenu: SideMenuPresentable { get }
    
    /// Navigate to a destination screen or a state
    /// Do not use protocol with associatedtype for the moment like presented here https://www.swiftbysundell.com/articles/navigation-in-swift/#where-to-navigator use a separate enum
    func navigate(to destination: AppNavigatorDestination)
}
