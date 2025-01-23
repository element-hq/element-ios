//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine

class MockUserSessionsOverviewService: UserSessionsOverviewServiceProtocol {
    enum Mode {
        case currentSessionUnverified
        case currentSessionVerified
        case onlyUnverifiedSessions
        case onlyInactiveSessions
        case noOtherSessions
    }
    
    private let mode: Mode
    
    var overviewDataPublisher: CurrentValueSubject<UserSessionsOverviewData, Never>
    var sessionInfos = [UserSessionInfo]()
    
    init(mode: Mode = .currentSessionUnverified) {
        self.mode = mode
        
        overviewDataPublisher = .init(UserSessionsOverviewData(currentSession: nil,
                                                               unverifiedSessions: [],
                                                               inactiveSessions: [],
                                                               otherSessions: [],
                                                               linkDeviceEnabled: false))
    }
    
    func updateOverviewData(completion: @escaping (Result<UserSessionsOverviewData, Error>) -> Void) {
        let unverifiedSessions = buildSessions(verified: false, active: true)
        let inactiveSessions = buildSessions(verified: true, active: false)
        
        switch mode {
        case .noOtherSessions:
            overviewDataPublisher.send(UserSessionsOverviewData(currentSession: mockCurrentSession,
                                                                unverifiedSessions: [],
                                                                inactiveSessions: [],
                                                                otherSessions: [],
                                                                linkDeviceEnabled: false))
        case .onlyUnverifiedSessions:
            overviewDataPublisher.send(UserSessionsOverviewData(currentSession: mockCurrentSession,
                                                                unverifiedSessions: unverifiedSessions + [mockCurrentSession],
                                                                inactiveSessions: [],
                                                                otherSessions: unverifiedSessions,
                                                                linkDeviceEnabled: false))
        case .onlyInactiveSessions:
            overviewDataPublisher.send(UserSessionsOverviewData(currentSession: mockCurrentSession,
                                                                unverifiedSessions: [],
                                                                inactiveSessions: inactiveSessions,
                                                                otherSessions: inactiveSessions,
                                                                linkDeviceEnabled: false))
        default:
            let otherSessions = unverifiedSessions + inactiveSessions + buildSessions(verified: true, active: true)
            
            overviewDataPublisher.send(UserSessionsOverviewData(currentSession: mockCurrentSession,
                                                                unverifiedSessions: unverifiedSessions,
                                                                inactiveSessions: inactiveSessions,
                                                                otherSessions: otherSessions,
                                                                linkDeviceEnabled: true))
        }
        
        completion(.success(overviewDataPublisher.value))
    }
    
    func sessionForIdentifier(_ sessionId: String) -> UserSessionInfo? {
        otherSessions.first { $0.id == sessionId }
    }
    
    // MARK: - Private
    
    private var mockCurrentSession: UserSessionInfo {
        UserSessionInfo(id: "alice",
                        name: "iOS",
                        deviceType: .mobile,
                        verificationState: mode == .currentSessionVerified ? .verified : .unverified,
                        lastSeenIP: "10.0.0.10",
                        lastSeenTimestamp: nil,
                        applicationName: "Element iOS",
                        applicationVersion: "1.0.0",
                        applicationURL: nil,
                        deviceModel: nil,
                        deviceOS: "iOS 15.5",
                        lastSeenIPLocation: nil,
                        clientName: "Element",
                        clientVersion: "1.0.0",
                        isActive: true,
                        isCurrent: true)
    }
    
    private func buildSessions(verified: Bool, active: Bool) -> [UserSessionInfo] {
        [UserSessionInfo(id: "1 verified: \(verified) active: \(active)",
                         name: "macOS verified: \(verified) active: \(active)",
                         deviceType: .desktop,
                         verificationState: verified ? .verified : .unverified,
                         lastSeenIP: "1.0.0.1",
                         lastSeenTimestamp: Date().timeIntervalSince1970 - 8_000_000,
                         applicationName: "Element MacOS",
                         applicationVersion: "1.0.0",
                         applicationURL: nil,
                         deviceModel: nil,
                         deviceOS: "macOS",
                         lastSeenIPLocation: nil,
                         clientName: "Electron",
                         clientVersion: "20.0.0",
                         isActive: active,
                         isCurrent: false),
         UserSessionInfo(id: "2 verified: \(verified) active: \(active)",
                         name: "Firefox on Windows verified: \(verified) active: \(active)",
                         deviceType: .web,
                         verificationState: verified ? .verified : .unverified,
                         lastSeenIP: "2.0.0.2",
                         lastSeenTimestamp: Date().timeIntervalSince1970 - 100,
                         applicationName: "Element Web",
                         applicationVersion: "1.0.0",
                         applicationURL: nil,
                         deviceModel: nil,
                         deviceOS: "Windows",
                         lastSeenIPLocation: nil,
                         clientName: "Firefox",
                         clientVersion: "39.0",
                         isActive: active,
                         isCurrent: false),
         UserSessionInfo(id: "3 verified: \(verified) active: \(active)",
                         name: "Android verified: \(verified) active: \(active)",
                         deviceType: .mobile,
                         verificationState: verified ? .verified : .unverified,
                         lastSeenIP: "3.0.0.3",
                         lastSeenTimestamp: Date().timeIntervalSince1970 - 10,
                         applicationName: "Element Android",
                         applicationVersion: "1.0.0",
                         applicationURL: nil,
                         deviceModel: nil,
                         deviceOS: "Android 4.0",
                         lastSeenIPLocation: nil,
                         clientName: "Element",
                         clientVersion: "1.0.0",
                         isActive: active,
                         isCurrent: false)]
    }
}
