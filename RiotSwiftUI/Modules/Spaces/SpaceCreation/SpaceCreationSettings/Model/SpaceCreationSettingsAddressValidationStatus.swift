//
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
