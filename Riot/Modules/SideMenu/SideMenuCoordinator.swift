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
import UIKit
import SideMenu
import SafariServices

class SideMenuCoordinatorParameters {
    let userSessionsService: UserSessionsService
    let appInfo: AppInfo
    
    init(userSessionsService: UserSessionsService, appInfo: AppInfo) {
        self.userSessionsService = userSessionsService
        self.appInfo = appInfo
    }
}

final class SideMenuCoordinator: SideMenuCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: SideMenuCoordinatorParameters
    private var sideMenuViewModel: SideMenuViewModelType
    
    private lazy var sideMenuNavigationViewController: SideMenuNavigationController = {
        return self.createSideMenuNavigationController(with: self.sideMenuViewController)
    }()
    
    private let sideMenuViewController: SideMenuViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: SideMenuCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(parameters: SideMenuCoordinatorParameters) {
        self.parameters = parameters
        
        let sideMenuViewModel = SideMenuViewModel(userSessionsService: self.parameters.userSessionsService, appInfo: parameters.appInfo)
        self.sideMenuViewController = SideMenuViewController.instantiate(with: sideMenuViewModel)
        self.sideMenuViewModel = sideMenuViewModel
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.sideMenuViewModel.coordinatorDelegate = self
        
        self.sideMenuNavigationViewController.sideMenuDelegate = self
        
        // Set the sideMenuNavigationViewController as default left menu
        SideMenuManager.default.leftMenuNavigationController = self.sideMenuNavigationViewController
    }
    
    func toPresentable() -> UIViewController {
        return self.sideMenuNavigationViewController
    }
    
    @discardableResult func addScreenEdgePanGesturesToPresent(to view: UIView) -> UIScreenEdgePanGestureRecognizer {
        return self.sideMenuNavigationViewController.sideMenuManager.addScreenEdgePanGesturesToPresent(toView: view, forMenu: .left)
    }
    
    @discardableResult func addPanGestureToPresent(to view: UIView) -> UIPanGestureRecognizer {
        return self.sideMenuNavigationViewController.sideMenuManager.addPanGestureToPresent(toView: view)
    }
    
    // MARK: - Private
    
    private func createSideMenuNavigationController(with rootViewController: UIViewController) -> SideMenuNavigationController {

        var sideMenuSettings = SideMenuSettings()
        sideMenuSettings.presentationStyle = .viewSlideOut
        
        let navigationController = SideMenuNavigationController(rootViewController: rootViewController, settings: sideMenuSettings)
                
        // Present side menu to the left
        navigationController.leftSide = true

        return navigationController
    }
    
    private func createSettingsViewController() -> SettingsViewController {
        let viewController: SettingsViewController = SettingsViewController.instantiate()
        viewController.loadViewIfNeeded()
        return viewController
    }
    
    private func showSettings() {
        let viewController = self.createSettingsViewController()
        
        // Push view controller and dismiss side menu
        self.sideMenuNavigationViewController.pushViewController(viewController, animated: true)
    }
    
    private func showBugReport() {
        let bugReportViewController = BugReportViewController()
        
        // Show in fullscreen to animate presentation along side menu dismiss
        bugReportViewController.modalPresentationStyle = .fullScreen
        bugReportViewController.modalTransitionStyle = .crossDissolve
        
        self.sideMenuNavigationViewController.present(bugReportViewController, animated: true)
    }
    
    private func showHelp() {
        guard let helpURL = URL(string: BuildSettings.applicationHelpUrlString) else {
            return
        }
        
        let safariViewController = SFSafariViewController(url: helpURL)
        
        // Show in fullscreen to animate presentation along side menu dismiss
        safariViewController.modalPresentationStyle = .fullScreen
        self.sideMenuNavigationViewController.present(safariViewController, animated: true, completion: nil)
    }
    
    private func showInviteFriends(from sourceView: UIView?) {
        let myUserId = self.parameters.userSessionsService.mainUserSession?.userId ?? ""
        
        let inviteFriendsPresenter = InviteFriendsPresenter()
        inviteFriendsPresenter.present(for: myUserId, from: self.sideMenuViewController, sourceView: sourceView, animated: true)
    }
}

// MARK: - SideMenuViewModelCoordinatorDelegate
extension SideMenuCoordinator: SideMenuViewModelCoordinatorDelegate {
    
    func sideMenuViewModel(_ viewModel: SideMenuViewModelType, didTapMenuItem menuItem: SideMenuItem, fromSourceView sourceView: UIView) {
        
        switch menuItem {
        case .inviteFriends:
            self.showInviteFriends(from: sourceView)
        case .settings:
            self.showSettings()
        case .help:
            self.showHelp()
        case .feedback:
            self.showBugReport()
        }
        
        self.delegate?.sideMenuCoordinator(self, didTapMenuItem: menuItem, fromSourceView: sourceView)
    }
}

// MARK: - SideMenuNavigationControllerDelegate
extension SideMenuCoordinator: SideMenuNavigationControllerDelegate {
 
    func sideMenuWillAppear(menu: SideMenuNavigationController, animated: Bool) {
    }
    
    func sideMenuDidAppear(menu: SideMenuNavigationController, animated: Bool) {
    }
    
    func sideMenuWillDisappear(menu: SideMenuNavigationController, animated: Bool) {
    }
    
    func sideMenuDidDisappear(menu: SideMenuNavigationController, animated: Bool) {
    }
}
