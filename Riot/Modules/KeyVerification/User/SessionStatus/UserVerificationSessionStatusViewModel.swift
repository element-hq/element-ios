// File created from ScreenTemplate
// $ createScreen.sh SessionStatus UserVerificationSessionStatus
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

struct SessionStatusViewData {
    let userId: String
    let userDisplayName: String?
    let isCurrentUser: Bool
    
    let deviceId: String
    let deviceName: String
    let isDeviceTrusted: Bool
}

enum UserVerificationSessionStatusViewModelError: Error {
    case deviceNotFound
}

final class UserVerificationSessionStatusViewModel: UserVerificationSessionStatusViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    private let userId: String
    private let userDisplayName: String?
    private let deviceId: String
    
    // MARK: Public

    weak var viewDelegate: UserVerificationSessionStatusViewModelViewDelegate?
    weak var coordinatorDelegate: UserVerificationSessionStatusViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, userId: String, userDisplayName: String?, deviceId: String) {
        self.session = session
        self.userId = userId
        self.userDisplayName = userDisplayName
        self.deviceId = deviceId
    }
    
    // MARK: - Public
    
    func process(viewAction: UserVerificationSessionStatusViewAction) {
        switch viewAction {
        case .loadData:
            self.loadData()
        case .verify:
             self.coordinatorDelegate?.userVerificationSessionStatusViewModel(self, wantsToVerifyDeviceWithId: self.deviceId, for: self.userId)
        case .verifyManually:
            self.coordinatorDelegate?.userVerificationSessionStatusViewModel(self, wantsToManuallyVerifyDeviceWithId: self.deviceId, for: self.userId)
        case .close:
            self.coordinatorDelegate?.userVerificationSessionStatusViewModelDidClose(self)
        }
    }
    
    // MARK: - Private
    
    private func loadData() {
        guard let deviceInfo = self.session.crypto.device(withDeviceId: self.deviceId, ofUser: self.userId) else {
            self.update(viewState: .error(UserVerificationSessionStatusViewModelError.deviceNotFound))
            return
        }
        
        let isCurrentUser = self.session.myUser.userId == self.userId
        
        let viewData = SessionStatusViewData(userId: self.userId,
                                             userDisplayName: self.userDisplayName,
                                             isCurrentUser: isCurrentUser,
                                             deviceId: deviceInfo.deviceId,
                                             deviceName: deviceInfo.displayName ?? "",
                                             isDeviceTrusted: deviceInfo.trustLevel.isVerified)
        self.update(viewState: .loaded(viewData: viewData))
    }
    
    private func update(viewState: UserVerificationSessionStatusViewState) {
        self.viewDelegate?.userVerificationSessionStatusViewModel(self, didUpdateViewState: viewState)
    }
}
