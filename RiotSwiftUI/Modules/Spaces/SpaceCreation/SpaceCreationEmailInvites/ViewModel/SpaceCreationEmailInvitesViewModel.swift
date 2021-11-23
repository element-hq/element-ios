// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationEmailInvites SpaceCreationEmailInvites
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
typealias SpaceCreationEmailInvitesViewModelType = StateStoreViewModel<SpaceCreationEmailInvitesViewState,
                                                                 SpaceCreationEmailInvitesStateAction,
                                                                 SpaceCreationEmailInvitesViewAction>
@available(iOS 14, *)
class SpaceCreationEmailInvitesViewModel: SpaceCreationEmailInvitesViewModelType, SpaceCreationEmailInvitesViewModelProtocol {

    // MARK: - Properties

    // MARK: Private

    private let creationParameters: SpaceCreationParameters
    private let service: SpaceCreationEmailInvitesServiceProtocol

    // MARK: Public

    var completion: ((SpaceCreationEmailInvitesViewModelResult) -> Void)?

    // MARK: - Setup

    init(creationParameters: SpaceCreationParameters, service: SpaceCreationEmailInvitesServiceProtocol) {
        self.creationParameters = creationParameters
        self.service = service
        let emailValidation = service.validate(creationParameters.emailInvites)
        super.init(initialViewState: SpaceCreationEmailInvitesViewModel.defaultState(creationParameters: creationParameters, emailValidation: emailValidation))
    }

    private static func defaultState(creationParameters: SpaceCreationParameters, emailValidation: [Bool]) -> SpaceCreationEmailInvitesViewState {
        let bindings = SpaceCreationEmailInvitesViewModelBindings(emailInvites: creationParameters.emailInvites)
        return SpaceCreationEmailInvitesViewState(
            title: creationParameters.isPublic ? VectorL10n.spacesCreationPublicSpaceTitle : VectorL10n.spacesCreationPrivateSpaceTitle,
            emailAddressesValid: emailValidation,
            bindings: bindings
        )
    }
    
    // MARK: - Public

    override func process(viewAction: SpaceCreationEmailInvitesViewAction) {
        switch viewAction {
        case .cancel:
            cancel()
        case .done:
            done()
        case .inviteByUsername:
            inviteByUsername()
        }
    }

    override class func reducer(state: inout SpaceCreationEmailInvitesViewState, action: SpaceCreationEmailInvitesStateAction) {
        switch action {
        case .updateEmailValidity(let emailValidity):
            state.emailAddressesValid = emailValidity
        }
    }

    private func done() {
        self.creationParameters.emailInvites = self.context.emailInvites
        let emailAddressesValidity = service.validate(self.context.emailInvites)
        
        dispatch(action: .updateEmailValidity(emailAddressesValidity))
        if emailAddressesValidity.reduce(true, { $0 && $1}) {
            completion?(.done)
        }
    }

    private func cancel() {
        completion?(.cancel)
    }
    
    private func inviteByUsername() {
        completion?(.inviteByUsername)
    }
}
