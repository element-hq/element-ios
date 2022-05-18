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

typealias TemplateUserProfileViewModelType = StateStoreViewModel<TemplateUserProfileViewState,
                                                                 Never,
                                                                 TemplateUserProfileViewAction>

class TemplateUserProfileViewModel: TemplateUserProfileViewModelType, TemplateUserProfileViewModelProtocol {

    // MARK: - Properties

    // MARK: Private

    private let templateUserProfileService: TemplateUserProfileServiceProtocol

    // MARK: Public

    var completion: ((TemplateUserProfileViewModelResult) -> Void)?

    // MARK: - Setup

    static func makeTemplateUserProfileViewModel(templateUserProfileService: TemplateUserProfileServiceProtocol) -> TemplateUserProfileViewModelProtocol {
        return TemplateUserProfileViewModel(templateUserProfileService: templateUserProfileService)
    }

    private init(templateUserProfileService: TemplateUserProfileServiceProtocol) {
        self.templateUserProfileService = templateUserProfileService
        super.init(initialViewState: Self.defaultState(templateUserProfileService: templateUserProfileService))
        setupPresenceObserving()
    }

    private static func defaultState(templateUserProfileService: TemplateUserProfileServiceProtocol) -> TemplateUserProfileViewState {
        return TemplateUserProfileViewState(
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
