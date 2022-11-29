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

import Combine
import MatrixSDK

class UserSessionsOverviewService: UserSessionsOverviewServiceProtocol {
    /// Delay after which session is considered inactive, 90 days
    private static let inactiveSessionDurationTreshold: TimeInterval = 90 * 86400
    
    private let dataProvider: UserSessionsDataProviderProtocol
    private var cancellables: Set<AnyCancellable> = []
    
    private(set) var overviewDataPublisher: CurrentValueSubject<UserSessionsOverviewData, Never>
    private var sessionInfos: [UserSessionInfo]
    
    init(dataProvider: UserSessionsDataProviderProtocol) {
        self.dataProvider = dataProvider
        
        overviewDataPublisher = .init(UserSessionsOverviewData(currentSession: nil,
                                                               unverifiedSessions: [],
                                                               inactiveSessions: [],
                                                               otherSessions: [],
                                                               linkDeviceEnabled: false))
        sessionInfos = []
        setupInitialOverviewData()
        listenForSessionUpdates()
    }
    
    // MARK: - Public
    
    func updateOverviewData(completion: @escaping (Result<UserSessionsOverviewData, Error>) -> Void) {
        dataProvider.devices { response in
            switch response {
            case .success(let devices):
                self.sessionInfos = self.sortedSessionInfos(from: devices)
                Task { @MainActor in
                    let linkDeviceEnabled = try? await self.dataProvider.qrLoginAvailable()
                    let overviewData = self.sessionsOverviewData(from: self.sessionInfos,
                                                                 linkDeviceEnabled: linkDeviceEnabled ?? false)
                    self.overviewDataPublisher.send(overviewData)
                    completion(.success(overviewData))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func sessionForIdentifier(_ sessionId: String) -> UserSessionInfo? {
        if currentSession?.id == sessionId {
            return currentSession
        }
        
        return otherSessions.first(where: { $0.id == sessionId })
    }

    // MARK: - Private
    
    private func listenForSessionUpdates() {
        NotificationCenter.default.publisher(for: .MXDeviceInfoTrustLevelDidChange)
            .sink { [weak self] _ in
                self?.updateOverviewData { _ in }
            }
            .store(in: &cancellables)
        NotificationCenter.default.publisher(for: .MXDeviceListDidUpdateUsersDevices)
            .sink { [weak self] _ in
                self?.updateOverviewData { _ in }
            }
            .store(in: &cancellables)
        NotificationCenter.default.publisher(for: .MXCrossSigningInfoTrustLevelDidChange)
            .sink { [weak self] _ in
                self?.updateOverviewData { _ in }
            }
            .store(in: &cancellables)
    }
    
    private func setupInitialOverviewData() {
        guard let currentSessionInfo = getCurrentSessionInfo() else {
            return
        }
        
        overviewDataPublisher = .init(UserSessionsOverviewData(currentSession: currentSessionInfo,
                                                               unverifiedSessions: currentSessionInfo.verificationState == .verified ? [] : [currentSessionInfo],
                                                               inactiveSessions: currentSessionInfo.isActive ? [] : [currentSessionInfo],
                                                               otherSessions: [],
                                                               linkDeviceEnabled: false))
    }
    
    private func getCurrentSessionInfo() -> UserSessionInfo? {
        guard let mainAccount = dataProvider.activeAccounts.first,
              let device = mainAccount.device else {
            return nil
        }
        return sessionInfo(from: device, isCurrentSession: true)
    }
    
    private func sortedSessionInfos(from devices: [MXDevice]) -> [UserSessionInfo] {
        devices
            .sorted { $0.lastSeenTs > $1.lastSeenTs }
            .map { sessionInfo(from: $0, isCurrentSession: $0.deviceId == dataProvider.myDeviceId) }
    }
    
    private func sessionsOverviewData(from allSessions: [UserSessionInfo],
                                      linkDeviceEnabled: Bool) -> UserSessionsOverviewData {
        UserSessionsOverviewData(currentSession: allSessions.filter(\.isCurrent).first,
                                 unverifiedSessions: allSessions.filter { $0.verificationState.isUnverified && !$0.isCurrent },
                                 inactiveSessions: allSessions.filter { !$0.isActive },
                                 otherSessions: allSessions.filter { !$0.isCurrent },
                                 linkDeviceEnabled: linkDeviceEnabled)
    }
    
    private func sessionInfo(from device: MXDevice, isCurrentSession: Bool) -> UserSessionInfo {
        let deviceInfo = deviceInfo(for: device.deviceId)
        let verificationState = dataProvider.verificationState(for: deviceInfo)

        let eventType = kMXAccountDataTypeClientInformation + "." + device.deviceId
        let appData = dataProvider.accountData(for: eventType)
        var userAgent: UserAgent?
        var isSessionActive = true

        if let lastSeenUserAgent = device.lastSeenUserAgent {
            userAgent = UserAgentParser.parse(lastSeenUserAgent)
        }

        if device.lastSeenTs > 0 {
            let elapsedTime = Date().timeIntervalSince1970 - TimeInterval(device.lastSeenTs / 1000)
            isSessionActive = elapsedTime < Self.inactiveSessionDurationTreshold
        }

        return UserSessionInfo(withDevice: device,
                               applicationData: appData as? [String: String],
                               userAgent: userAgent,
                               verificationState: verificationState,
                               isActive: isSessionActive,
                               isCurrent: isCurrentSession)
    }
    
    private func deviceInfo(for deviceId: String) -> MXDeviceInfo? {
        guard let userId = dataProvider.myUserId else {
            return nil
        }
        
        return dataProvider.device(withDeviceId: deviceId, ofUser: userId)
    }
}

extension UserSessionInfo {
    init(withDevice device: MXDevice,
         applicationData: [String: String]?,
         userAgent: UserAgent?,
         verificationState: VerificationState,
         isActive: Bool,
         isCurrent: Bool) {
        self.init(id: device.deviceId,
                  name: device.displayName,
                  deviceType: userAgent?.deviceType ?? .unknown,
                  verificationState: verificationState,
                  lastSeenIP: device.lastSeenIp,
                  lastSeenTimestamp: device.lastSeenTs > 0 ? TimeInterval(device.lastSeenTs / 1000) : nil,
                  applicationName: applicationData?["name"],
                  applicationVersion: applicationData?["version"],
                  applicationURL: applicationData?["url"],
                  deviceModel: userAgent?.deviceModel,
                  deviceOS: userAgent?.deviceOS,
                  lastSeenIPLocation: nil,
                  clientName: userAgent?.clientName,
                  clientVersion: userAgent?.clientVersion,
                  isActive: isActive,
                  isCurrent: isCurrent)
    }
}
