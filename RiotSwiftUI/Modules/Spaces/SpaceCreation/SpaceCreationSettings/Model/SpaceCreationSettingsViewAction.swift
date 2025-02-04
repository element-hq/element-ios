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

/// Actions send from the `View` to the `ViewModel`.
enum SpaceCreationSettingsViewAction {
    case cancel
    case back
    case done
    case pickImage(_ sourceRect: CGRect)
    case nameChanged(_ newValue: String)
    case addressChanged(_ newValue: String)
    case topicChanged(_ newValue: String)
}
