// File created from TemplateAdvancedRoomsExample
// $ createSwiftUITwoScreen.sh Spaces/SpaceCreation SpaceCreation SpaceCreationMenu SpaceCreationSettings
//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias SpaceCreationSettingsViewModelType = StateStoreViewModel<SpaceCreationSettingsViewState, SpaceCreationSettingsViewAction>

class SpaceCreationSettingsViewModel: SpaceCreationSettingsViewModelType, SpaceCreationSettingsViewModelProtocol {
    // MARK: - Properties
    
    // MARK: Private
    
    private let spaceCreationSettingsService: SpaceCreationSettingsServiceProtocol
    private let creationParameters: SpaceCreationParameters
    
    // MARK: Public
    
    var callback: ((SpaceCreationSettingsViewModelAction) -> Void)?

    // MARK: - Setup
    
    init(spaceCreationSettingsService: SpaceCreationSettingsServiceProtocol, creationParameters: SpaceCreationParameters) {
        self.spaceCreationSettingsService = spaceCreationSettingsService
        self.creationParameters = creationParameters
        let defaultState = Self.defaultState(creationParameters: creationParameters, validationStatus: spaceCreationSettingsService.addressValidationSubject.value)
        super.init(initialViewState: defaultState)
        setupServiceObserving()
    }
    
    private func setupServiceObserving() {
        spaceCreationSettingsService
            .defaultAddressSubject
            .sink(receiveValue: { [weak self] address in
                self?.state.defaultAddress = address
            })
            .store(in: &cancellables)
        
        spaceCreationSettingsService
            .addressValidationSubject
            .sink(receiveValue: { [weak self] status in
                self?.state.addressMessage = status.message
                self?.state.isAddressValid = status.isValid
            })
            .store(in: &cancellables)
        
        spaceCreationSettingsService
            .avatarViewDataSubject
            .sink(receiveValue: { [weak self] avatar in
                self?.state.avatar = avatar
            })
            .store(in: &cancellables)
    }

    private static func defaultState(creationParameters: SpaceCreationParameters, validationStatus: SpaceCreationSettingsAddressValidationStatus) -> SpaceCreationSettingsViewState {
        let bindings = SpaceCreationSettingsViewModelBindings(
            roomName: creationParameters.name ?? "",
            topic: creationParameters.topic ?? "",
            address: creationParameters.userDefinedAddress ?? ""
        )
        
        return SpaceCreationSettingsViewState(
            title: creationParameters.isPublic ? VectorL10n.spacesCreationPublicSpaceTitle : VectorL10n.spacesCreationPrivateSpaceTitle,
            showRoomAddress: creationParameters.showAddress,
            defaultAddress: creationParameters.address ?? "",
            roomNameError: nil,
            addressMessage: validationStatus.message,
            isAddressValid: validationStatus.isValid,
            avatar: AvatarInput(mxContentUri: nil, matrixItemId: "", displayName: nil),
            avatarImage: creationParameters.userSelectedAvatar,
            bindings: bindings
        )
    }
    
    // MARK: - Public
    
    func updateAvatarImage(with image: UIImage?) {
        creationParameters.userSelectedAvatar = image
        state.avatarImage = image
    }
    
    override func process(viewAction: SpaceCreationSettingsViewAction) {
        switch viewAction {
        case .done:
            done()
        case .back:
            back()
        case .cancel:
            cancel()
        case .pickImage(let sourceRect):
            pickImage(from: sourceRect)
        case .nameChanged(let newValue):
            spaceCreationSettingsService.roomName = newValue
            creationParameters.address = spaceCreationSettingsService.defaultAddressSubject.value
            creationParameters.name = newValue
            state.roomNameError = newValue.isEmpty ? VectorL10n.spacesCreationEmptyRoomNameError : nil
        case .addressChanged(let newValue):
            spaceCreationSettingsService.userDefinedAddress = newValue
            creationParameters.userDefinedAddress = newValue
        case .topicChanged(let newValue):
            creationParameters.topic = newValue
        }
    }
        
    // MARK: - Private
    
    private func done() {
        guard !context.roomName.isEmpty else {
            state.roomNameError = VectorL10n.spacesCreationEmptyRoomNameError
            return
        }
        
        guard !creationParameters.isPublic || spaceCreationSettingsService.isAddressValid else {
            return
        }
        
        creationParameters.name = context.roomName
        creationParameters.topic = context.topic
        creationParameters.userDefinedAddress = context.address
        creationParameters.address = spaceCreationSettingsService.defaultAddressSubject.value
        
        state.roomNameError = nil
        callback?(.done)
    }
    
    private func cancel() {
        callback?(.cancel)
    }
    
    private func back() {
        callback?(.back)
    }
    
    private func pickImage(from sourceRect: CGRect) {
        callback?(.pickImage(sourceRect))
    }
}
