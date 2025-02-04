//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias RoomUpgradeViewModelType = StateStoreViewModel<RoomUpgradeViewState, RoomUpgradeViewAction>

class RoomUpgradeViewModel: RoomUpgradeViewModelType, RoomUpgradeViewModelProtocol {
    // MARK: - Properties

    // MARK: Private

    private let roomUpgradeService: RoomUpgradeServiceProtocol

    // MARK: Public

    var completion: ((RoomUpgradeViewModelResult) -> Void)?

    // MARK: - Setup

    static func makeRoomUpgradeViewModel(roomUpgradeService: RoomUpgradeServiceProtocol) -> RoomUpgradeViewModelProtocol {
        RoomUpgradeViewModel(roomUpgradeService: roomUpgradeService)
    }

    private init(roomUpgradeService: RoomUpgradeServiceProtocol) {
        self.roomUpgradeService = roomUpgradeService
        super.init(initialViewState: Self.defaultState(roomUpgradeService: roomUpgradeService))
        setupObservers()
    }

    private static func defaultState(roomUpgradeService: RoomUpgradeServiceProtocol) -> RoomUpgradeViewState {
        RoomUpgradeViewState(waitingMessage: nil, isLoading: false, parentSpaceName: roomUpgradeService.parentSpaceName)
    }
    
    private func setupObservers() {
        roomUpgradeService
            .upgradingSubject
            .sink { [weak self] isUpgrading in
                self?.state.isLoading = isUpgrading
                self?.state.waitingMessage = isUpgrading ? VectorL10n.roomAccessSettingsScreenUpgradeAlertUpgrading : nil
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public

    override func process(viewAction: RoomUpgradeViewAction) {
        switch viewAction {
        case .cancel:
            completion?(.cancel(roomUpgradeService.currentRoomId))
        case .done(let autoInviteUsers):
            roomUpgradeService.upgradeRoom(autoInviteUsers: autoInviteUsers) { [weak self] success, _ in
                guard let self = self else { return }
                if success {
                    self.completion?(.done(self.roomUpgradeService.currentRoomId))
                }
            }
        }
    }
}
