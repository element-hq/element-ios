// File created from TemplateAdvancedRoomsExample
// $ createSwiftUITwoScreen.sh Spaces/SpaceCreation SpaceCreation SpaceCreationMenu SpaceCreationSettings
//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// State managed by the `ViewModel` delivered to the `View`.
struct SpaceCreationMenuViewState: BindableState {
    var navTitle: String
    var title: String
    var detail: String
    var options: [SpaceCreationMenuRoomOption]
}
