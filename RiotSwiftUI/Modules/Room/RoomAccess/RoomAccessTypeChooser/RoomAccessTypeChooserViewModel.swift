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
    
typealias RoomAccessTypeChooserViewModelType = StateStoreViewModel<RoomAccessTypeChooserViewState,
                                                              RoomAccessTypeChooserStateAction,
                                                              RoomAccessTypeChooserViewAction>
class RoomAccessTypeChooserViewModel: RoomAccessTypeChooserViewModelType, RoomAccessTypeChooserViewModelProtocol {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let roomAccessTypeChooserService: RoomAccessTypeChooserServiceProtocol
    
    // MARK: Public
    
    var callback: ((RoomAccessTypeChooserViewModelAction) -> Void)?
    
    // MARK: - Setup
    
    init(roomAccessTypeChooserService: RoomAccessTypeChooserServiceProtocol) {
        self.roomAccessTypeChooserService = roomAccessTypeChooserService
        super.init(initialViewState: Self.defaultState(roomAccessTypeChooserService: roomAccessTypeChooserService))
        startObservingService()
    }
    
    private static func defaultState(roomAccessTypeChooserService: RoomAccessTypeChooserServiceProtocol) -> RoomAccessTypeChooserViewState {
        let bindings = RoomAccessTypeChooserViewModelBindings(
            showUpgradeRoomAlert: roomAccessTypeChooserService.roomUpgradeRequiredSubject.value,
            waitingMessage: roomAccessTypeChooserService.waitingMessageSubject.value, isLoading: roomAccessTypeChooserService.waitingMessageSubject.value != nil)
        return RoomAccessTypeChooserViewState(accessItems: roomAccessTypeChooserService.accessItemsSubject.value, bindings: bindings)
    }
    
    private func startObservingService() {
        let accessTypePublisher = roomAccessTypeChooserService.accessItemsSubject
            .map(RoomAccessTypeChooserStateAction.updateAccessItems)
            .eraseToAnyPublisher()
        dispatch(actionPublisher: accessTypePublisher)
        roomAccessTypeChooserService
            .roomUpgradeRequiredSubject
            .sink { [weak self] isUpgradeRequired in
                if isUpgradeRequired {
                    self?.upgradeRoom()
                }
            }
            .store(in: &cancellables)
        let waitingMessagePublisher = roomAccessTypeChooserService.waitingMessageSubject
            .map(RoomAccessTypeChooserStateAction.updateWaitingMessage)
            .eraseToAnyPublisher()
        dispatch(actionPublisher: waitingMessagePublisher)
    }
    
    // MARK: - Public
    
    override func process(viewAction: RoomAccessTypeChooserViewAction) {
        switch viewAction {
        case .didSelectAccessType(let accessType):
            didSelect(accessType: accessType)
        case .done:
            done()
        case .cancel:
            cancel()
        }
    }
    
    override class func reducer(state: inout RoomAccessTypeChooserViewState, action: RoomAccessTypeChooserStateAction) {
        switch action {
        case .updateAccessItems(let accessItems):
            state.accessItems = accessItems
        case .updateShowUpgradeRoomAlert(let show):
            state.bindings.showUpgradeRoomAlert = show
        case .updateWaitingMessage(let message):
            state.bindings.waitingMessage = message
            state.bindings.isLoading = message != nil
        }
    }
    
    func handleRoomUpgradeResult(_ result: RoomUpgradeCoordinatorResult) {
        switch result {
        case .cancel(let roomId):
            roomAccessTypeChooserService.updateRoomId(with: roomId)
        case .done(let roomId):
            roomAccessTypeChooserService.updateRoomId(with: roomId)
            callback?(.spaceSelection(roomId, .restricted))
        }
    }
    
    // MARK: - Private
    
    private func upgradeRoom() {
        guard let versionOverride = roomAccessTypeChooserService.versionOverride else {
            UILog.error("[RoomAccessTypeChooserViewModel] upgradeRoom: versionOverride not found")
            return
        }
        
        callback?(.roomUpgradeNeeded(roomAccessTypeChooserService.currentRoomId, versionOverride))
    }
    
    private func done() {
        roomAccessTypeChooserService.applySelection { [weak self] in
            guard let self = self else { return }
            
            if self.roomAccessTypeChooserService.selectedType == .restricted {
                self.callback?(.spaceSelection(self.roomAccessTypeChooserService.currentRoomId, .restricted))
            } else {
                self.callback?(.done(self.roomAccessTypeChooserService.currentRoomId))
            }
        }
    }
    
    private func cancel() {
        callback?(.cancel(roomAccessTypeChooserService.currentRoomId))
    }
    
    private func didSelect(accessType: RoomAccessTypeChooserAccessType) {
        roomAccessTypeChooserService.updateSelection(with: accessType)
        if accessType == .restricted && !roomAccessTypeChooserService.roomUpgradeRequiredSubject.value {
            callback?(.spaceSelection(roomAccessTypeChooserService.currentRoomId, .restricted))
        }
    }
}
