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
typealias OnboardingDisplayNameViewModelType = StateStoreViewModel<OnboardingDisplayNameViewState,
                                                                 Never,
                                                                 OnboardingDisplayNameViewAction>
@available(iOS 14, *)
class OnboardingDisplayNameViewModel: OnboardingDisplayNameViewModelType, OnboardingDisplayNameViewModelProtocol {

    // MARK: - Properties

    // MARK: Private

    private let onboardingDisplayNameService: OnboardingDisplayNameServiceProtocol

    // MARK: Public

    var completion: (() -> Void)?

    // MARK: - Setup

    static func makeOnboardingDisplayNameViewModel(onboardingDisplayNameService: OnboardingDisplayNameServiceProtocol) -> OnboardingDisplayNameViewModelProtocol {
        return OnboardingDisplayNameViewModel(onboardingDisplayNameService: onboardingDisplayNameService)
    }

    private init(onboardingDisplayNameService: OnboardingDisplayNameServiceProtocol) {
        self.onboardingDisplayNameService = onboardingDisplayNameService
        super.init(initialViewState: Self.defaultState(onboardingDisplayNameService: onboardingDisplayNameService))
    }

    private static func defaultState(onboardingDisplayNameService: OnboardingDisplayNameServiceProtocol) -> OnboardingDisplayNameViewState {
        // Start with a blank display name to encourage the user not to just use the first part of their MXID.
        return OnboardingDisplayNameViewState(bindings: OnboardingDisplayNameBindings(displayName: ""))
    }
    
    // MARK: - Public

    override func process(viewAction: OnboardingDisplayNameViewAction) {
        switch viewAction {
        case .save:
            setDisplayName()
        case .skip:
            completion?()
        }
    }
    
    // MARK: - Private
    
    private func setDisplayName() {
        state.isWaiting = true
        
        onboardingDisplayNameService.setDisplayName(context.displayName) { [weak self] result in
            guard let self = self else { return }
            self.state.isWaiting = false
            
            switch result {
            case .success(_):
                self.completion?()
            case .failure(let error):
                self.state.bindings.alertInfo = AlertInfo(error: error as NSError)
            }
        }
    }
}
