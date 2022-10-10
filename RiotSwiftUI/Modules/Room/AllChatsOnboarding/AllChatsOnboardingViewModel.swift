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

typealias AllChatsOnboardingViewModelType = StateStoreViewModel<AllChatsOnboardingViewState, AllChatsOnboardingViewAction>

class AllChatsOnboardingViewModel: AllChatsOnboardingViewModelType, AllChatsOnboardingViewModelProtocol {
    // MARK: - Properties

    // MARK: Private

    // MARK: Public

    var completion: ((AllChatsOnboardingViewModelResult) -> Void)?

    // MARK: - Setup

    static func makeAllChatsOnboardingViewModel() -> AllChatsOnboardingViewModelProtocol {
        AllChatsOnboardingViewModel()
    }

    private init() {
        super.init(initialViewState: Self.defaultState())
    }

    private static func defaultState() -> AllChatsOnboardingViewState {
        AllChatsOnboardingViewState(pages: [
            AllChatsOnboardingPageData(image: Asset.Images.allChatsOnboarding1.image,
                                       title: VectorL10n.allChatsOnboardingPageTitle1,
                                       message: VectorL10n.allChatsOnboardingPageMessage1),
            AllChatsOnboardingPageData(image: Asset.Images.allChatsOnboarding2.image,
                                       title: VectorL10n.allChatsOnboardingPageTitle2,
                                       message: VectorL10n.allChatsOnboardingPageMessage2),
            AllChatsOnboardingPageData(image: Asset.Images.allChatsOnboarding3.image,
                                       title: VectorL10n.allChatsOnboardingPageTitle3,
                                       message: VectorL10n.allChatsOnboardingPageMessage3)
        ])
    }
    
    // MARK: - Public

    override func process(viewAction: AllChatsOnboardingViewAction) {
        switch viewAction {
        case .cancel:
            completion?(.cancel)
        }
    }
}
