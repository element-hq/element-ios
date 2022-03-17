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

import UIKit

// MARK: View model

enum OnboardingAvatarViewModelResult {
    case pickImage
    case takePhoto
    case save(UIImage?)
    case skip
}

// MARK: View

struct OnboardingAvatarViewState: BindableState {
    let placeholderAvatarLetter: String
    let placeholderAvatarColorIndex: Int
    var avatar: UIImage?
    var bindings: OnboardingAvatarBindings
    
    var buttonImage: ImageAsset {
        avatar == nil ? Asset.Images.onboardingAvatarCamera : Asset.Images.onboardingAvatarEdit
    }
    
    var avatarAccessibilityLabel: String {
        avatar == nil ? VectorL10n.onboardingAvatarPlaceholderAccessibilityLabel(placeholderAvatarLetter) : VectorL10n.onboardingAvatarImageAccessibilityLabel
    }
}

struct OnboardingAvatarBindings {
    var alertInfo: AlertInfo<Int>?
}

enum OnboardingAvatarViewAction {
    case pickImage
    case takePhoto
    case save
    case skip
}
