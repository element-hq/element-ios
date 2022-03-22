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

import SwiftUI
import Combine

@available(iOS 14, *)
typealias OnboardingAvatarViewModelType = StateStoreViewModel<OnboardingAvatarViewState,
                                                              Never,
                                                              OnboardingAvatarViewAction>
@available(iOS 14, *)
class OnboardingAvatarViewModel: OnboardingAvatarViewModelType, OnboardingAvatarViewModelProtocol {

    // MARK: - Properties

    // MARK: Private

    // MARK: Public

    var completion: ((OnboardingAvatarViewModelResult) -> Void)?

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
            completion?(.pickImage)
        case .takePhoto:
            completion?(.takePhoto)
        case .save:
            completion?(.save(state.avatar))
        case .skip:
            completion?(.skip)
        }
    }
    
    func updateAvatarImage(with image: UIImage?) {
        state.avatar = image
    }
    
    func processError(_ error: NSError?) {
        state.bindings.alertInfo = AlertInfo(error: error)
    }
}
