// File created from ScreenTemplate
// $ createScreen.sh DeviceVerification/Loading DeviceVerificationDataLoading
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

enum DeviceVerificationDataLoadingViewModelError: Error {
    case unknown
}

final class DeviceVerificationDataLoadingViewModel: DeviceVerificationDataLoadingViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    private let otherUserId: String
    private let otherDeviceId: String
    
    // MARK: Public

    weak var viewDelegate: DeviceVerificationDataLoadingViewModelViewDelegate?
    weak var coordinatorDelegate: DeviceVerificationDataLoadingViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, otherUserId: String, otherDeviceId: String) {
        self.session = session
        self.otherUserId = otherUserId
        self.otherDeviceId = otherDeviceId
    }
    
    deinit {
    }
    
    // MARK: - Public
    
    func process(viewAction: DeviceVerificationDataLoadingViewAction) {
        switch viewAction {
        case .loadData:
            self.loadData()
        case .cancel:
            self.coordinatorDelegate?.deviceVerificationDataLoadingViewModelDidCancel(self)
        }
    }
    
    // MARK: - Private

    private func loadData() {
        guard let crypto = self.session.crypto else {
            self.update(viewState: .errorMessage(VectorL10n.deviceVerificationErrorCannotLoadDevice))
            NSLog("[DeviceVerificationDataLoadingViewModel] Error session.crypto is nil")
            return
        }

        if let otherUser = self.session.user(withUserId: otherUserId) {
            
            self.update(viewState: .loading)
            
            crypto.downloadKeys([self.otherUserId], forceDownload: false, success: { [weak self] (usersDevicesMap) in
                guard let sself = self else {
                    return
                }

                if let otherDevice = usersDevicesMap?.object(forDevice: sself.otherDeviceId, forUser: sself.otherUserId) {
                    sself.update(viewState: .loaded)
                    sself.coordinatorDelegate?.deviceVerificationDataLoadingViewModel(sself, didLoadUser: otherUser, device: otherDevice)
                } else {
                     sself.update(viewState: .errorMessage(VectorL10n.deviceVerificationErrorCannotLoadDevice))
                }

            }, failure: { [weak self] (error) in
                guard let sself = self else {
                    return
                }
                
                let finalError = error ?? DeviceVerificationDataLoadingViewModelError.unknown
                
                sself.update(viewState: .error(finalError))
            })

        } else {
            self.update(viewState: .errorMessage(VectorL10n.deviceVerificationErrorCannotLoadDevice))
        }
    }
    
    private func update(viewState: DeviceVerificationDataLoadingViewState) {
        self.viewDelegate?.deviceVerificationDataLoadingViewModel(self, didUpdateViewState: viewState)
    }
}
