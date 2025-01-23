//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias OnboardingAvatarViewModelType = StateStoreViewModel<OnboardingAvatarViewState, OnboardingAvatarViewAction>

class OnboardingAvatarViewModel: OnboardingAvatarViewModelType, OnboardingAvatarViewModelProtocol {
    // MARK: - Properties

    // MARK: Private

    // MARK: Public

    var callback: ((OnboardingAvatarViewModelResult) -> Void)?

    // MARK: - Setup

    init(userId: String, displayName: String?, avatarColorCount: Int) {
        let placeholderViewModel = PlaceholderAvatarViewModel(displayName: displayName, matrixItemId: userId, colorCount: avatarColorCount)
        let initialViewState = OnboardingAvatarViewState(placeholderAvatarLetter: placeholderViewModel.firstCharacterCapitalized,
                                                         placeholderAvatarColorIndex: placeholderViewModel.stableColorIndex,
                                                         bindings: OnboardingAvatarBindings())
        super.init(initialViewState: initialViewState)
    }
    
    // MARK: - Public

    override func process(viewAction: OnboardingAvatarViewAction) {
        switch viewAction {
        case .pickImage:
            callback?(.pickImage)
        case .takePhoto:
            callback?(.takePhoto)
        case .save:
            callback?(.save(state.avatar))
        case .skip:
            callback?(.skip)
        }
    }
    
    func updateAvatarImage(with image: UIImage?) {
        state.avatar = image
    }
    
    func processError(_ error: NSError?) {
        state.bindings.alertInfo = AlertInfo(error: error)
    }
}
