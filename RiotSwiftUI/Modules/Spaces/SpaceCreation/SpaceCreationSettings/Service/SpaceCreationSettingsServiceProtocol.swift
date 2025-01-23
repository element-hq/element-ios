// File created from TemplateAdvancedRoomsExample
// $ createSwiftUITwoScreen.sh Spaces/SpaceCreation SpaceCreation SpaceCreationMenu SpaceCreationSettings
//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

protocol SpaceCreationSettingsServiceProtocol: AnyObject {
    var defaultAddressSubject: CurrentValueSubject<String, Never> { get }
    var addressValidationSubject: CurrentValueSubject<SpaceCreationSettingsAddressValidationStatus, Never> { get }
    var avatarViewDataSubject: CurrentValueSubject<AvatarInputProtocol, Never> { get }
    var roomName: String { get set }
    var userDefinedAddress: String? { get set }
    var isAddressValid: Bool { get }
}
