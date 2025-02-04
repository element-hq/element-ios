//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
