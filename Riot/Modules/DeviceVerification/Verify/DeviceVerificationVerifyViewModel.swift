// File created from ScreenTemplate
// $ createScreen.sh DeviceVerification/Verify DeviceVerificationVerify
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

final class DeviceVerificationVerifyViewModel: DeviceVerificationVerifyViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    private let transaction: MXSASTransaction
    
    // MARK: Public

    weak var viewDelegate: DeviceVerificationVerifyViewModelViewDelegate?
    weak var coordinatorDelegate: DeviceVerificationVerifyViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, transaction: MXSASTransaction) {
        self.session = session
        self.transaction = transaction
    }
    
    deinit {
    }
    
    // MARK: - Public
    
    func process(viewAction: DeviceVerificationVerifyViewAction) {
        switch viewAction {
        case .confirm:
            self.confirm()
        case .complete:
            self.coordinatorDelegate?.deviceVerificationVerifyViewModelDidComplete(self)
        case .cancel:
            self.coordinatorDelegate?.deviceVerificationVerifyViewModelDidCancel(self)
        }
    }
    
    // MARK: - Private
    
    private func confirm() {
        self.update(viewState: .loading)

        // TODO
    }
    
    private func update(viewState: DeviceVerificationVerifyViewState) {
        self.viewDelegate?.deviceVerificationVerifyViewModel(self, didUpdateViewState: viewState)
    }
}
