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
    /// The user would like to choose an image from their photo library.
    case pickImage
    /// The user would like to take a photo to use as their avatar.
    case takePhoto
    /// The user would like to set specified image as their avatar.
    case save(UIImage?)
    /// Move on to the next screen in the flow without setting an avatar.
    case skip
}

// MARK: View

struct OnboardingAvatarViewState: BindableState {
    /// The letter shown in the placeholder avatar.
    let placeholderAvatarLetter: Character
    /// The color index to use for the placeholder avatar's background.
    let placeholderAvatarColorIndex: Int
    /// The image selected by the user to use as their avatar.
    var avatar: UIImage?
    var bindings: OnboardingAvatarBindings
    
    /// The image shown in the avatar's button.
    var buttonImage: ImageAsset {
        avatar == nil ? Asset.Images.onboardingAvatarCamera : Asset.Images.onboardingAvatarEdit
    }
}

struct OnboardingAvatarBindings {
    /// The currently displayed alert's info value otherwise `nil`.
    var alertInfo: AlertInfo<Int>?
}

enum OnboardingAvatarViewAction {
    /// The user would like to choose an image from their photo library.
    case pickImage
    /// The user would like to take a photo to use as their avatar.
    case takePhoto
    /// The user would like to save their chosen avatar image.
    case save
    /// Move on to the next screen in the flow without setting an avatar.
    case skip
}
