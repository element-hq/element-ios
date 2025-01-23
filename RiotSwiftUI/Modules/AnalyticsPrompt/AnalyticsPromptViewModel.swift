//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias AnalyticsPromptViewModelType = StateStoreViewModel<AnalyticsPromptViewState, AnalyticsPromptViewAction>

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
