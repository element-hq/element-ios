//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
