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
