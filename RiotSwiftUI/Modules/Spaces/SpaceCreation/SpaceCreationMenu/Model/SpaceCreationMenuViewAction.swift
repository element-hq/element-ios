// File created from TemplateAdvancedRoomsExample
// $ createSwiftUITwoScreen.sh Spaces/SpaceCreation SpaceCreation SpaceCreationMenu SpaceCreationSettings
//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

/// Actions send from the `View` to the `ViewModel`.
enum SpaceCreationMenuViewAction {
    case back
    case cancel
    case didSelectOption(_ optionId: SpaceCreationMenuRoomOptionId)
}
