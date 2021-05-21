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
    
    private let customSchemeURLParser: CustomSchemeURLParser
  
    // MARK: Private
    
    private let rootRouter: RootRouterType
    // swiftlint:disable weak_delegate        
    private let legacyAppDelegate: LegacyAppDelegate = AppDelegate.theDelegate()
    // swiftlint:enable weak_delegate
    
    private weak var splitViewCoordinator: SplitViewCoordinatorType?
    
    private let userSessionsService: UserSessionsService
        
    /// Main user Matrix session
    private var mainMatrixSession: MXSession? {
        return self.userSessionsService.mainUserSession?.matrixSession
    }
  
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    // MARK: - Setup
    
    init(router: RootRouterType) {
        self.rootRouter = router
        self.customSchemeURLParser = CustomSchemeURLParser()
        self.userSessionsService = UserSessionsService()
    }
    
    // MARK: - Public methods
    
    func start() {
        // NOTE: When split view is shown there can be no Matrix sessions ready. Keep this behavior or use a loading screen before showing the spit view.
        self.showSplitView()
        NSLog("[AppCoordinator] Showed split view")
    }
    
    func open(url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        // NOTE: As said in the Apple documentation be careful on security issues with Custom Scheme URL (see https://developer.apple.com/documentation/xcode/allowing_apps_and_websites_to_link_to_your_content/defining_a_custom_url_scheme_for_your_app)
        
        do {
            let deepLinkOption = try self.customSchemeURLParser.parse(url: url, options: options)
            return self.handleDeepLinkOption(deepLinkOption)
        } catch {
            NSLog("[AppCoordinator] Custom scheme URL parsing failed with error: \(error)")
            return false
        }
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
    
    private func showSplitView() {
        let coordinatorParameters = SplitViewCoordinatorParameters(router: self.rootRouter, userSessionsService: self.userSessionsService)
                        
        let splitViewCoordinator = SplitViewCoordinator(parameters: coordinatorParameters)
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
    
    private func handleDeepLinkOption(_ deepLinkOption: DeepLinkOption) -> Bool {
        
        let canOpenLink: Bool
        
        switch deepLinkOption {
        case .connect(let loginToken, let transactionId):
            canOpenLink = self.legacyAppDelegate.continueSSOLogin(withToken: loginToken, txnId: transactionId)
        }
        
        return canOpenLink
    }
}

// MARK: - LegacyAppDelegateDelegate
extension AppCoordinator: LegacyAppDelegateDelegate {
            
    func legacyAppDelegate(_ legacyAppDelegate: LegacyAppDelegate!, wantsToPopToHomeViewControllerAnimated animated: Bool, completion: (() -> Void)!) {
        
        NSLog("[AppCoordinator] wantsToPopToHomeViewControllerAnimated")
        
        self.splitViewCoordinator?.popToHome(animated: animated, completion: completion)
    }
    
    func legacyAppDelegateRestoreEmptyDetailsViewController(_ legacyAppDelegate: LegacyAppDelegate!) {
        self.splitViewCoordinator?.restorePlaceholderDetails()
    }
    
    func legacyAppDelegate(_ legacyAppDelegate: LegacyAppDelegate!, didAddMatrixSession session: MXSession!) {
    }
    
    func legacyAppDelegate(_ legacyAppDelegate: LegacyAppDelegate!, didRemoveMatrixSession session: MXSession!) {
    }
    
    func legacyAppDelegate(_ legacyAppDelegate: LegacyAppDelegate!, didAdd account: MXKAccount!) {
        self.userSessionsService.addUserSession(fromAccount: account)
    }
    
    func legacyAppDelegate(_ legacyAppDelegate: LegacyAppDelegate!, didRemove account: MXKAccount!) {
        self.userSessionsService.removeUserSession(relatedToAccount: account)
    }
}

// MARK: - SplitViewCoordinatorDelegate
extension AppCoordinator: SplitViewCoordinatorDelegate {
    func splitViewCoordinatorDidCompleteAuthentication(_ coordinator: SplitViewCoordinatorType) {
        self.legacyAppDelegate.authenticationDidComplete()
    }
}
