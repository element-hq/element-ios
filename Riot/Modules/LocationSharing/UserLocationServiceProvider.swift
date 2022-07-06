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

/// UserLocationServiceProvider enables to automatically store UserLocationService per user id and retrieve existing UserLocationService.
/// Note: UserLocationService management is not set inside UserSessionsService at the moment to avoid to expose user location management to extension targets.
class UserLocationServiceProvider {
    
    // MARK: - Constants
    
    static let shared = UserLocationServiceProvider()
    
    // MARK: - Properties
    
    // UserLocationService per user id
    private var locationServices: [String: UserLocationServiceProtocol] = [:]
    
    // MARK: - Setup
    
    private init() {
        self.setupOrTeardownLocationServices()
        
        // Listen to lab flag changes
        self.registerRiotSettingsNotifications()
    }
    
    // MARK: - Public
    
    func locationService(for userId: String) -> UserLocationServiceProtocol? {
        return self.locationServices[userId]
    }
    
    // MARK: - Private
    
    // MARK: Store
    
    private func addLocationService(_ userLocationService: UserLocationServiceProtocol, for userId: String) {
        self.locationServices[userId] = userLocationService
    }
    
    private func removeLocationService(for userId: String) {
        self.locationServices[userId] = nil
    }
    
    // MARK: UserLocationService setup
    
    private func setupUserLocationService(for userSession: UserSession) {
        
        self.tearDownUserLocationService(for: userSession.userId)
        
        let userLocationService = UserLocationService(session: userSession.matrixSession)
        
        self.addLocationService(userLocationService, for: userSession.userId)
        
        userLocationService.start()
        
        MXLog.debug("Start monitoring user live location sharing")
    }
    
    private func setupUserLocationServiceIfNeeded(for userSession: UserSession) {
        
        // Be sure Matrix session has is store setup to access beacon info summaries
        guard userSession.matrixSession.state.rawValue >= MXSessionState.storeDataReady.rawValue else {
            return
        }
        
        let locationService =  self.locationService(for: userSession.userId)
        
        guard locationService == nil else {
            return
        }
        
        self.setupUserLocationService(for: userSession)
    }
    
    private func tearDownUserLocationService(for userId: String) {
        
        guard let locationService = self.locationService(for: userId) else {
            return
        }
        
        locationService.stop()
        
        self.removeLocationService(for: userId)

        MXLog.debug("Stop monitoring user live location sharing")
    }
    
    private func setupOrTeardownLocationServices() {
        
        self.unregisterUserSessionsServiceNotifications()
        
        if RiotSettings.shared.enableLiveLocationSharing {
            self.setupUserLocationServiceForAllUsers()
            self.registerUserSessionsServiceNotifications()
        } else {
            self.tearDownUserLocationServiceForAllUsers()
        }
    }
    
    private func setupUserLocationServiceForAllUsers() {
        for userSession in  UserSessionsService.shared.userSessions {
            self.setupUserLocationService(for: userSession)
        }
    }
    
    private func tearDownUserLocationServiceForAllUsers() {
        for (userId, _) in self.locationServices {
            self.tearDownUserLocationService(for: userId)
        }
    }
    
    // MARK: UserSessions management
    
    private func registerUserSessionsServiceNotifications() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(userSessionsServiceDidAddUserSession(_:)), name: UserSessionsService.didAddUserSession, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(userSessionsServiceDidUpdateUserSession(_:)), name: UserSessionsService.userSessionDidChange, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(userSessionsServiceDidRemoveUserSession(_:)), name: UserSessionsService.didRemoveUserSession, object: nil)
    }
    
    private func unregisterUserSessionsServiceNotifications() {
        
        NotificationCenter.default.removeObserver(self, name: UserSessionsService.didAddUserSession, object: nil)
        
        NotificationCenter.default.removeObserver(self, name: UserSessionsService.userSessionDidChange, object: nil)
        
        NotificationCenter.default.removeObserver(self, name: UserSessionsService.didRemoveUserSession, object: nil)
    }
    
    @objc private func userSessionsServiceDidAddUserSession(_ notification: Notification) {
        
        guard let userInfo = notification.userInfo, let userSession = userInfo[UserSessionsService.NotificationUserInfoKey.userSession] as? UserSession else {
            return
        }
        
        self.setupUserLocationServiceIfNeeded(for: userSession)
    }
    
    @objc private func userSessionsServiceDidUpdateUserSession(_ notification: Notification) {
        
        guard let userInfo = notification.userInfo, let userSession = userInfo[UserSessionsService.NotificationUserInfoKey.userSession] as? UserSession else {
            return
        }
        
        self.setupUserLocationServiceIfNeeded(for: userSession)
    }
    
    @objc private func userSessionsServiceDidRemoveUserSession(_ notification: Notification) {
        
        guard let userInfo = notification.userInfo, let userId = userInfo[UserSessionsService.NotificationUserInfoKey.userId] as? String else {
            return
        }
        
        self.tearDownUserLocationService(for: userId)
    }
    
    // MARK: - RiotSettings
    
    private func registerRiotSettingsNotifications() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(riotSettingsDidUpdateLiveLocationSharingActivation(_:)), name: RiotSettings.didUpdateLiveLocationSharingActivation, object: nil)
    }
    
    @objc private func riotSettingsDidUpdateLiveLocationSharingActivation(_ notification: Notification) {
        
        // Lab flag value has changed, check if we should enable or disable location services
        self.setupOrTeardownLocationServices()
    }
}
