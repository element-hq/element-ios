// 
// Copyright 2022 New Vector Ltd
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

import Foundation
import MatrixSDK

class UserSessionsOverviewService: UserSessionsOverviewServiceProtocol {
    private let mxSession: MXSession
    
    private(set) var lastOverviewData: UserSessionsOverviewData
    
    init(mxSession: MXSession) {
        self.mxSession = mxSession
        
        lastOverviewData =  UserSessionsOverviewData(currentSessionInfo: nil,
                                                          unverifiedSessionsInfo: [],
                                                          inactiveSessionsInfo: [],
                                                          otherSessionsInfo: [])
        
        setupInitialOverviewData()
    }
    
    // MARK: - Public
    
    func fetchUserSessionsOverviewData(completion: @escaping (Result<UserSessionsOverviewData, Error>) -> Void) {
        mxSession.matrixRestClient.devices { response in
            switch response {
            case .success(let devices):
                self.lastOverviewData = self.userSessionsOverviewData(from: devices)
                completion(.success(self.lastOverviewData))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getOtherSession(sessionId: String) -> UserSessionInfo? {
        lastOverviewData.otherSessionsInfo.first(where: {$0.sessionId == sessionId})
    }
    
    // MARK: - Private
    
    private func setupInitialOverviewData() {
        let currentSessionInfo = getCurrentUserSessionInfoFromCache()
        
        lastOverviewData = UserSessionsOverviewData(currentSessionInfo: currentSessionInfo, unverifiedSessionsInfo: [], inactiveSessionsInfo: [], otherSessionsInfo: [])
    }
    
    private func getCurrentUserSessionInfoFromCache() -> UserSessionInfo? {
        guard let mainAccount = MXKAccountManager.shared().activeAccounts.first, let device = mainAccount.device else {
            return nil
        }
        return userSessionInfo(from: device)
    }
    
    private func userSessionInfo(from device: MXDevice) -> UserSessionInfo {
        let deviceInfo = getDeviceInfo(for: device.deviceId)
        
        let isSessionVerified = deviceInfo?.trustLevel.isVerified ?? false
        
        var lastSeenTs: TimeInterval?
        
        if device.lastSeenTs > 0 {
            lastSeenTs = TimeInterval(device.lastSeenTs / 1000)
        }
        
        return UserSessionInfo(sessionId: device.deviceId,
                               sessionName: device.displayName,
                               deviceType: .unknown,
                               isVerified: isSessionVerified,
                               lastSeenIP: device.lastSeenIp,
                               lastSeenTimestamp: lastSeenTs)
    }
    
    private func getDeviceInfo(for deviceId: String) -> MXDeviceInfo? {
        guard let userId = mxSession.myUserId else {
            return nil
        }
        
        return mxSession.crypto.device(withDeviceId: deviceId, ofUser: userId)
    }
    
    private func userSessionsOverviewData(from devices: [MXDevice]) -> UserSessionsOverviewData {
        let sortedDevices = devices.sorted { device1, device2 in
            device1.lastSeenTs > device2.lastSeenTs
        }
        
        let allUserSessionInfo = sortedDevices.map { device in
            return userSessionInfo(from: device)
        }
        
        var currentSessionInfo: UserSessionInfo?
        
        var unverifiedSessionsInfo: [UserSessionInfo] = []
        var inactiveSessionsInfo: [UserSessionInfo] = []
        var otherSessionsInfo: [UserSessionInfo] = []
        
        for userSessionInfo in allUserSessionInfo {
            if userSessionInfo.sessionId == mxSession.myDeviceId {
                currentSessionInfo = userSessionInfo
            } else {
                otherSessionsInfo.append(userSessionInfo)
                
                if userSessionInfo.isVerified == false {
                    unverifiedSessionsInfo.append(userSessionInfo)
                }
                
                if userSessionInfo.isSessionActive == false {
                    inactiveSessionsInfo.append(userSessionInfo)
                }
            }
        }
        
        return UserSessionsOverviewData(currentSessionInfo: currentSessionInfo,
                                        unverifiedSessionsInfo: unverifiedSessionsInfo,
                                        inactiveSessionsInfo: inactiveSessionsInfo,
                                        otherSessionsInfo: otherSessionsInfo)
    }
}
