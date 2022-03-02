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
typealias SpaceSettingsViewModelType = StateStoreViewModel<SpaceSettingsViewState,
                                                                 Never,
                                                                 SpaceSettingsViewAction>
@available(iOS 14, *)
class SpaceSettingsViewModel: SpaceSettingsViewModelType, SpaceSettingsViewModelProtocol {

    // MARK: - Properties
    
    private static let options: [SpaceSettingsOption] = [
        SpaceSettingsOption(id: .rooms, icon: Asset.Images.spaceRoomIcon.image, title: VectorL10n.titleRooms, value: nil, isEnabled: true),
        SpaceSettingsOption(id: .members, icon: Asset.Images.spaceMenuMembers.image, title: VectorL10n.roomDetailsPeople, value: nil, isEnabled: true)
    ]

    // MARK: Private

    private let service: SpaceSettingsServiceProtocol

    // MARK: Public

    var completion: ((SpaceSettingsViewModelResult) -> Void)?

    // MARK: - Setup

    static func makeSpaceSettingsViewModel(service: SpaceSettingsServiceProtocol) -> SpaceSettingsViewModelProtocol {
        return SpaceSettingsViewModel(service: service)
    }

    private init(service: SpaceSettingsServiceProtocol) {
        self.service = service
        super.init(initialViewState: Self.defaultState(with: service, validationStatus: service.addressValidationSubject.value))
        setupObservers()
    }

    private static func defaultState(with service: SpaceSettingsServiceProtocol, validationStatus: SpaceCreationSettingsAddressValidationStatus) -> SpaceSettingsViewState {
        let bindings = SpaceSettingsViewModelBindings(
            name: service.roomProperties?.name ?? "",
            topic: service.roomProperties?.topic ?? "",
            address: service.roomProperties?.address ?? "",
            showPostProcessAlert: service.showPostProcessAlert.value)
        
        return SpaceSettingsViewState(
            defaultAddress: service.roomProperties?.address ?? "",
            avatar: AvatarInput(mxContentUri: service.mxContentUri, matrixItemId: service.matrixItemId, displayName: service.displayName),
            roomProperties: service.roomProperties,
            userSelectedAvatar: nil,
            showRoomAddress: service.roomProperties?.visibility == .public,
            roomNameError: nil,
            addressMessage: addressMessage(with: validationStatus),
            isAddressValid: isAddressValid(with: validationStatus),
            isLoading: service.isLoadingSubject.value,
            visibilityString: visibilityString(with: service.roomProperties?.visibility ?? .private),
            options: options,
            bindings: bindings)
    }
    
    private static func visibilityString(with visibility: SpaceSettingsVisibility) -> String {
        switch visibility {
        case .private:
            return VectorL10n.private
        case .public:
            return VectorL10n.public
        case .restricted:
            return VectorL10n.createRoomTypeRestricted
        }
    }

    private func setupObservers() {
        service.isLoadingSubject.sink { [weak self] isLoading in
                self?.state.isLoading = isLoading
        }
        .store(in: &cancellables)
        
        service.showPostProcessAlert.sink { [weak self] showPostProcessAlert in
            self?.state.bindings.showPostProcessAlert = showPostProcessAlert
        }
        .store(in: &cancellables)
        
        service.roomPropertiesSubject.sink { [weak self] roomProperties in
            guard let roomProperties = roomProperties, let self = self else {
                return
            }
            
            self.propertiesUpdated(roomProperties)
        }
        .store(in: &cancellables)
        
        service.addressValidationSubject.sink { [weak self] validationStatus in
            self?.state.addressMessage = Self.addressMessage(with: validationStatus)
            self?.state.isAddressValid = Self.isAddressValid(with: validationStatus)
        }
        .store(in: &cancellables)
    }

    // MARK: - Public

    override func process(viewAction: SpaceSettingsViewAction) {
        switch viewAction {
        case .cancel:
            cancel()
        case .pickImage(let sourceRect):
            completion?(.pickImage(sourceRect))
        case .optionSelected(let optionType):
            completion?(.optionScreen(optionType))
        case .done(let name, let topic, let address, let userSelectedAvatar):
            service.update(roomName: name, topic: topic, address: address, avatar: userSelectedAvatar) { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success:
                    self.done()
                case .failure:
                    break
                }
            }
        case .addressChanged(let newValue):
            service.addressDidChange(newValue)
        }
    }

    func updateAvatarImage(with image: UIImage?) {
        state.userSelectedAvatar = image
    }
    
    private func propertiesUpdated(_ roomProperties: SpaceSettingsRoomProperties) {
        state.roomProperties = roomProperties
        if !state.isRoomNameModified {
            state.bindings.name = roomProperties.name ?? ""
        }
        if !state.isTopicModified {
            state.bindings.topic = roomProperties.topic ?? ""
        }
        if !state.isAddressModified {
            state.bindings.address = roomProperties.address ?? ""
        }
        state.visibilityString = Self.visibilityString(with: roomProperties.visibility)
        state.showRoomAddress = roomProperties.visibility == .public
    }

    private func done() {
        completion?(.done)
    }

    private func cancel() {
        completion?(.cancel)
    }
    
    private static func addressMessage(with validationStatus: SpaceCreationSettingsAddressValidationStatus) -> String {
        switch validationStatus {
        case .none(let fullAddress):
            return VectorL10n.spacesCreationAddressDefaultMessage(fullAddress)
        case .current(let fullAddress):
            return VectorL10n.spaceSettingsCurrentAddressMessage(fullAddress)
        case .valid(let fullAddress):
            return VectorL10n.spacesCreationAddressDefaultMessage(fullAddress)
        case .alreadyExists(let fullAddress):
            return VectorL10n.spacesCreationAddressAlreadyExists(fullAddress)
        case .invalidCharacters(let fullAddress):
            return VectorL10n.spacesCreationAddressInvalidCharacters(fullAddress)
        }
    }
    
    private static func isAddressValid(with validationStatus: SpaceCreationSettingsAddressValidationStatus) -> Bool {
        switch validationStatus {
        case .none, .current, .valid:
            return true
        default:
            return false
        }
    }
}
