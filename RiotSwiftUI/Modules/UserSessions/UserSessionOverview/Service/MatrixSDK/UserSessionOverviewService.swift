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
    private var localNotificationSettings: [String: Any]?
    
    // MARK: - Setup
    
    init(session: MXSession, sessionInfo: UserSessionInfo) {
        self.session = session
        self.sessionInfo = sessionInfo
        pusherEnabledSubject = CurrentValueSubject(nil)
        remotelyTogglingPushersAvailableSubject = CurrentValueSubject(false)
        
        localNotificationSettings = session.accountData.localNotificationSettingsForDevice(withId: sessionInfo.id)
        
        if let localNotificationSettings = localNotificationSettings, let isSilenced = localNotificationSettings[kMXAccountDataIsSilencedKey] as? Bool {
            remotelyTogglingPushersAvailableSubject.send(true)
            pusherEnabledSubject.send(!isSilenced)
        } else {
            loadPushers { [weak self] pushers in
                guard let pusher = pushers.first(where: {$0.deviceId == sessionInfo.id}) else {
                    self?.pusherEnabledSubject.send(nil)
                    return
                }
                self?.pusher = pusher
                self?.checkIfRemotelyTogglingSupported { supported in
                    self?.remotelyTogglingPushersAvailableSubject.send(supported)
                    
                    if supported {
                        self?.pusherEnabledSubject.send(pusher.enabled?.boolValue ?? false)
                    } else {
                        self?.pusherEnabledSubject.send(nil)
                    }
                }
            }
        }
    }
    
    // MARK: - UserSessionOverviewServiceProtocol
    
    func togglePushNotifications() {
        guard let pusher = pusher, let enabled = pusher.enabled?.boolValue else {
            updateLocalNotification()
            return
        }

        toggle(pusher, enabled: !enabled)
    }

    // MARK: - Private
    
    private func toggle(_ pusher: MXPusher, enabled: Bool) {
        guard remotelyTogglingPushersAvailableSubject.value else {
            MXLog.warning("[UserSessionOverviewService] toggle pusher canceled: remotely toggling pushers not available")
            return
        }

        MXLog.debug("[UserSessionOverviewService] remotely toggling pusher")
        let data = pusher.data.jsonDictionary() as? [String: Any] ?? [:]
        
        session.matrixRestClient.setPusher(pushKey: pusher.pushkey,
                                           kind: MXPusherKind(value: pusher.kind),
                                           appId: pusher.appId,
                                           appDisplayName: pusher.appDisplayName,
                                           deviceDisplayName: pusher.deviceDisplayName,
                                           profileTag: pusher.profileTag ?? "",
                                           lang: pusher.lang,
                                           data: data,
                                           append: false,
                                           enabled: enabled) { [weak self] response in
            guard let self = self else { return }
            
            switch response {
            case .success:
                if let account = MXKAccountManager.shared().activeAccounts.first, account.device?.deviceId == pusher.deviceId {
                    account.loadCurrentPusher(nil)
                }
                
                self.loadPushers { [weak self] pushers in
                    guard let pusher = pushers.first(where: {$0.deviceId == self?.sessionInfo.id}) else {
                        self?.pusherEnabledSubject.send(nil)
                        return
                    }
                    self?.pusher = pusher
                    self?.pusherEnabledSubject.send(pusher.enabled?.boolValue ?? false)
                }
            case .failure(let error):
                MXLog.warning("[UserSessionOverviewService] togglePusher failed due to error: \(error)")
                self.pusherEnabledSubject.send(!enabled)
            }
        }
    }
    
    private func updateLocalNotification() {
        guard var localNotificationSettings = localNotificationSettings, let isSilenced = localNotificationSettings[kMXAccountDataIsSilencedKey] as? Bool else {
            MXLog.warning("[UserSessionOverviewService] updateLocalNotification canceled: \"\(kMXAccountDataIsSilencedKey)\" notification property not found")
            return
        }
        
        localNotificationSettings[kMXAccountDataIsSilencedKey] = !isSilenced
        session.setAccountData(localNotificationSettings, forType: MXAccountData.localNotificationSettingsKeyForDevice(withId: sessionInfo.id)) { [weak self] in
            self?.localNotificationSettings = localNotificationSettings
            self?.pusherEnabledSubject.send(isSilenced)
        } failure: { [weak self] error in
            MXLog.warning("[UserSessionOverviewService] updateLocalNotification failed due to error: \(String(describing: error))")
            self?.pusherEnabledSubject.send(!isSilenced)
        }
    }

    private func checkIfRemotelyTogglingSupported(completion: @escaping ((Bool) -> Void)) {
        session.supportedMatrixVersions { response in
            switch response {
            case .success(let versions):
                completion(versions.supportsRemotelyTogglingPushNotifications)
            case .failure(let error):
                MXLog.warning("[UserSessionOverviewService] checkServerVersions failed due to error: \(error)")
                completion(false)
            }
        }
    }
    
    private func loadPushers(_ completion: @escaping ([MXPusher]) -> Void) {
        session.matrixRestClient.pushers { response in
            switch response {
            case .success(let pushers):
                completion(pushers)
            case .failure(let error):
                MXLog.warning("[UserSessionOverviewService] checkPusher failed due to error: \(error)")
                completion([])
            }
        }
    }
}
