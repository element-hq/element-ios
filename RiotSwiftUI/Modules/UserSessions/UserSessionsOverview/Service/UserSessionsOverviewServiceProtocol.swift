//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine

struct UserSessionsOverviewData {
    let currentSession: UserSessionInfo?
    let unverifiedSessions: [UserSessionInfo]
    let inactiveSessions: [UserSessionInfo]
    let otherSessions: [UserSessionInfo]
    let linkDeviceEnabled: Bool
}

protocol UserSessionsOverviewServiceProtocol {
    var overviewDataPublisher: CurrentValueSubject<UserSessionsOverviewData, Never> { get }
    
    func updateOverviewData(completion: @escaping (Result<UserSessionsOverviewData, Error>) -> Void) -> Void
    func sessionForIdentifier(_ sessionId: String) -> UserSessionInfo?
}

extension UserSessionsOverviewServiceProtocol {
    /// The user's current session.
    var currentSession: UserSessionInfo? { overviewDataPublisher.value.currentSession }
    /// Any sessions that are verified and have been seen recently.
    var otherSessions: [UserSessionInfo] { overviewDataPublisher.value.otherSessions }
}
