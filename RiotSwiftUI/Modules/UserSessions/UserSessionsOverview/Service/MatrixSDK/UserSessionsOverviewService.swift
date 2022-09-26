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
    
    private(set) var overviewData: UserSessionsOverviewData
    
    init(mxSession: MXSession) {
        self.mxSession = mxSession
        
        overviewData =  UserSessionsOverviewData(currentSession: nil,
                                                 unverifiedSessions: [],
                                                 inactiveSessions: [],
                                                 otherSessions: [])
        
        setupInitialOverviewData()
    }
    
    // MARK: - Public
    
    func updateOverviewData(completion: @escaping (Result<UserSessionsOverviewData, Error>) -> Void) {
        mxSession.matrixRestClient.devices { response in
            switch response {
            case .success(let devices):
                self.overviewData = self.sessionsOverviewData(from: devices)
                completion(.success(self.overviewData))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func sessionForIdentifier(_ sessionId: String) -> UserSessionInfo? {
        if overviewData.currentSession?.id == sessionId {
            return overviewData.currentSession
        }
        
        return overviewData.otherSessions.first(where: { $0.sessionId == sessionId })
    }
    
    // MARK: - Private
    
    private func setupInitialOverviewData() {
        let currentSessionInfo = currentSessionInfo()
        
        overviewData = UserSessionsOverviewData(currentSession: currentSessionInfo,
                                                unverifiedSessions: [],
                                                inactiveSessions: [],
                                                otherSessions: [])
    }
    
    private func currentSessionInfo() -> UserSessionInfo? {
        guard let mainAccount = MXKAccountManager.shared().activeAccounts.first,
              let device = mainAccount.device else {
            return nil
        }
        return sessionInfo(from: device)
    }
    
    private func sessionsOverviewData(from devices: [MXDevice]) -> UserSessionsOverviewData {
        let allSessions = devices
            .sorted { $0.lastSeenTs > $1.lastSeenTs }
            .map { sessionInfo(from: $0) }
        
        var currentSession: UserSessionInfo?
        var unverifiedSessions: [UserSessionInfo] = []
        var inactiveSessions: [UserSessionInfo] = []
        var otherSessions: [UserSessionInfo] = []
        
        for session in allSessions {
            guard session.sessionId != mxSession.myDeviceId else {
                currentSession = session
                continue
            }
            
            otherSessions.append(session)
            
            if session.isVerified == false {
                unverifiedSessions.append(session)
            }
            
            if session.isSessionActive == false {
                inactiveSessions.append(session)
            }
        }
        
        return UserSessionsOverviewData(currentSession: currentSession,
                                        unverifiedSessions: unverifiedSessions,
                                        inactiveSessions: inactiveSessions,
                                        otherSessions: otherSessions)
    }
    
    private func sessionInfo(from device: MXDevice) -> UserSessionInfo {
        let isSessionVerified = deviceInfo(for: device.deviceId)?.trustLevel.isVerified ?? false
        
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
    
    private func deviceInfo(for deviceId: String) -> MXDeviceInfo? {
        guard let userId = mxSession.myUserId else {
            return nil
        }
        
        return mxSession.crypto.device(withDeviceId: deviceId, ofUser: userId)
    }
}
