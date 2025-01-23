// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Classes compliant with the protocol `RoomActionProviderProtocol` are meant to provide the menu within `UIContextMenuActionProvider`
@available(iOS 13.0, *)
protocol RoomActionProviderProtocol {
    /// menu instance returned within the `UIContextMenuActionProvider` block
    var menu: UIMenu { get }
}
