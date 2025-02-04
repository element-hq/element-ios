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

/// State managed by the `ViewModel` delivered to the `View`.
struct SpaceCreationSettingsViewState: BindableState {
    let title: String
    let showRoomAddress: Bool
    var defaultAddress: String
    var roomNameError: String?
    var addressMessage: String?
    var isAddressValid: Bool
    var avatar: AvatarInputProtocol
    var avatarImage: UIImage?
    var bindings: SpaceCreationSettingsViewModelBindings
}
