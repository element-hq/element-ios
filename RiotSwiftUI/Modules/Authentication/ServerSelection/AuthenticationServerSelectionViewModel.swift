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

@available(iOS 14, *)
typealias AuthenticationServerSelectionViewModelType = StateStoreViewModel<AuthenticationServerSelectionViewState,
                                                                           Never,
                                                                           AuthenticationServerSelectionViewAction>
@available(iOS 14, *)
class AuthenticationServerSelectionViewModel: AuthenticationServerSelectionViewModelType, AuthenticationServerSelectionViewModelProtocol {

    // MARK: - Properties

    // MARK: Private

    // MARK: Public

    var completion: ((AuthenticationServerSelectionViewModelResult) -> Void)?

    // MARK: - Setup

    init(homeserverAddress: String, hasModalPresentation: Bool) {
        let bindings = AuthenticationServerSelectionBindings(homeserverAddress: HomeserverAddress.displayable(homeserverAddress))
        super.init(initialViewState: AuthenticationServerSelectionViewState(bindings: bindings,
                                                                            hasModalPresentation: hasModalPresentation))
    }

    // MARK: - Public

    override func process(viewAction: AuthenticationServerSelectionViewAction) {
        Task {
            await MainActor.run {
                switch viewAction {
                case .confirm:
                    completion?(.confirm(homeserverAddress: state.bindings.homeserverAddress))
                case .dismiss:
                    completion?(.dismiss)
                case .getInTouch:
                    getInTouch()
                case .clearFooterError:
                    guard state.footerErrorMessage != nil else { return }
                    withAnimation { state.footerErrorMessage = nil }
                }
            }
        }
    }
    
    @MainActor func displayError(_ type: AuthenticationServerSelectionErrorType) {
        switch type {
        case .footerMessage(let message):
            withAnimation {
                state.footerErrorMessage = message
            }
        case .openURLAlert:
            state.bindings.alertInfo = AlertInfo(id: .openURLAlert, title: VectorL10n.roomMessageUnableOpenLinkErrorMessage)
        }
    }
    
    // MARK: - Private
    
    /// Opens the EMS link in the user's browser.
    @MainActor private func getInTouch() {
        let url = BuildSettings.onboardingHostYourOwnServerLink
        
        UIApplication.shared.open(url) { [weak self] success in
            guard !success, let self = self else { return }
            self.displayError(.openURLAlert)
        }
    }
}
