// File created from ScreenTemplate
// $ createScreen.sh DeviceVerification/Incoming DeviceVerificationIncoming
/*
 Copyright 2019 New Vector Ltd
 
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

final class DeviceVerificationIncomingViewModel: DeviceVerificationIncomingViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    private let transaction: MXIncomingSASTransaction
    
    // MARK: Public

    var userDisplayName: String
    var avatarUrl: String
    var deviceId: String

    var message: String?

    weak var viewDelegate: DeviceVerificationIncomingViewModelViewDelegate?
    weak var coordinatorDelegate: DeviceVerificationIncomingViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, otherUser: MXUser, transaction: MXIncomingSASTransaction) {
        self.session = session
        self.transaction = transaction
        self.message = nil
        self.userDisplayName = otherUser.displayname
        self.avatarUrl = otherUser.avatarUrl
        self.deviceId = transaction.otherDeviceId
    }
    
    deinit {
    }
    
    // MARK: - Public
    
    func process(viewAction: DeviceVerificationIncomingViewAction) {
        switch viewAction {
        case .sayHello:
            self.setupHelloMessage()
        case .complete:
            if let message = self.message {
            //self.coordinatorDelegate?.deviceVerificationIncomingViewModel(self, didCompleteWithMessage: message)
            }
        case .cancel:
            self.coordinatorDelegate?.deviceVerificationIncomingViewModelDidCancel(self)
        }
    }
    
    // MARK: - Private
    
    private func setupHelloMessage() {

        self.update(viewState: .loading)

        // Check first that the user homeserver is federated with the  Riot-bot homeserver
        self.session.matrixRestClient.displayName(forUser: self.session.myUser.userId) { [weak self]  (response) in

            guard let sself = self else {
                return
            }
            
            switch response {
            case .success:
                sself.message = "Hello \(response.value ?? "you")"
                sself.update(viewState: .loaded)
            case .failure(let error):
                sself.update(viewState: .error(error))
            }
        }
    }
    
    private func update(viewState: DeviceVerificationIncomingViewState) {
        self.viewDelegate?.deviceVerificationIncomingViewModel(self, didUpdateViewState: viewState)
    }
}
