// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationEmailInvites SpaceCreationEmailInvites
//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias SpaceCreationEmailInvitesViewModelType = StateStoreViewModel<SpaceCreationEmailInvitesViewState, SpaceCreationEmailInvitesViewAction>

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
        super.init(initialViewState: SpaceCreationEmailInvitesViewModel.defaultState(creationParameters: creationParameters, service: service))
    }
    
    private func setupServiceObserving() {
        service
            .isLoadingSubject
            .sink(receiveValue: { [weak self] isLoading in
                self?.state.loading = isLoading
            })
            .store(in: &cancellables)
    }

    private static func defaultState(creationParameters: SpaceCreationParameters, service: SpaceCreationEmailInvitesServiceProtocol) -> SpaceCreationEmailInvitesViewState {
        let emailValidation = service.validate(creationParameters.emailInvites)
        let bindings = SpaceCreationEmailInvitesViewModelBindings(emailInvites: creationParameters.emailInvites)
        return SpaceCreationEmailInvitesViewState(
            title: creationParameters.isPublic ? VectorL10n.spacesCreationPublicSpaceTitle : VectorL10n.spacesCreationPrivateSpaceTitle,
            emailAddressesValid: emailValidation,
            loading: service.isLoadingSubject.value,
            bindings: bindings
        )
    }
    
    // MARK: - Public

    override func process(viewAction: SpaceCreationEmailInvitesViewAction) {
        switch viewAction {
        case .cancel:
            cancel()
        case .back:
            back()
        case .done:
            done()
        case .inviteByUsername:
            inviteByUsername()
        }
    }

    private func done() {
        creationParameters.emailInvites = context.emailInvites
        creationParameters.inviteType = .email
        
        let emailAddressesValidity = service.validate(context.emailInvites)
        state.emailAddressesValid = emailAddressesValidity
        
        if context.emailInvites.reduce(true, { $0 && $1.isEmpty }) {
            completion?(.done)
        } else if emailAddressesValidity.reduce(true, { $0 && $1 }) {
            if service.isIdentityServiceReady {
                completion?(.done)
            } else {
                service.prepareIdentityService { [weak self] baseURL, accessToken in
                    self?.completion?(.needIdentityServiceTerms(baseURL, accessToken))
                } failure: { [weak self] error in
                    self?.completion?(.identityServiceFailure(error))
                }
            }
        }
    }

    private func cancel() {
        completion?(.cancel)
    }
    
    private func back() {
        completion?(.back)
    }
    
    private func inviteByUsername() {
        completion?(.inviteByUsername)
    }
}
