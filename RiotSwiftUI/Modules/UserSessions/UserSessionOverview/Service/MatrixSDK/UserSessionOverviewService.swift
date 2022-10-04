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

class UserSessionOverviewService: UserSessionOverviewServiceProtocol {

    // MARK: - Members
    
    private(set) var pusherEnabledSubject: CurrentValueSubject<Bool?, Never>
    private(set) var remotelyTogglingPushersAvailableSubject: CurrentValueSubject<Bool, Never>

    // MARK: - Private
    
    private let session: MXSession
    private let sessionInfo: UserSessionInfo
    private var pusher: MXPusher?
    
    // MARK: - Setup
    
    init(session: MXSession, sessionInfo: UserSessionInfo) {
        self.session = session
        self.sessionInfo = sessionInfo
        self.pusherEnabledSubject = CurrentValueSubject(nil)
        self.remotelyTogglingPushersAvailableSubject = CurrentValueSubject(false)

        checkServerVersions { [weak self] in
            self?.checkPusher()
        }
    }
    
    // MARK: - UserSessionOverviewServiceProtocol
    
    func togglePushNotifications() {
        guard let pusher = pusher, let enabled = pusher.enabled?.boolValue, self.remotelyTogglingPushersAvailableSubject.value else {
            return
        }
        
        let data = pusher.data.jsonDictionary() as? [String: Any] ?? [:]
        
        self.session.matrixRestClient.setPusher(pushKey: pusher.pushkey,
                                                kind: MXPusherKind(value: pusher.kind),
                                                appId: pusher.appId,
                                                appDisplayName:pusher.appDisplayName,
                                                deviceDisplayName: pusher.deviceDisplayName,
                                                profileTag: pusher.profileTag ?? "",
                                                lang: pusher.lang,
                                                data: data,
                                                append: false,
                                                enabled: !enabled) { [weak self] response in
            guard let self = self else { return }
            
            switch response {
            case .success:
                self.checkPusher()
            case .failure(let error):
                MXLog.warning("[UserSessionOverviewService] togglePushNotifications failed due to error: \(error)")
                self.pusherEnabledSubject.send(enabled)
            }
        }
    }

    // MARK: - Private
    
    private func checkServerVersions(_ completion: @escaping () -> Void) {
        session.supportedMatrixVersions { [weak self] response in
            switch response {
            case .success(let versions):
                self?.remotelyTogglingPushersAvailableSubject.send(versions.supportsRemotelyTogglingPushNotifications)
            case .failure(let error):
                MXLog.warning("[UserSessionOverviewService] checkServerVersions failed due to error: \(error)")
            }
            completion()
        }
    }
    
    private func checkPusher() {
        session.matrixRestClient.pushers { [weak self] response in
            switch response {
            case .success(let pushers):
                self?.check(pushers: pushers)
            case .failure(let error):
                MXLog.warning("[UserSessionOverviewService] checkPusher failed due to error: \(error)")
            }
        }
    }
    
    private func check(pushers: [MXPusher]) {
        for pusher in pushers where pusher.deviceId == sessionInfo.id {
            self.pusher = pusher
            
            guard let enabled = pusher.enabled else {
                // For backwards compatibility, any pusher without an enabled field should be treated as if enabled is false
                pusherEnabledSubject.send(false)
                return
            }
            
            pusherEnabledSubject.send(enabled.boolValue)
        }
    }
}
