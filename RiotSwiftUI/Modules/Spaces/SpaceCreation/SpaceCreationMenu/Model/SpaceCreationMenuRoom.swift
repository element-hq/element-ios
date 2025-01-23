// File created from TemplateAdvancedRoomsExample
// $ createSwiftUITwoScreen.sh Spaces/SpaceCreation SpaceCreation SpaceCreationMenu SpaceCreationSettings
//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import UIKit

/// list of IDs for the items displayed in the different menu views
enum SpaceCreationMenuRoomOptionId {
    /// Public space option
    case publicSpace
    /// Private space option
    case privateSpace
    /// Private space for internal use option
    case ownedPrivateSpace
    /// Private space shared with members option
    case sharedPrivateSpace
}

struct SpaceCreationMenuRoomOption {
    let id: SpaceCreationMenuRoomOptionId
    let icon: UIImage
    let title: String
    let detail: String
}

extension SpaceCreationMenuRoomOption: Identifiable, Equatable { }
