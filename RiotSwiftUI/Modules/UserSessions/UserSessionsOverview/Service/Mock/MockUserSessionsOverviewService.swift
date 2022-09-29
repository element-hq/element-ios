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

class MockUserSessionsOverviewService: UserSessionsOverviewServiceProtocol {
    enum Mode {
        case currentSessionUnverified
        case currentSessionVerified
        case onlyUnverifiedSessions
        case onlyInactiveSessions
        case noOtherSessions
    }
    
    private let mode: Mode
    
    var overviewData: UserSessionsOverviewData
    
    init(mode: Mode = .currentSessionUnverified) {
        self.mode = mode
        
        overviewData = UserSessionsOverviewData(currentSession: nil,
                                                unverifiedSessions: [],
                                                inactiveSessions: [],
                                                otherSessions: [])
    }
    
    func updateOverviewData(completion: @escaping (Result<UserSessionsOverviewData, Error>) -> Void) {
        let unverifiedSessions = buildSessions(verified: false, active: true)
        let inactiveSessions = buildSessions(verified: true, active: false)
        
        switch mode {
        case .noOtherSessions:
            overviewData = UserSessionsOverviewData(currentSession: currentSession,
                                                    unverifiedSessions: [],
                                                    inactiveSessions: [],
                                                    otherSessions: [])
        case .onlyUnverifiedSessions:
            overviewData = UserSessionsOverviewData(currentSession: currentSession,
                                                    unverifiedSessions: unverifiedSessions + [currentSession],
                                                    inactiveSessions: [],
                                                    otherSessions: unverifiedSessions)
        case .onlyInactiveSessions:
            overviewData = UserSessionsOverviewData(currentSession: currentSession,
                                                    unverifiedSessions: [],
                                                    inactiveSessions: inactiveSessions,
                                                    otherSessions: inactiveSessions)
        default:
            let otherSessions = unverifiedSessions + inactiveSessions + buildSessions(verified: true, active: true)
            
            overviewData = UserSessionsOverviewData(currentSession: currentSession,
                                                    unverifiedSessions: unverifiedSessions,
                                                    inactiveSessions: inactiveSessions,
                                                    otherSessions: otherSessions)
        }
        
        completion(.success(overviewData))
    }
    
    func sessionForIdentifier(_ sessionId: String) -> UserSessionInfo? {
        overviewData.otherSessions.first { $0.id == sessionId }
    }

    // MARK: - Private
    
    private var currentSession: UserSessionInfo {
        UserSessionInfo(id: "alice",
                        name: "iOS",
                        deviceType: .mobile,
                        isVerified: mode == .currentSessionVerified,
                        lastSeenIP: "10.0.0.10",
                        lastSeenTimestamp: nil,
                        applicationName: "Element iOS",
                        applicationVersion: "1.0.0",
                        applicationURL: nil,
                        deviceModel: nil,
                        deviceOS: "iOS 15.5",
                        lastSeenIPLocation: nil,
                        deviceName: "My iPhone",
                        isActive: true,
                        isCurrent: true)
    }
    
    private func buildSessions(verified: Bool, active: Bool) -> [UserSessionInfo] {
        [UserSessionInfo(id: "1 verified: \(verified) active: \(active)",
                         name: "macOS verified: \(verified) active: \(active)",
                         deviceType: .desktop,
                         isVerified: verified,
                         lastSeenIP: "1.0.0.1",
                         lastSeenTimestamp: Date().timeIntervalSince1970 - 130_000,
                         applicationName: "Element MacOS",
                         applicationVersion: "1.0.0",
                         applicationURL: nil,
                         deviceModel: nil,
                         deviceOS: "macOS 12.5.1",
                         lastSeenIPLocation: nil,
                         deviceName: "My Mac",
                         isActive: active,
                         isCurrent: false),
         UserSessionInfo(id: "2 verified: \(verified) active: \(active)",
                         name: "Firefox on Windows verified: \(verified) active: \(active)",
                         deviceType: .web,
                         isVerified: verified,
                         lastSeenIP: "2.0.0.2",
                         lastSeenTimestamp: Date().timeIntervalSince1970 - 100,
                         applicationName: "Element Web",
                         applicationVersion: "1.0.0",
                         applicationURL: nil,
                         deviceModel: nil,
                         deviceOS: "Windows 10",
                         lastSeenIPLocation: nil,
                         deviceName: "My Windows",
                         isActive: active,
                         isCurrent: false),
         UserSessionInfo(id: "3 verified: \(verified) active: \(active)",
                         name: "Android verified: \(verified) active: \(active)",
                         deviceType: .mobile,
                         isVerified: verified,
                         lastSeenIP: "3.0.0.3",
                         lastSeenTimestamp: Date().timeIntervalSince1970 - 10,
                         applicationName: "Element Android",
                         applicationVersion: "1.0.0",
                         applicationURL: nil,
                         deviceModel: nil,
                         deviceOS: "Android 4.0",
                         lastSeenIPLocation: nil,
                         deviceName: "My Phone",
                         isActive: active,
                         isCurrent: false)]
    }
}
