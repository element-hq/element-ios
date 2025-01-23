//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum SpaceCreationSettingsAddressValidationStatus {
    case none(_ address: String)
    case current(_ address: String)
    case valid(_ address: String)
    case alreadyExists(_ address: String)
    case invalidCharacters(_ address: String)
    
    var message: String {
        switch self {
        case .none(let fullAddress):
            return VectorL10n.spacesCreationAddressDefaultMessage(fullAddress)
        case .current(let fullAddress):
            return VectorL10n.spaceSettingsCurrentAddressMessage(fullAddress)
        case .valid(let fullAddress):
            return VectorL10n.spacesCreationAddressDefaultMessage(fullAddress)
        case .alreadyExists(let fullAddress):
            return VectorL10n.spacesCreationAddressAlreadyExists(fullAddress)
        case .invalidCharacters(let fullAddress):
            return VectorL10n.spacesCreationAddressInvalidCharacters(fullAddress)
        }
    }
    
    var isValid: Bool {
        switch self {
        case .none, .current, .valid:
            return true
        default:
            return false
        }
    }
}
