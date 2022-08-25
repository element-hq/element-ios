//
// Copyright 2021 New Vector Ltd
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

// MARK: - UserSessionsService notification constants

public extension UserSessionsService {
    static let didAddUserSession = Notification.Name("UserSessionsServiceDidAddUserSession")
    static let willRemoveUserSession = Notification.Name("UserSessionsServiceWillRemoveUserSession")
    static let didRemoveUserSession = Notification.Name("UserSessionsServiceDidRemoveUserSession")
    static let userSessionDidChange = Notification.Name("UserSessionsServiceUserSessionDidChange")
    
    enum NotificationUserInfoKey {
        static let userSession = "userSession"
        static let userId = "userId"
    }
}

/// UserSessionsService enables to manage multiple user sessions and all logic around sessions management.
/// TODO: Move MXSession and MXKAccountManager code from LegacyAppDelegate to this place. Create a UserSessionService to make per session management if needed.
@objcMembers
class UserSessionsService: NSObject {
    // MARK: - Singleton
    
    public static let shared = UserSessionsService()
    
    // MARK: - Properties
    
    // MARK: Private
    
    private(set) var userSessions: [UserSession] = []
    private var accountManager = MXKAccountManager.shared()
    
    // MARK: Public
    
    /// At the moment the main session is the first one added
    var mainUserSession: UserSession? {
        self.userSessions.first
    }
    
    // MARK: - Setup
    
    override init() {
        super.init()
        
        for account in accountManager.accounts {
            addUserSession(fromAccount: account, postNotification: false)
        }
        
        registerAccountNotifications()
    }
    
    // MARK: - Public
    
    func addUserSession(fromAccount account: MXKAccount) {
        addUserSession(fromAccount: account, postNotification: true)
    }
    
    func removeUserSession(relatedToAccount account: MXKAccount) {
        removeUserSession(relatedToAccount: account, postNotification: true)
    }
    
    func removeUserSession(relatedToMatrixSession matrixSession: MXSession) {
        let foundUserSession = userSessions.first { userSession -> Bool in
            userSession.matrixSession == matrixSession
        }
        
        guard let userSessionToRemove = foundUserSession else {
            return
        }
        
        removeUserSession(relatedToAccount: userSessionToRemove.account)
    }
    
    func isUserSessionExists(withUserId userId: String) -> Bool {
        userSessions.contains { userSession -> Bool in
            userSession.userId == userId
        }
    }
    
    func userSession(withUserId userId: String) -> UserSession? {
        userSessions.first { userSession -> Bool in
            userSession.userId == userId
        }
    }
    
    // MARK: - Private
    
    @discardableResult
    private func addUserSession(fromAccount account: MXKAccount, postNotification: Bool) -> Bool {
        guard canAddAccount(account) else {
            return false
        }
        
        guard let matrixSession = account.mxSession else {
            return false
        }
        
        let userSession = UserSession(account: account, matrixSession: matrixSession)
        userSessions.append(userSession)
        
        MXLog.debug("[UserSessionsService] addUserSession from account with user id: \(userSession.userId)")
                
        if postNotification {
            NotificationCenter.default.post(name: UserSessionsService.didAddUserSession, object: self, userInfo: [NotificationUserInfoKey.userSession: userSession])
        }
        
        return true
    }
    
    private func removeUserSession(relatedToAccount account: MXKAccount, postNotification: Bool) {
        guard let userId = account.mxCredentials.userId, let userSession = userSession(withUserId: userId) else {
            return
        }
        
        if postNotification {
            NotificationCenter.default.post(name: UserSessionsService.willRemoveUserSession, object: self, userInfo: [NotificationUserInfoKey.userSession: userSession])
        }
        
        // Clear any stored user properties from this session.
        userSession.userProperties.delete()
        
        userSessions.removeAll { userSession -> Bool in
            userId == userSession.userId
        }
        
        MXLog.debug("[UserSessionsService] removeUserSession related to account with user id: \(userId)")
        
        if postNotification {
            NotificationCenter.default.post(name: UserSessionsService.didRemoveUserSession, object: self, userInfo: [NotificationUserInfoKey.userId: userId])
        }
    }
    
    private func canAddAccount(_ account: MXKAccount) -> Bool {
        guard let userId = account.mxCredentials.userId, !self.isUserSessionExists(withUserId: userId) else {
            return false
        }
        
        guard let mxSession = account.mxSession else {
            MXLog.debug("[UserSessionsService] Cannot add a UserSession from a MXKAccount with nil Matrix session")
            return false
        }
        
        let isSessionStateValid: Bool
        
        switch mxSession.state {
        case .closed:
            isSessionStateValid = false
        default:
            isSessionStateValid = true
        }
        
        return isSessionStateValid
    }
    
    private func registerAccountNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(accountDidChange(_:)), name: .mxkAccountUserInfoDidChange, object: nil)
    }
    
    @objc private func accountDidChange(_ notification: Notification) {
        guard let userId = notification.object as? String else {
            return
        }
        
        // Wait before MXKAccount.mxSession is set before adding a UserSession with the associated account
        if let account = accountManager.account(forUserId: userId), canAddAccount(account) {
            addUserSession(fromAccount: account)
        } else if let userSession = userSession(withUserId: userId) {
            NotificationCenter.default.post(name: UserSessionsService.userSessionDidChange, object: self, userInfo: [NotificationUserInfoKey.userSession: userSession])
        }
    }
}
