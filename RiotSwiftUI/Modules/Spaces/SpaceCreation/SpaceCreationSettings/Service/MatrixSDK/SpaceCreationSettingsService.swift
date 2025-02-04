// File created from TemplateAdvancedRoomsExample
// $ createSwiftUITwoScreen.sh Spaces/SpaceCreation SpaceCreation SpaceCreationMenu SpaceCreationSettings
//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import MatrixSDK

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

    private var lastValidatedAddress = ""
    private var currentAddress: String? {
        userDefinedAddress?.count ?? 0 > 0 ? userDefinedAddress : defaultAddress
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
        defaultAddress = ""
        defaultAddressSubject = CurrentValueSubject(defaultAddress)
        self.roomName = roomName
        addressValidationSubject = CurrentValueSubject(.none("#"))
        avatarViewDataSubject = CurrentValueSubject(AvatarInput(mxContentUri: userDefinedAddress, matrixItemId: "", displayName: roomName))
        
        updateDefaultAddress()
        validateAddress()
    }
    
    deinit {
        currentOperation?.cancel()
        currentOperation = nil
    }
    
    // MARK: Public
    
    // MARK: Private
    
    private func updateAvatar() {
        avatarViewDataSubject.send(AvatarInput(mxContentUri: currentAddress, matrixItemId: "", displayName: roomName))
    }
    
    private func updateDefaultAddress() {
        defaultAddress = MXTools.validAliasLocalPart(from: roomName)
    }
    
    private func validateAddress() {
        currentOperation?.cancel()
        currentOperation = nil

        guard let userDefinedAddress = userDefinedAddress, !userDefinedAddress.isEmpty else {
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
