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

typealias AnalyticsPromptViewModelType = StateStoreViewModel<AnalyticsPromptViewState,
                                                             Never,
                                                             AnalyticsPromptViewAction>
class AnalyticsPromptViewModel: AnalyticsPromptViewModelType {

    // MARK: - Properties

    // MARK: Private
    
    let termsURL: URL

    // MARK: Public

    var completion: ((AnalyticsPromptViewModelResult) -> Void)?

    // MARK: - Setup
    
    /// Initialize a view model with the specified prompt type and app display name.
    init(promptType: AnalyticsPromptType, strings: AnalyticsPromptStringsProtocol, termsURL: URL) {
        self.termsURL = termsURL
        super.init(initialViewState: AnalyticsPromptViewState(promptType: promptType, strings: strings))
    }

    // MARK: - Public
    
    override func process(viewAction: AnalyticsPromptViewAction) {
        switch viewAction {
        case .enable:
            enable()
        case .disable:
            disable()
        case .openTermsURL:
            openTermsURL()
        }
    }
    
    /// Enable analytics. The call to the Analytics class is made in the completion.
    private func enable() {
        completion?(.enable)
    }

    /// Disable analytics. The call to the Analytics class is made in the completion.
    private func disable() {
        completion?(.disable)
    }
    
    /// Open the service terms link.
    private func openTermsURL() {
        UIApplication.shared.open(termsURL)
    }
}
