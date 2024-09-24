// File created from ScreenTemplate
// $ createScreen.sh Room/NotificationSettings RoomNotificationSettings
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Combine
import Foundation

class RoomNotificationSettingsViewModel: RoomNotificationSettingsViewModelType {
    // MARK: - Properties
    
    // MARK: Private
    
    private let roomNotificationService: RoomNotificationSettingsServiceType
    var state: RoomNotificationSettingsViewState {
        willSet {
            update(viewState: newValue)
        }
    }

    // MARK: Public
    
    weak var viewDelegate: RoomNotificationSettingsViewModelViewDelegate?
    
    weak var coordinatorDelegate: RoomNotificationSettingsViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(roomNotificationService: RoomNotificationSettingsServiceType,
         initialState: RoomNotificationSettingsViewState) {
        self.roomNotificationService = roomNotificationService
        state = initialState
        
        self.roomNotificationService.observeNotificationState { [weak self] state in
            guard let self = self else { return }
            self.state.notificationState = Self.mapNotificationStateOnRead(encrypted: self.state.roomEncrypted, state: state)
        }
    }
    
    convenience init(roomNotificationService: RoomNotificationSettingsServiceType,
                     avatarData: AvatarProtocol?,
                     displayName: String?,
                     roomEncrypted: Bool) {
        let notificationState = Self.mapNotificationStateOnRead(encrypted: roomEncrypted, state: roomNotificationService.notificationState)
        
        let initialState = RoomNotificationSettingsViewState(
            roomEncrypted: roomEncrypted,
            saving: false,
            notificationState: notificationState,
            avatarData: avatarData,
            displayName: displayName
        )
        self.init(roomNotificationService: roomNotificationService, initialState: initialState)
    }
    
    // MARK: - Public
    
    func process(viewAction: RoomNotificationSettingsViewAction) {
        switch viewAction {
        case .load:
            update(viewState: state)
        case .selectNotificationState(let state):
            self.state.notificationState = state
        case .save:
            state.saving = true
            roomNotificationService.update(state: state.notificationState) { [weak self] in
                guard let self = self else { return }
                self.state.saving = false
                self.coordinatorDelegate?.roomNotificationSettingsViewModelDidComplete(self)
            }
        case .cancel:
            coordinatorDelegate?.roomNotificationSettingsViewModelDidCancel(self)
        }
    }
    
    // MARK: - Private
    
    private static func mapNotificationStateOnRead(encrypted: Bool, state: RoomNotificationState) -> RoomNotificationState {
        if encrypted, case .mentionsAndKeywordsOnly = state {
            // Notifications not supported on encrypted rooms, map mentionsOnly to mute on read
            return .mute
        } else {
            return state
        }
    }
    
    func update(viewState: RoomNotificationSettingsViewState) {
        viewDelegate?.roomNotificationSettingsViewModel(self, didUpdateViewState: viewState)
    }
}
