// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

// MARK: - UserSessionsService notification constants
extension UserSessionsService {
    public static let didAddUserSession = Notification.Name("UserSessionsServiceDidAddUserSession")
    public static let willRemoveUserSession = Notification.Name("UserSessionsServiceWillRemoveUserSession")
    public static let didRemoveUserSession = Notification.Name("UserSessionsServiceDidRemoveUserSession")
    public static let userSessionDidChange = Notification.Name("UserSessionsServiceUserSessionDidChange")
    
    public struct NotificationUserInfoKey {
        static let userSession = "userSession"
        static let userId = "userId"
    }
}

/// UserSessionsService enables to manage multiple user sessions and all logic around sessions management.
/// TODO: Move MXSession and MXKAccountManager code from LegacyAppDelegate to this place. Create a UserSessionService to make per session management if needed.
@objcMembers
class UserSessionsService: NSObject {
    
    // MARK: - Singleton
    
    static public let shared: UserSessionsService = UserSessionsService()
    
    // MARK: - Properties
    
    // MARK: Private
    
    private(set) var userSessions: [UserSession] = []
    private var accountManager: MXKAccountManager = MXKAccountManager.shared()
    
    // MARK: Public
    
    /// At the moment the main session is the first one added
    var mainUserSession: UserSession? {
        return self.userSessions.first
    }
    
    // MARK: - Setup
    
    override init() {
        super.init()
        
        for account in self.accountManager.accounts {
            self.addUserSession(fromAccount: account, postNotification: false)
        }
        
        self.registerAccountNotifications()
    }
    
    // MARK: - Public
    
    func addUserSession(fromAccount account: MXKAccount) {
        self.addUserSession(fromAccount: account, postNotification: true)
    }
    
    func removeUserSession(relatedToAccount account: MXKAccount) {
        self.removeUserSession(relatedToAccount: account, postNotification: true)
    }
    
    func removeUserSession(relatedToMatrixSession matrixSession: MXSession) {
        let foundUserSession = self.userSessions.first { (userSession) -> Bool in
            userSession.matrixSession == matrixSession
        }
        
        guard let userSessionToRemove = foundUserSession else {
            return
        }
        
        self.removeUserSession(relatedToAccount: userSessionToRemove.account)
    }
    
    func isUserSessionExists(withUserId userId: String) -> Bool {
        return self.userSessions.contains { (userSession) -> Bool in
            return userSession.userId == userId
        }
    }
    
    func userSession(withUserId userId: String) -> UserSession? {
        return self.userSessions.first { (userSession) -> Bool in
            return userSession.userId == userId
        }
    }
    
    // MARK: - Private
    
    @discardableResult
    private func addUserSession(fromAccount account: MXKAccount, postNotification: Bool) -> Bool {
        guard self.canAddAccount(account) else {
            return false
        }
        
        guard let matrixSession = account.mxSession else {
            return false
        }
        
        let userSession = UserSession(account: account, matrixSession: matrixSession)
        self.userSessions.append(userSession)
        
        MXLog.debug("[UserSessionsService] addUserSession from account with user id: \(userSession.userId)")
                
        if postNotification {
            NotificationCenter.default.post(name: UserSessionsService.didAddUserSession, object: self, userInfo: [NotificationUserInfoKey.userSession: userSession])
        }
        
        return true
    }
    
    private func removeUserSession(relatedToAccount account: MXKAccount, postNotification: Bool) {
        guard let userId = account.mxCredentials.userId, let userSession = self.userSession(withUserId: userId) else {
            return
        }
        
        if postNotification {
            NotificationCenter.default.post(name: UserSessionsService.willRemoveUserSession, object: self, userInfo: [NotificationUserInfoKey.userSession: userSession])
        }
        
        // Clear any stored user properties from this session.
        userSession.userProperties.delete()
        
        self.userSessions.removeAll { (userSession) -> Bool in
            return userId == userSession.userId
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
        if let account = self.accountManager.account(forUserId: userId), self.canAddAccount(account) {
            self.addUserSession(fromAccount: account)
        } else if let userSession = self.userSession(withUserId: userId) {
            NotificationCenter.default.post(name: UserSessionsService.userSessionDidChange, object: self, userInfo: [NotificationUserInfoKey.userSession: userSession])
        }
    }
}
