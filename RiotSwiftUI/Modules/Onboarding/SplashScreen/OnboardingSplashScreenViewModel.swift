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
typealias OnboardingSplashScreenViewModelType = StateStoreViewModel<OnboardingSplashScreenViewState,
                                                                    OnboardingSplashScreenStateAction,
                                                                    OnboardingSplashScreenViewAction>

protocol OnboardingSplashScreenViewModelProtocol {
    var completion: ((OnboardingSplashScreenViewModelResult) -> Void)? { get set }
    @available(iOS 14, *)
    var context: OnboardingSplashScreenViewModelType.Context { get }
}


@available(iOS 14, *)
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
        case .nextPage, .hiddenPage:
            dispatch(action: .viewAction(viewAction))
        }
    }

    override class func reducer(state: inout OnboardingSplashScreenViewState, action: OnboardingSplashScreenStateAction) {
        switch action {
        case .viewAction(let viewAction):
            switch viewAction {
            case .nextPage:
                state.bindings.pageIndex = (state.bindings.pageIndex + 1) % state.content.count
            case .hiddenPage:
                state.bindings.pageIndex = -1
            case .login, .register:
                break
            }
        }
        UILog.debug("[OnboardingSplashScreenViewModel] reducer with action \(action) produced state: \(state)")
    }

    private func register() {
        completion?(.register)
    }

    private func login() {
        completion?(.login)
    }
}
