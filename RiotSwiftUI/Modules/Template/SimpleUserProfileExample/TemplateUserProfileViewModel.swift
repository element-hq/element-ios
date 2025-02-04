//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias TemplateUserProfileViewModelType = StateStoreViewModel<TemplateUserProfileViewState, TemplateUserProfileViewAction>

class TemplateUserProfileViewModel: TemplateUserProfileViewModelType, TemplateUserProfileViewModelProtocol {
    private let templateUserProfileService: TemplateUserProfileServiceProtocol

    var completion: ((TemplateUserProfileViewModelResult) -> Void)?

    static func makeTemplateUserProfileViewModel(templateUserProfileService: TemplateUserProfileServiceProtocol) -> TemplateUserProfileViewModelProtocol {
        TemplateUserProfileViewModel(templateUserProfileService: templateUserProfileService)
    }

    private init(templateUserProfileService: TemplateUserProfileServiceProtocol) {
        self.templateUserProfileService = templateUserProfileService
        super.init(initialViewState: Self.defaultState(templateUserProfileService: templateUserProfileService))
        setupPresenceObserving()
    }

    private static func defaultState(templateUserProfileService: TemplateUserProfileServiceProtocol) -> TemplateUserProfileViewState {
        TemplateUserProfileViewState(
            avatar: templateUserProfileService.avatarData,
            displayName: templateUserProfileService.displayName,
            presence: templateUserProfileService.presenceSubject.value,
            count: 0
        )
    }
    
    private func setupPresenceObserving() {
        templateUserProfileService
            .presenceSubject
            .sink(receiveValue: { [weak self] presence in
                self?.state.presence = presence
            })
            .store(in: &cancellables)
    }
    
    // MARK: - Public

    override func process(viewAction: TemplateUserProfileViewAction) {
        switch viewAction {
        case .cancel:
            completion?(.cancel)
        case .done:
            completion?(.done)
        case .incrementCount:
            state.count += 1
        case .decrementCount:
            state.count -= 1
        }
    }
}
