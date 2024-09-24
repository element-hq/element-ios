// File created from ScreenTemplate
// $ createScreen.sh UserVerification UserVerificationSessionsStatus
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

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
        self.userTrustLevel = .unknown
    }
    
    deinit {
        self.currentOperation?.cancel()
    }
    
    // MARK: - Public
    
    func process(viewAction: UserVerificationSessionsStatusViewAction) {
        switch viewAction {
        case .loadData:
            self.loadData()
        case .selectSession(deviceId: let deviceId):
            self.coordinatorDelegate?.userVerificationSessionsStatusViewModel(self, didSelectDeviceWithId: deviceId, for: self.userId)
        case .close:
            self.coordinatorDelegate?.userVerificationSessionsStatusViewModelDidClose(self)
        }
    }
    
    // MARK: - Private

    private func loadData() {
        
        let sessionsStatusViewData = self.getSessionStatusViewDataListFromCache(for: self.userId)
        self.update(viewState: .loaded(userTrustLevel: self.userTrustLevel, sessionsStatusViewData: sessionsStatusViewData))
        
        self.fetchSessionStatus()
    }
    
    private func update(viewState: UserVerificationSessionsStatusViewState) {
        self.viewDelegate?.userVerificationSessionsStatusViewModel(self, didUpdateViewState: viewState)
    }
    
    private func fetchSessionStatus() {
        self.update(viewState: .loading)
        
        self.currentOperation = self.getSessionStatusViewDataList(for: self.userId) { result in
            switch result {
            case .success(let sessionsStatusViewData):
                
                let isUserTrusted = sessionsStatusViewData.contains(where: { sessionsStatusViewData -> Bool in
                    return sessionsStatusViewData.isTrusted == false
                }) == false
                
                let userTrustLevel: UserEncryptionTrustLevel = isUserTrusted ? .trusted : .warning
                
                self.update(viewState: .loaded(userTrustLevel: userTrustLevel, sessionsStatusViewData: sessionsStatusViewData))
            case .failure(let error):
                self.update(viewState: .error(error))
            }
        }
    }
    
    private func getSessionStatusViewDataListFromCache(for userId: String) -> [UserVerificationSessionStatusViewData] {
        let deviceInfoList = self.getDevicesFromCache(for: self.userId)
        return self.sessionStatusViewDataList(from: deviceInfoList)
    }
    
    private func getDevicesFromCache(for userId: String) -> [MXDeviceInfo] {
        guard let deviceInfoMap = self.session.crypto?.devices(forUser: self.userId) else {
            return []
        }
        return Array(deviceInfoMap.values)
    }
    
    @discardableResult
    private func getSessionStatusViewDataList(for userId: String, completion: @escaping (Result<[UserVerificationSessionStatusViewData], Error>) -> Void) -> MXHTTPOperation? {
        
        let httpOperation: MXHTTPOperation?
        
        httpOperation = self.session.crypto.downloadKeys([self.userId], forceDownload: false, success: { ( usersDeviceMap: MXUsersDevicesMap<MXDeviceInfo>?, usersCrossSigningMap: [String: MXCrossSigningInfo]?) in
            
            let sessionsViewData: [UserVerificationSessionStatusViewData]
            
            if let usersDeviceMap = usersDeviceMap, let userDeviceInfoMap = Array(usersDeviceMap.map.values).first {
                let deviceInfoList = Array(userDeviceInfoMap.values)
                sessionsViewData = self.sessionStatusViewDataList(from: deviceInfoList)
            } else {
                sessionsViewData = []
            }
            
            completion(.success(sessionsViewData))
            
        }, failure: { error in
            completion(.failure(error))
        })
        
        return httpOperation
    }
    
    private func sessionStatusViewData(from deviceInfo: MXDeviceInfo) -> UserVerificationSessionStatusViewData {
        return UserVerificationSessionStatusViewData(deviceId: deviceInfo.deviceId, sessionName: deviceInfo.displayName ?? "", isTrusted: deviceInfo.trustLevel.isVerified)
    }
    
    private func sessionStatusViewDataList(from deviceInfoList: [MXDeviceInfo]) -> [UserVerificationSessionStatusViewData] {
        return deviceInfoList.map { (deviceInfo) -> UserVerificationSessionStatusViewData in
            return self.sessionStatusViewData(from: deviceInfo)
        }
    }
}
