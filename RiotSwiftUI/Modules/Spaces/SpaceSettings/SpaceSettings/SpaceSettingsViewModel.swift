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
                                                                 SpaceSettingsStateAction,
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
        super.init(initialViewState: Self.defaultState(with: service))
        setupObservers()
    }

    private static func defaultState(with service: SpaceSettingsServiceProtocol) -> SpaceSettingsViewState {
        let bindings = SpaceSettingsViewModelBindings(
            name: service.roomProperties?.name ?? "",
            topic: service.roomProperties?.topic ?? "",
            address: service.roomProperties?.address ?? "",
            showPostProcessAlert: service.showPostProcessAlert.value)
        
        return SpaceSettingsViewState(
            defaultAddress: service.roomProperties?.name?.toValidAliasLocalPart() ?? "",
            avatar: AvatarInput(mxContentUri: service.mxContentUri, matrixItemId: service.matrixItemId, displayName: service.displayName),
            roomProperties: service.roomProperties,
            userSelectedAvatar: nil,
            showRoomAddress: service.roomProperties?.visibility == .public,
            roomNameError: nil,
            addressMessage: nil,
            isAddressValid: true,
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
        let loadingPublisher = service.isLoadingSubject
            .map(SpaceSettingsStateAction.updateLoading)
            .eraseToAnyPublisher()
        dispatch(actionPublisher: loadingPublisher)
        let showAlertPublisher = service.showPostProcessAlert
            .map(SpaceSettingsStateAction.updateShowPostProcessAlert)
            .eraseToAnyPublisher()
        dispatch(actionPublisher: showAlertPublisher)
        let roomPropertiesPublisher = service.roomPropertiesSubject
            .map(SpaceSettingsStateAction.updateRoomProperties)
            .eraseToAnyPublisher()
        dispatch(actionPublisher: roomPropertiesPublisher)
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
        }
    }

    func updateAvatarImage(with image: UIImage?) {
        dispatch(action: .updateAvatarImage(image))
    }
    
    override class func reducer(state: inout SpaceSettingsViewState, action: SpaceSettingsStateAction) {
        UILog.debug("[SpaceSettingsViewModel] reducer with action \(action) produced state: \(state)")

        switch action {
        case .updateLoading(let isLoading):
            state.isLoading = isLoading
        case .updateAvatarImage(let image):
            state.userSelectedAvatar = image
        case .updateShowPostProcessAlert(let show):
            state.bindings.showPostProcessAlert = show
        case .updateRoomProperties(let roomProperties):
            guard let roomProperties = roomProperties else {
                return
            }
            
            UILog.debug("[TOTO] reducer \(roomProperties.visibility)")

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
            state.visibilityString = visibilityString(with: roomProperties.visibility)
            state.showRoomAddress = roomProperties.visibility == .public
        }
    }

    private func done() {
        completion?(.done)
    }

    private func cancel() {
        completion?(.cancel)
    }
}
