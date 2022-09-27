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
    var overviewData: UserSessionsOverviewData
    
    func updateOverviewData(completion: @escaping (Result<UserSessionsOverviewData, Error>) -> Void) {
        completion(.success(overviewData))
    }
    
    func sessionForIdentifier(_ sessionId: String) -> UserSessionInfo? {
        nil
    }
    
    init() {
        overviewData = UserSessionsOverviewData(currentSession: Self.allSessions.filter(\.isCurrent).first,
                                                unverifiedSessions: Self.allSessions.filter { !$0.isVerified },
                                                inactiveSessions: Self.allSessions.filter { !$0.isActive },
                                                otherSessions: Self.allSessions.filter { !$0.isCurrent })
    }
    
    static var allSessions: [UserSessionInfo] = {
        [UserSessionInfo(id: "alice",
                         name: "iOS",
                         deviceType: .mobile,
                         isVerified: false,
                         lastSeenIP: "10.0.0.10",
                         lastSeenTimestamp: nil,
                         isActive: true,
                         isCurrent: true),
         UserSessionInfo(id: "1",
                         name: "macOS",
                         deviceType: .desktop,
                         isVerified: true,
                         lastSeenIP: "1.0.0.1",
                         lastSeenTimestamp: Date().timeIntervalSince1970 - 130_000,
                         isActive: false,
                         isCurrent: false),
         UserSessionInfo(id: "2",
                         name: "Firefox on Windows",
                         deviceType: .web,
                         isVerified: true,
                         lastSeenIP: "2.0.0.2",
                         lastSeenTimestamp: Date().timeIntervalSince1970 - 100,
                         isActive: true,
                         isCurrent: false),
         UserSessionInfo(id: "3",
                         name: "Android",
                         deviceType: .mobile,
                         isVerified: false,
                         lastSeenIP: "3.0.0.3",
                         lastSeenTimestamp: Date().timeIntervalSince1970 - 10,
                         isActive: true,
                         isCurrent: false)]
    }()
}
