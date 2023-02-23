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
