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

// MARK: - Coordinator

enum SpaceSettingsCoordinatorResult {
    case cancel
    case done
    case optionScreen(_ optionType: SpaceSettingsOptionType)
}

// MARK: View model

enum SpaceSettingsViewModelResult {
    case cancel
    case done
    case optionScreen(_ optionType: SpaceSettingsOptionType)
    case pickImage(_ sourceRect: CGRect)
}

// MARK: View

enum SpaceSettingsVisibility: CaseIterable {
    case `private`
    case restricted
    case `public`
    
    var stringValue: String {
        switch self {
        case .private:
            return VectorL10n.private
        case .public:
            return VectorL10n.public
        case .restricted:
            return VectorL10n.createRoomTypeRestricted
        }
    }
}

struct SpaceSettingsRoomProperties {
    let name: String?
    let topic: String?
    let address: String?
    let avatarUrl: String?
    let visibility: SpaceSettingsVisibility
    let allowedParentIds: [String]
    let isAvatarEditable: Bool
    let isNameEditable: Bool
    let isTopicEditable: Bool
    let isAddressEditable: Bool
    let isAccessEditable: Bool
}

struct SpaceSettingsViewState: BindableState {
    let defaultAddress: String
    let avatar: AvatarInputProtocol
    var roomProperties: SpaceSettingsRoomProperties?
    var userSelectedAvatar: UIImage?
    var showRoomAddress: Bool
    let roomNameError: String?
    var addressMessage: String?
    var isAddressValid: Bool
    var isLoading: Bool
    var visibilityString: String
    var options: [SpaceSettingsOption]
    var isModified: Bool {
        userSelectedAvatar != nil || isRoomNameModified || isTopicModified || isAddressModified
    }
    var isRoomNameModified: Bool {
        (roomProperties?.name ?? "") != bindings.name
    }
    var isTopicModified: Bool {
        (roomProperties?.topic ?? "") != bindings.topic
    }
    var isAddressModified: Bool {
        (roomProperties?.address ?? "") != bindings.address
    }
    var bindings: SpaceSettingsViewModelBindings
}

struct SpaceSettingsViewModelBindings {
    var name: String
    var topic: String
    var address: String
    var showPostProcessAlert: Bool
}

struct SpaceSettingsOption: Identifiable {
    let id: SpaceSettingsOptionType
    let icon: UIImage?
    let title: String?
    let value: String?
    let isEnabled: Bool
}

enum SpaceSettingsOptionType {
    case visibility
    case rooms
    case members
}

enum SpaceSettingsViewAction {
    case done(_ name: String, _ topic: String, _ address: String, _ userSelectedAvatar: UIImage?)
    case cancel
    case pickImage(_ sourceRect: CGRect)
    case optionSelected(_ optionType: SpaceSettingsOptionType)
    case addressChanged(_ newValue: String)
    case trackSpace
}
