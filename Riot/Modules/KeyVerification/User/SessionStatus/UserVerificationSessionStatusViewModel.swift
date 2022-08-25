// File created from ScreenTemplate
// $ createScreen.sh SessionStatus UserVerificationSessionStatus
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
            loadData()
        case .verify:
            coordinatorDelegate?.userVerificationSessionStatusViewModel(self, wantsToVerifyDeviceWithId: deviceId, for: userId)
        case .verifyManually:
            coordinatorDelegate?.userVerificationSessionStatusViewModel(self, wantsToManuallyVerifyDeviceWithId: deviceId, for: userId)
        case .close:
            coordinatorDelegate?.userVerificationSessionStatusViewModelDidClose(self)
        }
    }
    
    // MARK: - Private
    
    private func loadData() {
        guard let deviceInfo = session.crypto.device(withDeviceId: deviceId, ofUser: userId) else {
            update(viewState: .error(UserVerificationSessionStatusViewModelError.deviceNotFound))
            return
        }
        
        let isCurrentUser = session.myUser.userId == userId
        
        let viewData = SessionStatusViewData(userId: userId,
                                             userDisplayName: userDisplayName,
                                             isCurrentUser: isCurrentUser,
                                             deviceId: deviceInfo.deviceId,
                                             deviceName: deviceInfo.displayName ?? "",
                                             isDeviceTrusted: deviceInfo.trustLevel.isVerified)
        update(viewState: .loaded(viewData: viewData))
    }
    
    private func update(viewState: UserVerificationSessionStatusViewState) {
        viewDelegate?.userVerificationSessionStatusViewModel(self, didUpdateViewState: viewState)
    }
}
