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
    /// Delay after which session is considered inactive, 90 days
    private static let inactiveSessionDurationTreshold: TimeInterval = 90 * 86400
    
    private let mxSession: MXSession
    
    private(set) var overviewData: UserSessionsOverviewData
    
    init(mxSession: MXSession) {
        self.mxSession = mxSession
        
        overviewData = UserSessionsOverviewData(currentSession: nil,
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
        
        return overviewData.otherSessions.first(where: { $0.id == sessionId })
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
        return sessionInfo(from: device, isCurrentSession: true)
    }
    
    private func sessionsOverviewData(from devices: [MXDevice]) -> UserSessionsOverviewData {
        let allSessions = devices
            .sorted { $0.lastSeenTs > $1.lastSeenTs }
            .map { sessionInfo(from: $0, isCurrentSession: $0.deviceId == mxSession.myDeviceId) }
        
        return UserSessionsOverviewData(currentSession: allSessions.filter(\.isCurrent).first,
                                        unverifiedSessions: allSessions.filter { !$0.isVerified },
                                        inactiveSessions: allSessions.filter { !$0.isActive },
                                        otherSessions: allSessions.filter { !$0.isCurrent })
    }
    
    private func sessionInfo(from device: MXDevice, isCurrentSession: Bool) -> UserSessionInfo {
        let isSessionVerified = deviceInfo(for: device.deviceId)?.trustLevel.isVerified ?? false
        
        var lastSeenTs: TimeInterval?
        if device.lastSeenTs > 0 {
            lastSeenTs = TimeInterval(device.lastSeenTs / 1000)
        }
        
        var isSessionActive = true
        if let lastSeenTimestamp = lastSeenTs {
            let elapsedTime = Date().timeIntervalSince1970 - lastSeenTimestamp
            isSessionActive = elapsedTime < Self.inactiveSessionDurationTreshold
        }
        
        return UserSessionInfo(id: device.deviceId,
                               name: device.displayName,
                               deviceType: .unknown,
                               isVerified: isSessionVerified,
                               lastSeenIP: device.lastSeenIp,
                               lastSeenTimestamp: lastSeenTs,
                               isActive: isSessionActive,
                               isCurrent: isCurrentSession)
    }
    
    private func deviceInfo(for deviceId: String) -> MXDeviceInfo? {
        guard let userId = mxSession.myUserId else {
            return nil
        }
        
        return mxSession.crypto.device(withDeviceId: deviceId, ofUser: userId)
    }
}
