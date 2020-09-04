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
import Intents

final class AppCoordinator: NSObject, AppCoordinatorType {
    
    // MARK: - Constants
    
    // MARK: - Properties
  
    // MARK: Private
    
    private let rootRouter: RootRouterType
    
    private weak var splitViewCoordinator: SplitViewCoordinatorType?
    
    // TODO: Use a dedicated class to handle Matrix sessions
    /// Main user Matrix session
    private var mainSession: MXSession? {
        return MXKAccountManager.shared().activeAccounts.first?.mxSession
    }
  
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    // MARK: - Setup
    
    init(router: RootRouterType) {
        self.rootRouter = router
    }
    
    // MARK: - Public methods
    
    func start() {
        self.showSplitView(session: self.mainSession)
    }
        
    // MARK: - Private methods
    
    private func showLogin() {
        // TODO: Implement
    }
    
    private func showLoading() {
        // TODO: Implement
    }
    
    private func showPinCode() {
        // TODO: Implement
    }
    
    private func showSplitView(session: MXSession?) {
        let splitViewCoordinator = SplitViewCoordinator(router: self.rootRouter, session: session)
        splitViewCoordinator.start()
        self.add(childCoordinator: splitViewCoordinator)
        self.splitViewCoordinator = splitViewCoordinator
    }
    
    private func checkAppVersion() {
        // TODO: Implement
    }
    
    private func showError(_ error: Error) {
        // FIXME: Present an error on coordinator.toPresentable()
        AppDelegate.theDelegate().showError(asAlert: error)
    }
}

// MARK: - LegacyAppDelegateDelegate
extension AppCoordinator: LegacyAppDelegateDelegate {
            
    func legacyAppDelegate(_ legacyAppDelegate: LegacyAppDelegate!, wantsToPopToHomeViewControllerAnimated animated: Bool, completion: (() -> Void)!) {
        
        self.splitViewCoordinator?.popToHome(animated: animated, completion: completion)
    }
    
    func legacyAppDelegateRestoreEmptyDetailsViewController(_ legacyAppDelegate: LegacyAppDelegate!) {
        self.splitViewCoordinator?.restorePlaceholderDetails()
    }
}
