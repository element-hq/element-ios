// File created from ScreenTemplate
// $ createScreen.sh UserVerification UserVerificationSessionsStatus
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

enum UserVerificationSessionsStatusViewModelError: Error {
    case unknown
}

final class UserVerificationSessionsStatusViewModel: UserVerificationSessionsStatusViewModelType {
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    private let userId: String
    private var currentOperation: MXHTTPOperation?
    private var userTrustLevel: UserEncryptionTrustLevel
    
    // MARK: Public

    weak var viewDelegate: UserVerificationSessionsStatusViewModelViewDelegate?
    weak var coordinatorDelegate: UserVerificationSessionsStatusViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, userId: String) {
        self.session = session
        self.userId = userId
        userTrustLevel = .unknown
    }
    
    deinit {
        self.currentOperation?.cancel()
    }
    
    // MARK: - Public
    
    func process(viewAction: UserVerificationSessionsStatusViewAction) {
        switch viewAction {
        case .loadData:
            loadData()
        case .selectSession(deviceId: let deviceId):
            coordinatorDelegate?.userVerificationSessionsStatusViewModel(self, didSelectDeviceWithId: deviceId, for: userId)
        case .close:
            coordinatorDelegate?.userVerificationSessionsStatusViewModelDidClose(self)
        }
    }
    
    // MARK: - Private

    private func loadData() {
        let sessionsStatusViewData = getSessionStatusViewDataListFromCache(for: userId)
        update(viewState: .loaded(userTrustLevel: userTrustLevel, sessionsStatusViewData: sessionsStatusViewData))
        
        fetchSessionStatus()
    }
    
    private func update(viewState: UserVerificationSessionsStatusViewState) {
        viewDelegate?.userVerificationSessionsStatusViewModel(self, didUpdateViewState: viewState)
    }
    
    private func fetchSessionStatus() {
        update(viewState: .loading)
        
        currentOperation = getSessionStatusViewDataList(for: userId) { result in
            switch result {
            case .success(let sessionsStatusViewData):
                
                let isUserTrusted = sessionsStatusViewData.contains(where: { sessionsStatusViewData -> Bool in
                    sessionsStatusViewData.isTrusted == false
                }) == false
                
                let userTrustLevel: UserEncryptionTrustLevel = isUserTrusted ? .trusted : .warning
                
                self.update(viewState: .loaded(userTrustLevel: userTrustLevel, sessionsStatusViewData: sessionsStatusViewData))
            case .failure(let error):
                self.update(viewState: .error(error))
            }
        }
    }
    
    private func getSessionStatusViewDataListFromCache(for userId: String) -> [UserVerificationSessionStatusViewData] {
        let deviceInfoList = getDevicesFromCache(for: self.userId)
        return sessionStatusViewDataList(from: deviceInfoList)
    }
    
    private func getDevicesFromCache(for userId: String) -> [MXDeviceInfo] {
        guard let deviceInfoMap = session.crypto.devices(forUser: self.userId) else {
            return []
        }
        return Array(deviceInfoMap.values)
    }
    
    @discardableResult
    private func getSessionStatusViewDataList(for userId: String, completion: @escaping (Result<[UserVerificationSessionStatusViewData], Error>) -> Void) -> MXHTTPOperation? {
        let httpOperation: MXHTTPOperation?
        
        httpOperation = session.crypto.downloadKeys([self.userId], forceDownload: false, success: { (usersDeviceMap: MXUsersDevicesMap<MXDeviceInfo>?, _: [String: MXCrossSigningInfo]?) in
            
            let sessionsViewData: [UserVerificationSessionStatusViewData]
            
            if let usersDeviceMap = usersDeviceMap, let userDeviceInfoMap = Array(usersDeviceMap.map.values).first {
                let deviceInfoList = Array(userDeviceInfoMap.values)
                sessionsViewData = self.sessionStatusViewDataList(from: deviceInfoList)
            } else {
                sessionsViewData = []
            }
            
            completion(.success(sessionsViewData))
            
        }, failure: { error in
            
            let finalError = error ?? UserVerificationSessionsStatusViewModelError.unknown
            completion(.failure(finalError))
        })
        
        return httpOperation
    }
    
    private func sessionStatusViewData(from deviceInfo: MXDeviceInfo) -> UserVerificationSessionStatusViewData {
        UserVerificationSessionStatusViewData(deviceId: deviceInfo.deviceId, sessionName: deviceInfo.displayName ?? "", isTrusted: deviceInfo.trustLevel.isVerified)
    }
    
    private func sessionStatusViewDataList(from deviceInfoList: [MXDeviceInfo]) -> [UserVerificationSessionStatusViewData] {
        deviceInfoList.map { deviceInfo -> UserVerificationSessionStatusViewData in
            self.sessionStatusViewData(from: deviceInfo)
        }
    }
}
