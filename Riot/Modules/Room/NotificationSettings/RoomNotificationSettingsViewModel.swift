// File created from ScreenTemplate
// $ createScreen.sh Room/NotificationSettings RoomNotificationSettings
/*
 Copyright 2020 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation


final class RoomNotificationSettingsViewModel: RoomNotificationSettingsViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let roomNotificationRepository: RoomNotificationRepository
    private var state: RoomNotificationSettingsViewStateImpl {
        willSet {
            update(viewState: newValue)
        }
    }
    // MARK: Public

    weak var viewDelegate: RoomNotificationSettingsViewModelViewDelegate?
    
    weak var coordinatorDelegate: RoomNotificationSettingsViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(roomNotificationRepository: RoomNotificationRepository) {
        self.roomNotificationRepository = roomNotificationRepository
        self.state = RoomNotificationSettingsViewStateImpl(saving: false, notificationState: roomNotificationRepository.notificationState)
        self.roomNotificationRepository.observeNotificationState { state in
            self.state.notificationState = state
        }
    }
    
    // MARK: - Public
    
    func process(viewAction: RoomNotificationSettingsViewAction) {
        switch viewAction {
        case .load:
            update(viewState: self.state)
        case .selectNotificationState(let state):
            self.state.notificationState = state
        case .save:
            self.state.saving = true
            roomNotificationRepository.update(state: state.notificationState) { [weak self] in
                guard let self = self else { return }
                self.state.saving = false
                self.coordinatorDelegate?.roomNotificationSettingsViewModelDidComplete(self)
            }
        case .cancel:
            coordinatorDelegate?.roomNotificationSettingsViewModelDidCancel(self)
        }
    }
    
    // MARK: - Private
    
    private func update(viewState: RoomNotificationSettingsViewState) {
        self.viewDelegate?.roomNotificationSettingsViewModel(self, didUpdateViewState: viewState)
    }
}
