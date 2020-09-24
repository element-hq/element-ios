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

/// The AppCoordinator is responsible of screen navigation and data injection at root application level. It decides if authentication or home screen should be shown and inject data needed for these flows, it changes the navigation stack on deep link, displays global warning.
/// This class should avoid to contain too many data management code not related to screen navigation logic. For example `MXSession` or push notification management should be handled in dedicated classes and report only navigation changes to the AppCoordinator.
final class AppCoordinator: NSObject, AppCoordinatorType {
    
    // MARK: - Constants
    
    // MARK: - Properties
  
    // MARK: Private
    
    private let rootRouter: RootRouterType
    // swiftlint:disable weak_delegate        
    private let legacyAppDelegate: LegacyAppDelegate = AppDelegate.theDelegate()
    // swiftlint:enable weak_delegate
    
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
    
    private func showAuthentication() {
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
        splitViewCoordinator.delegate = self
        splitViewCoordinator.start()
        self.add(childCoordinator: splitViewCoordinator)
        self.splitViewCoordinator = splitViewCoordinator
    }
    
    private func checkAppVersion() {
        // TODO: Implement
    }
    
    private func showError(_ error: Error) {
        // FIXME: Present an error on coordinator.toPresentable()
        self.legacyAppDelegate.showError(asAlert: error)
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

// MARK: - SplitViewCoordinatorDelegate
extension AppCoordinator: SplitViewCoordinatorDelegate {
    func splitViewCoordinatorDidCompleteAuthentication(_ coordinator: SplitViewCoordinatorType) {
        self.legacyAppDelegate.authenticationDidComplete()
    }
}
