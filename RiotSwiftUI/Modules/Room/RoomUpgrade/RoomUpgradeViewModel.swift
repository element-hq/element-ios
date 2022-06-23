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

typealias RoomUpgradeViewModelType = StateStoreViewModel<RoomUpgradeViewState,
                                                                 Never,
                                                                 RoomUpgradeViewAction>
class RoomUpgradeViewModel: RoomUpgradeViewModelType, RoomUpgradeViewModelProtocol {

    // MARK: - Properties

    // MARK: Private

    private let roomUpgradeService: RoomUpgradeServiceProtocol

    // MARK: Public

    var completion: ((RoomUpgradeViewModelResult) -> Void)?

    // MARK: - Setup

    static func makeRoomUpgradeViewModel(roomUpgradeService: RoomUpgradeServiceProtocol) -> RoomUpgradeViewModelProtocol {
        return RoomUpgradeViewModel(roomUpgradeService: roomUpgradeService)
    }

    private init(roomUpgradeService: RoomUpgradeServiceProtocol) {
        self.roomUpgradeService = roomUpgradeService
        super.init(initialViewState: Self.defaultState(roomUpgradeService: roomUpgradeService))
        setupObservers()
    }

    private static func defaultState(roomUpgradeService: RoomUpgradeServiceProtocol) -> RoomUpgradeViewState {
        return RoomUpgradeViewState(waitingMessage: nil, isLoading: false, parentSpaceName: roomUpgradeService.parentSpaceName)
    }
    
    private func setupObservers() {
        roomUpgradeService
            .upgradingSubject
            .sink { [weak self] isUpgrading in
                self?.state.isLoading = isUpgrading
                self?.state.waitingMessage = isUpgrading ? VectorL10n.roomAccessSettingsScreenUpgradeAlertUpgrading: nil
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public

    override func process(viewAction: RoomUpgradeViewAction) {
        switch viewAction {
        case .cancel:
            completion?(.cancel(roomUpgradeService.currentRoomId))
        case .done(let autoInviteUsers):
            roomUpgradeService.upgradeRoom(autoInviteUsers: autoInviteUsers) { [weak self] success, roomId in
                guard let self = self else { return }
                if success {
                    self.completion?(.done(self.roomUpgradeService.currentRoomId))
                }
            }
        }
    }
}
