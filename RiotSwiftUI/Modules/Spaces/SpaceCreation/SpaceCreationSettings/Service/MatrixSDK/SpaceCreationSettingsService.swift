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

import Foundation
import Combine
import MatrixSDK

@available(iOS 14.0, *)
class SpaceCreationSettingsService: SpaceCreationSettingsServiceProtocol {
    
    // MARK: - Properties
    
    var roomName: String {
        didSet {
            updateDefaultAddress()
            updateAvatar()
        }
    }
    var userDefinedAddress: String? {
        didSet {
            validateAddress()
        }
    }

    // MARK: Private
    
    private let session: MXSession
    private var defaultAddress: String {
        didSet {
            defaultAddressSubject.send(defaultAddress)
            validateAddress()
        }
    }
    private var lastValidatedAddress: String = ""
    private var currentAddress: String? {
        return self.userDefinedAddress?.count ?? 0 > 0 ? self.userDefinedAddress : defaultAddress
    }
    private var currentOperation: MXHTTPOperation?
    
    // MARK: Public
    
    private(set) var addressValidationSubject: CurrentValueSubject<SpaceCreationSettingsAddressValidationStatus, Never>
    private(set) var defaultAddressSubject: CurrentValueSubject<String, Never>
    private(set) var avatarViewDataSubject: CurrentValueSubject<AvatarInputProtocol, Never>
    var isAddressValid: Bool {
        switch addressValidationSubject.value {
        case .none, .valid:
            return true
        default:
            return false
        }
    }

    // MARK: - Setup
    
    init(roomName: String, userDefinedAddress: String?, session: MXSession) {
        self.session = session
        self.defaultAddress = ""
        self.defaultAddressSubject = CurrentValueSubject(defaultAddress)
        self.roomName = roomName
        self.addressValidationSubject = CurrentValueSubject(.none("#"))
        self.avatarViewDataSubject = CurrentValueSubject(AvatarInput(mxContentUri: userDefinedAddress, matrixItemId: "", displayName: roomName))
        
        self.updateDefaultAddress()
        self.validateAddress()
    }
    
    deinit {
        currentOperation?.cancel()
        currentOperation = nil
    }
    
    // MARK: Public
    
    // MARK: Private
    
    private func updateAvatar() {
        self.avatarViewDataSubject.send(AvatarInput(mxContentUri: currentAddress, matrixItemId: "", displayName: roomName))
    }
    
    private func updateDefaultAddress() {
        defaultAddress = MXTools.validAliasLocalPart(from: roomName)
    }
    
    private func validateAddress() {
        currentOperation?.cancel()
        currentOperation = nil

        guard let userDefinedAddress = self.userDefinedAddress, !userDefinedAddress.isEmpty else {
            let fullAddress = MXTools.fullLocalAlias(from: defaultAddress, with: session)
            
            if defaultAddress.isEmpty {
                addressValidationSubject.send(.none(fullAddress))
            } else {
                validate(defaultAddress)
            }
            return
        }
        
        validate(userDefinedAddress)
    }
    
    private func validate(_ aliasLocalPart: String) {
        let fullAddress = MXTools.fullLocalAlias(from: aliasLocalPart, with: session)

        currentOperation = MXRoomAliasAvailabilityChecker.validate(aliasLocalPart: aliasLocalPart, with: session) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .available:
                self.addressValidationSubject.send(.valid(fullAddress))
            case .invalid:
                self.addressValidationSubject.send(.invalidCharacters(fullAddress))
            case .notAvailable:
                self.addressValidationSubject.send(.alreadyExists(fullAddress))
            case .serverError:
                self.addressValidationSubject.send(.none(fullAddress))
            }
        }
    }
}
