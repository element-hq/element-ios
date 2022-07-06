// File created from TemplateAdvancedRoomsExample
// $ createSwiftUITwoScreen.sh Spaces/SpaceCreation SpaceCreation SpaceCreationMenu SpaceCreationSettings
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

typealias SpaceCreationSettingsViewModelType = StateStoreViewModel<SpaceCreationSettingsViewState,
                                                              SpaceCreationSettingsStateAction,
                                                              SpaceCreationSettingsViewAction>

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
        let defaultAddressUpdatePublisher = spaceCreationSettingsService.defaultAddressSubject
            .map(SpaceCreationSettingsStateAction.updateRoomDefaultAddress)
            .eraseToAnyPublisher()
        dispatch(actionPublisher: defaultAddressUpdatePublisher)
        
        let addressValidationUpdatePublisher = spaceCreationSettingsService.addressValidationSubject
            .map(SpaceCreationSettingsStateAction.updateAddressValidationStatus)
            .eraseToAnyPublisher()
        dispatch(actionPublisher: addressValidationUpdatePublisher)
        
        let avatarUpdatePublisher = spaceCreationSettingsService.avatarViewDataSubject
            .map(SpaceCreationSettingsStateAction.updateAvatar)
            .eraseToAnyPublisher()
        dispatch(actionPublisher: avatarUpdatePublisher)
    }

    private static func defaultState(creationParameters: SpaceCreationParameters, validationStatus: SpaceCreationSettingsAddressValidationStatus) -> SpaceCreationSettingsViewState {
        let bindings = SpaceCreationSettingsViewModelBindings(
            roomName: creationParameters.name ?? "",
            topic: creationParameters.topic ?? "",
            address: creationParameters.userDefinedAddress ?? "")
        
        return SpaceCreationSettingsViewState(
            title: creationParameters.isPublic ? VectorL10n.spacesCreationPublicSpaceTitle : VectorL10n.spacesCreationPrivateSpaceTitle,
            showRoomAddress: creationParameters.showAddress,
            defaultAddress: creationParameters.address ?? "",
            roomNameError: nil,
            addressMessage: validationStatus.message,
            isAddressValid: validationStatus.isValid,
            avatar: AvatarInput(mxContentUri: nil, matrixItemId: "", displayName: nil),
            avatarImage: creationParameters.userSelectedAvatar,
            bindings: bindings)
    }
    
    // MARK: - Public
    
    func updateAvatarImage(with image: UIImage?) {
        creationParameters.userSelectedAvatar = image
        dispatch(action: .updateAvatarImage(image))
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
            dispatch(action: .updateRoomNameError(newValue.isEmpty ? VectorL10n.spacesCreationEmptyRoomNameError : nil))
        case .addressChanged(let newValue):
            spaceCreationSettingsService.userDefinedAddress = newValue
            creationParameters.userDefinedAddress = newValue
        case .topicChanged(let newValue):
            creationParameters.topic = newValue
        }
    }
    
    override class func reducer(state: inout SpaceCreationSettingsViewState, action: SpaceCreationSettingsStateAction) {
        switch action {
        case .updateRoomNameError(let error):
            state.roomNameError = error
        case .updateRoomDefaultAddress(let defaultAddress):
            state.defaultAddress = defaultAddress
        case .updateAddressValidationStatus(let validationStatus):
            state.addressMessage = validationStatus.message
            state.isAddressValid = validationStatus.isValid
        case .updateAvatar(let avatar):
            state.avatar = avatar
        case .updateAvatarImage(let image):
            state.avatarImage = image
        }
    }
    
    // MARK: - Private
    
    private func done() {
        guard !context.roomName.isEmpty else {
            dispatch(action: .updateRoomNameError(VectorL10n.spacesCreationEmptyRoomNameError))
            return
        }
        
        guard !creationParameters.isPublic || spaceCreationSettingsService.isAddressValid else {
            return
        }
        
        creationParameters.name = context.roomName
        creationParameters.topic = context.topic
        creationParameters.userDefinedAddress = context.address
        creationParameters.address = spaceCreationSettingsService.defaultAddressSubject.value
        
        dispatch(action: .updateRoomNameError(nil))
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
