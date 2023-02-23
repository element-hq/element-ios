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

typealias OnboardingSplashScreenViewModelType = StateStoreViewModel<OnboardingSplashScreenViewState, OnboardingSplashScreenViewAction>

protocol OnboardingSplashScreenViewModelProtocol {
    var completion: ((OnboardingSplashScreenViewModelResult) -> Void)? { get set }
    var context: OnboardingSplashScreenViewModelType.Context { get }
}

class OnboardingSplashScreenViewModel: OnboardingSplashScreenViewModelType, OnboardingSplashScreenViewModelProtocol {
    // MARK: - Properties

    // MARK: Private

    // MARK: Public

    var completion: ((OnboardingSplashScreenViewModelResult) -> Void)?

    // MARK: - Setup

    init() {
        super.init(initialViewState: OnboardingSplashScreenViewState())
    }

    // MARK: - Public

    override func process(viewAction: OnboardingSplashScreenViewAction) {
        switch viewAction {
        case .register:
            register()
        case .login:
            login()
        case .nextPage:
            // Wrap back round to the first page index when reaching the end.
            state.bindings.pageIndex = (state.bindings.pageIndex + 1) % state.content.count
        case .previousPage:
            // Prevent the hidden page at index -1 from being shown.
            state.bindings.pageIndex = max(0, state.bindings.pageIndex - 1)
        case .hiddenPage:
            // Hidden page for a nicer animation when looping back to the start.
            state.bindings.pageIndex = -1
        }
    }

    private func register() {
        completion?(.register)
    }

    private func login() {
        completion?(.login)
    }
}
