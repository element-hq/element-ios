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
import MatrixSDK
import CommonKit
import UIKit

#if DEBUG
import FLEX
#endif

/// The AppCoordinator is responsible of screen navigation and data injection at root application level. It decides
/// if authentication or home screen should be shown and inject data needed for these flows, it changes the navigation
/// stack on deep link, displays global warning.
/// This class should avoid to contain too many data management code not related to screen navigation logic. For example
/// `MXSession` or push notification management should be handled in dedicated classes and report only navigation
/// changes to the AppCoordinator.
final class AppCoordinator: NSObject, AppCoordinatorType {
    
    // MARK: - Constants
    
    // MARK: - Properties
    
    private let customSchemeURLParser: CustomSchemeURLParser
  
    // MARK: Private
    
    private let rootRouter: RootRouterType
    // swiftlint:disable weak_delegate
    fileprivate let legacyAppDelegate: LegacyAppDelegate = AppDelegate.theDelegate()
    // swiftlint:enable weak_delegate
    
    private lazy var appNavigator: AppNavigatorProtocol = {
        return AppNavigator(appCoordinator: self)
    }()
    
    fileprivate weak var splitViewCoordinator: SplitViewCoordinatorType?
    fileprivate weak var sideMenuCoordinator: SideMenuCoordinatorType?
    
    private let userSessionsService: UserSessionsService
        
    /// Main user Matrix session
    private var mainMatrixSession: MXSession? {
        return self.userSessionsService.mainUserSession?.matrixSession
    }
        
    private var currentSpaceId: String?
  
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    // MARK: - Setup
    
    init(router: RootRouterType, window: UIWindow) {
        self.rootRouter = router
        self.customSchemeURLParser = CustomSchemeURLParser()
        self.userSessionsService = UserSessionsService.shared
        
        super.init()
        
        setupFlexDebuggerOnWindow(window)
        update(with: ThemeService.shared().theme)
    }
    
    // MARK: - Public methods
    
    func start() {
        self.setupLogger()
        self.setupTheme()
        self.excludeAllItemsFromBackup()
        
        // Setup navigation router store
        _ = NavigationRouterStore.shared
        
        // Setup user location services
        _ = UserLocationServiceProvider.shared
        
        if BuildSettings.enableSideMenu {
            self.addSideMenu()
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.appDelegateNetworkStatusDidChange, object: nil, queue: OperationQueue.main) { [weak self] notification in
            guard let self = self else { return }

            if AppDelegate.theDelegate().isOffline {
                self.splitViewCoordinator?.showAppStateIndicator(with: VectorL10n.networkOfflineTitle, icon: UIImage(systemName: "wifi.slash"))
            } else {
                self.splitViewCoordinator?.hideAppStateIndicator()
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.newAppLayoutToggleDidChange(notification:)), name: RiotSettings.newAppLayoutBetaToggleDidChange, object: nil)
        
        // NOTE: When split view is shown there can be no Matrix sessions ready. Keep this behavior or use a loading screen before showing the split view.
        self.showSplitView()
        MXLog.debug("[AppCoordinator] Showed split view")
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.themeDidChange), name: Notification.Name.themeServiceDidChangeTheme, object: nil)
    }
    
    func open(url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        // NOTE: As said in the Apple documentation be careful on security issues with Custom Scheme URL:
        // https://developer.apple.com/documentation/xcode/allowing_apps_and_websites_to_link_to_your_content/defining_a_custom_url_scheme_for_your_app
        
        do {
            let deepLinkOption = try self.customSchemeURLParser.parse(url: url, options: options)
            return self.handleDeepLinkOption(deepLinkOption)
        } catch {
            MXLog.debug("[AppCoordinator] Custom scheme URL parsing failed with error: \(error)")
            return false
        }
    }
        
    // MARK: - Theme management
    
    @objc private func themeDidChange() {
        update(with: ThemeService.shared().theme)
    }
    
    private func update(with theme: Theme) {
        for window in UIApplication.shared.windows {
            window.overrideUserInterfaceStyle = ThemeService.shared().theme.userInterfaceStyle
        }
    }
    
    // MARK: - Private methods
    private func setupLogger() {
        UILog.configure(logger: MatrixSDKLogger.self)
    }
    
    private func setupTheme() {
        ThemeService.shared().themeId = RiotSettings.shared.userInterfaceTheme

        // Set theme id from current theme.identifier, themeId can be nil.
        if let themeId = ThemeIdentifier(rawValue: ThemeService.shared().theme.identifier) {
            ThemePublisher.configure(themeId: themeId)
        } else {
            MXLog.error("[AppCoordinator] No theme id found to update ThemePublisher")
        }
        
        // Always republish theme change events, and again always getting the identifier from the theme.
        let themeIdPublisher = NotificationCenter.default.publisher(for: Notification.Name.themeServiceDidChangeTheme)
            .compactMap({ _ in ThemeIdentifier(rawValue: ThemeService.shared().theme.identifier) })
            .eraseToAnyPublisher()

        ThemePublisher.shared.republish(themeIdPublisher: themeIdPublisher)
    }
    
    @objc private func newAppLayoutToggleDidChange(notification: Notification) {
        if BuildSettings.enableSideMenu {
            self.addSideMenu()
        }
    }
    
    private func excludeAllItemsFromBackup() {
        let manager = FileManager.default
        
        // Individual files and directories created by the application or SDK are excluded case-by-case,
        // but sometimes the lifecycle of a file is not directly controlled by the app (e.g. plists for
        // UserDefaults). For that reason the app will always exclude all top-level directories as well
        // as individual files.
        manager.excludeAllUserDirectoriesFromBackup()
        manager.excludeAllAppGroupDirectoriesFromBackup()
    }
    
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
        let coordinatorParameters = SplitViewCoordinatorParameters(router: self.rootRouter, userSessionsService: self.userSessionsService, appNavigator: self.appNavigator)
                        
        let splitViewCoordinator = SplitViewCoordinator(parameters: coordinatorParameters)
        splitViewCoordinator.delegate = self
        splitViewCoordinator.start()
        self.add(childCoordinator: splitViewCoordinator)
        self.splitViewCoordinator = splitViewCoordinator
    }
    
    private func addSideMenu() {
        let appInfo = AppInfo.current
        let coordinatorParameters = SideMenuCoordinatorParameters(appNavigator: self.appNavigator, userSessionsService: self.userSessionsService, appInfo: appInfo)
        
        let coordinator = SideMenuCoordinator(parameters: coordinatorParameters)
        coordinator.delegate = self
        coordinator.start()
        self.add(childCoordinator: coordinator)
        self.sideMenuCoordinator = coordinator
    }
    
    private func checkAppVersion() {
        // TODO: Implement
    }
    
    private func handleDeepLinkOption(_ deepLinkOption: DeepLinkOption) -> Bool {
        
        let canOpenLink: Bool
        
        switch deepLinkOption {
        case .connect(let loginToken, let transactionID):
            canOpenLink = AuthenticationService.shared.continueSSOLogin(with: loginToken, and: transactionID)
        }
        
        return canOpenLink
    }
    
    private func setupFlexDebuggerOnWindow(_ window: UIWindow) {
        #if DEBUG
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(showFlexDebugger))
        tapGestureRecognizer.numberOfTouchesRequired = 2
        tapGestureRecognizer.numberOfTapsRequired = 2
        window.addGestureRecognizer(tapGestureRecognizer)
        #endif
    }
    
    @objc private func showFlexDebugger() {
        #if DEBUG
        FLEXManager.shared.showExplorer()
        #endif
    }
    
    fileprivate func navigate(to destination: AppNavigatorDestination) {
        switch destination {
        case .homeSpace:
            MXLog.verbose("Switch to home space")
            self.navigateToSpace(with: nil)
            Analytics.shared.activeSpace = nil
        case .space(let spaceId):
            MXLog.verbose("Switch to space with id: \(spaceId)")
            self.navigateToSpace(with: spaceId)
            Analytics.shared.activeSpace = userSessionsService.mainUserSession?.matrixSession.spaceService.getSpace(withId: spaceId)
        }
    }
    
    private func navigateToSpace(with spaceId: String?) {
        guard spaceId != self.currentSpaceId else {
            MXLog.verbose("Space with id: \(String(describing: spaceId)) is already selected")
            return
        }
        
        self.currentSpaceId = spaceId
        
        // Reload split view with selected space id
        self.splitViewCoordinator?.start(with: spaceId)
    }
}

// MARK: - LegacyAppDelegateDelegate
extension AppCoordinator: LegacyAppDelegateDelegate {
            
    func legacyAppDelegate(_ legacyAppDelegate: LegacyAppDelegate!, wantsToPopToHomeViewControllerAnimated animated: Bool, completion: (() -> Void)!) {
        
        MXLog.debug("[AppCoordinator] wantsToPopToHomeViewControllerAnimated")
        
        self.splitViewCoordinator?.popToHome(animated: animated, completion: completion)
    }
    
    func legacyAppDelegateRestoreEmptyDetailsViewController(_ legacyAppDelegate: LegacyAppDelegate!) {
        self.splitViewCoordinator?.resetDetails(animated: false)
    }
    
    func legacyAppDelegate(_ legacyAppDelegate: LegacyAppDelegate!, didAddMatrixSession session: MXSession!) {
    }
    
    func legacyAppDelegate(_ legacyAppDelegate: LegacyAppDelegate!, didRemoveMatrixSession session: MXSession?) {
        guard let session = session else { return }
        // Handle user session removal on clear cache. On clear cache the account has his session closed but the account is not removed.
        self.userSessionsService.removeUserSession(relatedToMatrixSession: session)
    }
    
    func legacyAppDelegate(_ legacyAppDelegate: LegacyAppDelegate!, didAdd account: MXKAccount!) {
        self.userSessionsService.addUserSession(fromAccount: account)
    }
    
    func legacyAppDelegate(_ legacyAppDelegate: LegacyAppDelegate!, didRemove account: MXKAccount!) {
        self.userSessionsService.removeUserSession(relatedToAccount: account)
    }
    
    func legacyAppDelegate(_ legacyAppDelegate: LegacyAppDelegate!, didNavigateToSpaceWithId spaceId: String!) {
        self.sideMenuCoordinator?.select(spaceWithId: spaceId)
    }
}

// MARK: - SplitViewCoordinatorDelegate
extension AppCoordinator: SplitViewCoordinatorDelegate {
    func splitViewCoordinatorDidCompleteAuthentication(_ coordinator: SplitViewCoordinatorType) {
        self.legacyAppDelegate.authenticationDidComplete()
    }
}

// MARK: - SideMenuCoordinatorDelegate
extension AppCoordinator: SideMenuCoordinatorDelegate {
    func sideMenuCoordinator(_ coordinator: SideMenuCoordinatorType, didTapMenuItem menuItem: SideMenuItem, fromSourceView sourceView: UIView) {
    }
}

// MARK: - AppNavigator

// swiftlint:disable private_over_fileprivate
fileprivate class AppNavigator: AppNavigatorProtocol {
// swiftlint:enable private_over_fileprivate
    
    // MARK: - Properties
    
    private unowned let appCoordinator: AppCoordinator
    
    lazy var sideMenu: SideMenuPresentable = {
        guard let sideMenuCoordinator = appCoordinator.sideMenuCoordinator else {
            fatalError("sideMenuCoordinator is not initialized")
        }
        
        return SideMenuPresenter(sideMenuCoordinator: sideMenuCoordinator)
    }()

    // MARK: - Setup
    
    init(appCoordinator: AppCoordinator) {
        self.appCoordinator = appCoordinator
    }
    
    // MARK: - Public
    
    func navigate(to destination: AppNavigatorDestination) {
        self.appCoordinator.navigate(to: destination)
    }
}
