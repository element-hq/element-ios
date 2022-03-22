// File created from ScreenTemplate
// $ createScreen.sh SideMenu SideMenu
/*
 Copyright 2020 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation

final class SideMenuViewModel: SideMenuViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private

    private let userSessionsService: UserSessionsService
    private let appInfo: AppInfo
    
    private var currentOperation: MXHTTPOperation?
    
    // MARK: Public

    weak var viewDelegate: SideMenuViewModelViewDelegate?
    weak var coordinatorDelegate: SideMenuViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(userSessionsService: UserSessionsService, appInfo: AppInfo) {
        self.userSessionsService = userSessionsService
        self.appInfo = appInfo
    }
    
    deinit {
        self.cancelOperations()        
    }
    
    // MARK: - Public
    
    func process(viewAction: SideMenuViewAction) {
        switch viewAction {
        case .loadData:
            self.loadData()
        case .tap(menuItem: let menuItem, sourceView: let sourceView):
            self.coordinatorDelegate?.sideMenuViewModel(self, didTapMenuItem: menuItem, fromSourceView: sourceView)
        case .tapHeader(sourceView: let sourceView):
            self.coordinatorDelegate?.sideMenuViewModel(self, didTapMenuItem: .settings, fromSourceView: sourceView)
        }
    }
    
    // MARK: - Private
    
    private func loadData() {

        self.update(viewState: .loading)

        guard let mainUserSession = self.userSessionsService.mainUserSession else {
            return
        }
        self.updateView(with: mainUserSession)
        
        self.registerUserSessionsServiceNotifications()
    }
    
    private func userAvatarViewData(from mxSession: MXSession) -> UserAvatarViewData? {
        guard let userId = mxSession.myUserId, let mediaManager = mxSession.mediaManager, let myUser = mxSession.myUser else {
            return nil
        }
        
        let userDisplayName = myUser.displayname
        let avatarUrl = myUser.avatarUrl
        
        return UserAvatarViewData(userId: userId,
                                  displayName: userDisplayName,
                                  avatarUrl: avatarUrl,
                                  mediaManager: mediaManager)
    }
    
    private func update(viewState: SideMenuViewState) {
        self.viewDelegate?.sideMenuViewModel(self, didUpdateViewState: viewState)
    }
    
    private func cancelOperations() {
        self.currentOperation?.cancel()
    }
    
    private func updateView(with userSession: UserSession) {
        guard let userAvatarViewData = self.userAvatarViewData(from: userSession.matrixSession) else {
            return
        }
        
        var sideMenuItems: [SideMenuItem] = []
        
        if BuildSettings.sideMenuShowInviteFriends {
            sideMenuItems += [.inviteFriends]
        }
        
        sideMenuItems += [
            .settings,
            .feedback
        ]
        
        // Hide app version
        let appVersion: String? = nil
        
        let viewData = SideMenuViewData(userAvatarViewData: userAvatarViewData, sideMenuItems: sideMenuItems, appVersion: appVersion)
        
        self.update(viewState: .loaded(viewData))
    }
    
    private func registerUserSessionsServiceNotifications() {
        
        // Listen only notifications from the current UserSessionsService instance
                
        NotificationCenter.default.addObserver(self, selector: #selector(userSessionDidChange(_:)), name: UserSessionsService.userSessionDidChange, object: self.userSessionsService)
    }
    
    @objc private func userSessionDidChange(_ notification: Notification) {
        guard let userSession = notification.userInfo?[UserSessionsService.NotificationUserInfoKey.userSession] as? UserSession else {
            return
        }
        
        // Main user session did change (maybe avatar or display name changed)
        if let mainUserSession =  self.userSessionsService.mainUserSession, mainUserSession.userId == userSession.userId {
            self.updateView(with: mainUserSession)
        }
    }
}
