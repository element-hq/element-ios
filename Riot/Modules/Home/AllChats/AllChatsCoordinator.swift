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
import CommonKit

/// AllChatsCoordinator input parameters
class AllChatsCoordinatorParameters {
    
    let userSessionsService: UserSessionsService
    let appNavigator: AppNavigatorProtocol
    
    init(userSessionsService: UserSessionsService, appNavigator: AppNavigatorProtocol) {
        self.userSessionsService = userSessionsService
        self.appNavigator = appNavigator
    }
}

class AllChatsCoordinator: NSObject, SplitViewMasterCoordinatorProtocol {
    
    // MARK: Properties
    
    // MARK: Private
    
    private let parameters: AllChatsCoordinatorParameters
    private let activityIndicatorPresenter: ActivityIndicatorPresenterType
    private let indicatorPresenter: UserIndicatorTypePresenterProtocol
    private let userIndicatorStore: UserIndicatorStore
    private var appStateIndicatorCancel: UserIndicatorCancel?
    private var appSateIndicator: UserIndicator?

    // Indicate if the Coordinator has started once
    private var hasStartedOnce: Bool {
        return self.allChatsViewController != nil
    }
    
    // TODO: Move MasterTabBarController navigation code here
    private var allChatsViewController: AllChatsViewController!

    // TODO: Embed UINavigationController in each tab like recommended by Apple and remove these properties. UITabBarViewController shoud not be embed in a UINavigationController (https://github.com/vector-im/riot-ios/issues/3086).
    private let navigationRouter: NavigationRouterType
    
    private var currentSpaceId: String?
    
    private weak var versionCheckCoordinator: VersionCheckCoordinator?
    
    private var currentMatrixSession: MXSession? {
        return parameters.userSessionsService.mainUserSession?.matrixSession
    }
    
    private var isAllChatsControllerTopMostController: Bool {
        return self.navigationRouter.modules.last is AllChatsViewController
    }
    
    private var detailUserIndicatorPresenter: UserIndicatorTypePresenterProtocol {
        guard let presenter = splitViewMasterPresentableDelegate?.detailUserIndicatorPresenter else {
            MXLog.debug("[AllChatsCoordinator]: Missing defautl user indicator presenter")
            return UserIndicatorTypePresenter(presentingViewController: toPresentable())
        }
        return presenter
    }
    
    private var indicators = [UserIndicator]()
    private var signOutAlertPresenter = SignOutAlertPresenter()
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: SplitViewMasterCoordinatorDelegate?
    
    weak var splitViewMasterPresentableDelegate: SplitViewMasterPresentableDelegate?
    
    // MARK: - Setup
        
    init(parameters: AllChatsCoordinatorParameters) {
        self.parameters = parameters
        
        let masterNavigationController = RiotNavigationController()
        self.navigationRouter = NavigationRouter(navigationController: masterNavigationController)
        self.activityIndicatorPresenter = ActivityIndicatorPresenter()
        self.indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: masterNavigationController)
        self.userIndicatorStore = UserIndicatorStore(presenter: indicatorPresenter)
    }
    
    // MARK: - Public methods
    
    func start() {
        self.start(with: nil)
    }
        
    func start(with spaceId: String?) {
                
        // If start has been done once do not setup view controllers again
        if self.hasStartedOnce == false {
            signOutAlertPresenter.delegate = self
            
            let allChatsViewController = AllChatsViewController.instantiate()
            allChatsViewController.allChatsDelegate = self
            allChatsViewController.userIndicatorStore = UserIndicatorStore(presenter: indicatorPresenter)
            createLeftButtonItem(for: allChatsViewController)
            self.allChatsViewController = allChatsViewController
            self.navigationRouter.setRootModule(allChatsViewController)
            
            // Add existing Matrix sessions if any
            for userSession in self.parameters.userSessionsService.userSessions {
                self.addMatrixSessionToAllChatsController(userSession.matrixSession)
            }
            
            self.registerUserSessionsServiceNotifications()
            self.registerSessionChange()
            
            let versionCheckCoordinator = createVersionCheckCoordinator(withRootViewController: allChatsViewController, bannerPresentrer: allChatsViewController)
            versionCheckCoordinator.start()
            self.add(childCoordinator: versionCheckCoordinator)
        }
        
        self.allChatsViewController?.switchSpace(withId: spaceId)
        
        self.currentSpaceId = spaceId
    }
    
    func toPresentable() -> UIViewController {
        return self.navigationRouter.toPresentable()
    }
    
    func releaseSelectedItems() {
        self.allChatsViewController.releaseSelectedItem()
    }
    
    func popToHome(animated: Bool, completion: (() -> Void)?) {
        
        // Force back to the main screen if this is not the one that is displayed
        if allChatsViewController != self.navigationRouter.modules.last?.toPresentable() {
            
            // Listen to the masterNavigationController changes
            // We need to be sure that allChatsViewController is back to the screen
            
            // If the AllChatsViewController is not visible because there is a modal above it
            // but still the top view controller of navigation controller
            if self.isAllChatsControllerTopMostController {
                completion?()
            } else {
                // Otherwise AllChatsViewController is not the top controller of the navigation controller
                
                // Waiting for `self.navigationRouter` popping to AllChatsViewController
                var token: NSObjectProtocol?
                token = NotificationCenter.default.addObserver(forName: NavigationRouter.didPopModule, object: self.navigationRouter, queue: OperationQueue.main) { [weak self] (notification) in
                    
                    guard let self = self else {
                        return
                    }
                    
                    // If AllChatsViewController is now the top most controller in navigation controller stack call the completion
                    if self.isAllChatsControllerTopMostController {
                        
                        completion?()
                        
                        if let token = token {
                            NotificationCenter.default.removeObserver(token)
                        }
                    }
                }
                
                // Pop to root view controller
                self.navigationRouter.popToRootModule(animated: animated)
            }
        } else {
            // the AllChatsViewController is already visible
            completion?()
        }
    }
    
    func showErroIndicator(with error: Error) {
        let error = error as NSError
        
        // Ignore fake error, or connection cancellation error
        guard error.domain != NSURLErrorDomain || error.code != NSURLErrorCancelled else {
            return
        }
        
        // Ignore GDPR Consent not given error. Already caught by kMXHTTPClientUserConsentNotGivenErrorNotification observation
        let mxError = MXError.isMXError(error) ? MXError(nsError: error) : nil
        guard mxError?.errcode != kMXErrCodeStringConsentNotGiven else {
            return
        }
        
        let msg = error.userInfo[NSLocalizedFailureReasonErrorKey] as? String
        let localizedDescription = error.userInfo[NSLocalizedDescriptionKey] as? String
        let title = (error.userInfo[NSLocalizedFailureReasonErrorKey] as? String) ?? (msg ?? (localizedDescription ?? VectorL10n.error))
        
        indicators.append(self.indicatorPresenter.present(.failure(label: title)))
    }
    
    func showAppStateIndicator(with text: String, icon: UIImage?) {
        hideAppStateIndicator()
        appSateIndicator = self.indicatorPresenter.present(.custom(label: text, icon: icon))
    }
    
    func hideAppStateIndicator() {
        appSateIndicator?.cancel()
        appSateIndicator = nil
    }
    
    // MARK: - SplitViewMasterPresentable
    
    var selectedNavigationRouter: NavigationRouterType? {
        return self.navigationRouter
    }
    
    // MARK: Split view
    
    /// If the split view is collapsed (one column visible) it will push the Presentable on the primary navigation controller, otherwise it will show the Presentable as the secondary view of the split view.
    private func replaceSplitViewDetails(with presentable: Presentable, popCompletion: (() -> Void)? = nil) {
        self.splitViewMasterPresentableDelegate?.splitViewMasterPresentable(self, wantsToReplaceDetailWith: presentable, popCompletion: popCompletion)
    }
    
    /// If the split view is collapsed (one column visible) it will push the Presentable on the primary navigation controller, otherwise it will show the Presentable as the secondary view of the split view on top of existing views.
    private func stackSplitViewDetails(with presentable: Presentable, popCompletion: (() -> Void)? = nil) {
        self.splitViewMasterPresentableDelegate?.splitViewMasterPresentable(self, wantsToStack: presentable, popCompletion: popCompletion)
    }
    
    private func showSplitViewDetails(with presentable: Presentable, stackedOnSplitViewDetail: Bool, popCompletion: (() -> Void)? = nil) {
        
        if stackedOnSplitViewDetail {
            self.stackSplitViewDetails(with: presentable, popCompletion: popCompletion)
        } else {
            self.replaceSplitViewDetails(with: presentable, popCompletion: popCompletion)
        }
    }
    
    private func showSplitViewDetails(with modules: [NavigationModule], stack: Bool) {
        if stack {
            self.splitViewMasterPresentableDelegate?.splitViewMasterPresentable(self, wantsToStack: modules)
        } else {
            self.splitViewMasterPresentableDelegate?.splitViewMasterPresentable(self, wantsToReplaceDetailsWith: modules)
        }
    }
    
    private func resetSplitViewDetails() {
        self.splitViewMasterPresentableDelegate?.splitViewMasterPresentableWantsToResetDetail(self)
    }
    
    // MARK: UserSessions management
    
    private func registerUserSessionsServiceNotifications() {
        
        // Listen only notifications from the current UserSessionsService instance
        let userSessionService = self.parameters.userSessionsService
        
        NotificationCenter.default.addObserver(self, selector: #selector(userSessionsServiceDidAddUserSession(_:)), name: UserSessionsService.didAddUserSession, object: userSessionService)
        
        NotificationCenter.default.addObserver(self, selector: #selector(userSessionsServiceWillRemoveUserSession(_:)), name: UserSessionsService.willRemoveUserSession, object: userSessionService)
    }
    
    @objc private func userSessionsServiceDidAddUserSession(_ notification: Notification) {
        guard let userSession = notification.userInfo?[UserSessionsService.NotificationUserInfoKey.userSession] as? UserSession else {
            return
        }
        
        self.addMatrixSessionToAllChatsController(userSession.matrixSession)
    }
    
    @objc private func userSessionsServiceWillRemoveUserSession(_ notification: Notification) {
        guard let userSession = notification.userInfo?[UserSessionsService.NotificationUserInfoKey.userSession] as? UserSession else {
            return
        }
        
        self.removeMatrixSessionFromAllChatsController(userSession.matrixSession)
    }
    
    // MARK: - Matrix Session management
    
    // TODO: Remove Matrix session handling from the view controller
    private func addMatrixSessionToAllChatsController(_ matrixSession: MXSession) {
        MXLog.debug("[TabBarCoordinator] masterTabBarController.addMatrixSession")
        self.allChatsViewController.addMatrixSession(matrixSession)
    }
    
    // TODO: Remove Matrix session handling from the view controller
    private func removeMatrixSessionFromAllChatsController(_ matrixSession: MXSession) {
        MXLog.debug("[TabBarCoordinator] masterTabBarController.removeMatrixSession")
        self.allChatsViewController.removeMatrixSession(matrixSession)
    }
    
    private func registerSessionChange() {
        NotificationCenter.default.addObserver(self, selector: #selector(sessionDidSync(_:)), name: NSNotification.Name.mxSessionDidSync, object: nil)
    }
    
    @objc private func sessionDidSync(_ notification: Notification) {
        updateAvatarButtonItem()
    }
    
    // MARK: Navigation
    
    private func showSettings() {
        let viewController = self.createSettingsViewController()
        
        self.navigationRouter.push(viewController, animated: true, popCompletion: nil)
    }
    
    private func showContactDetails(with contact: MXKContact, presentationParameters: ScreenPresentationParameters) {
        
        let coordinatorParameters = ContactDetailsCoordinatorParameters(contact: contact)
        let coordinator = ContactDetailsCoordinator(parameters: coordinatorParameters)
        coordinator.start()
        self.add(childCoordinator: coordinator)
        
        self.showSplitViewDetails(with: coordinator, stackedOnSplitViewDetail: presentationParameters.stackAboveVisibleViews) { [weak self] in
            self?.remove(childCoordinator: coordinator)
        }
    }
    
    // MARK: Navigation bar items management
    
    private weak var avatarMenuView: AvatarView?
    private weak var avatarMenuButton: UIButton?

    private func createLeftButtonItem(for viewController: UIViewController) {
        createAvatarButtonItem(for: viewController)
    }

    private func createAvatarButtonItem(for viewController: UIViewController) {
        var actions: [UIMenuElement] = []
        
        actions.append(UIAction(title: VectorL10n.allChatsUserMenuSettings, image: UIImage(systemName: "gearshape")) { [weak self] action in
            self?.showSettings()
        })
        
        var subMenuActions: [UIAction] = []
        if BuildSettings.sideMenuShowInviteFriends {
            subMenuActions.append(UIAction(title: VectorL10n.sideMenuActionInviteFriends, image: UIImage(systemName: "square.and.arrow.up.fill")) { [weak self] action in
                guard let self = self else { return }
                self.showInviteFriends(from: self.avatarMenuButton)
            })
        }

        subMenuActions.append(UIAction(title: VectorL10n.sideMenuActionFeedback, image: UIImage(systemName: "questionmark.circle")) { [weak self] action in
            self?.showBugReport()
        })
        
        actions.append(UIMenu(title: "", options: .displayInline, children: subMenuActions))
        actions.append(UIMenu(title: "", options: .displayInline, children: [
            UIAction(title: VectorL10n.settingsSignOut, image: UIImage(systemName: "rectangle.portrait.and.arrow.right.fill"), attributes: .destructive) { [weak self] action in
                self?.signOut()
            }
        ]))

        let menu = UIMenu(options: .displayInline, children: actions)
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 36, height: 36))
        view.backgroundColor = .clear
        
        let button: UIButton = UIButton(frame: view.bounds.inset(by: UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)))
        button.setImage(Asset.Images.tabPeople.image, for: .normal)
        button.menu = menu
        button.showsMenuAsPrimaryAction = true
        button.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        view.addSubview(button)
        self.avatarMenuButton = button

        let avatarView = UserAvatarView(frame: view.bounds.inset(by: UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)))
        avatarView.isUserInteractionEnabled = false
        avatarView.update(theme: ThemeService.shared().theme)
        avatarView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        view.addSubview(avatarView)
        self.avatarMenuView = avatarView

        if let avatar = userAvatarViewData(from: currentMatrixSession) {
            avatarView.fill(with: avatar)
            button.setImage(nil, for: .normal)
        }
        
        viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: view)
    }
    
    private func updateAvatarButtonItem() {
        guard let avatarView = avatarMenuView, let button = avatarMenuButton, let avatar = userAvatarViewData(from: currentMatrixSession) else {
            return
        }
        
        button.setImage(nil, for: .normal)
        avatarView.fill(with: avatar)
    }
    
    private func showRoom(withId roomId: String, eventId: String? = nil) {
        
        guard let matrixSession = self.parameters.userSessionsService.mainUserSession?.matrixSession else {
            return
        }
        
        self.showRoom(with: roomId, eventId: eventId, matrixSession: matrixSession)
    }
    
    private func showRoom(withNavigationParameters roomNavigationParameters: RoomNavigationParameters, completion: (() -> Void)?) {
        
        if let threadParameters = roomNavigationParameters.threadParameters, threadParameters.stackRoomScreen {
            showRoomAndThread(with: roomNavigationParameters,
                              completion: completion)
        } else {
            let threadId = roomNavigationParameters.threadParameters?.threadId
            let displayConfig: RoomDisplayConfiguration
            if threadId != nil {
                displayConfig = .forThreads
            } else {
                displayConfig = .default
            }
            
            
            let roomCoordinatorParameters = RoomCoordinatorParameters(navigationRouterStore: NavigationRouterStore.shared,
                                                                      userIndicatorPresenter: detailUserIndicatorPresenter,
                                                                      session: roomNavigationParameters.mxSession,
                                                                      parentSpaceId: self.currentSpaceId,
                                                                      roomId: roomNavigationParameters.roomId,
                                                                      eventId: roomNavigationParameters.eventId,
                                                                      threadId: threadId,
                                                                      userId: roomNavigationParameters.userId,
                                                                      showSettingsInitially: roomNavigationParameters.showSettingsInitially,
                                                                      displayConfiguration: displayConfig,
                                                                      autoJoinInvitedRoom: roomNavigationParameters.autoJoinInvitedRoom)
            
            self.showRoom(with: roomCoordinatorParameters,
                          stackOnSplitViewDetail: roomNavigationParameters.presentationParameters.stackAboveVisibleViews,
                          completion: completion)
        }
    }
        
    private func showRoom(with roomId: String, eventId: String?, matrixSession: MXSession, completion: (() -> Void)? = nil) {
        
        // RoomCoordinator will be presented by the split view.
        // As we don't know which navigation controller instance will be used,
        // give the NavigationRouterStore instance and let it find the associated navigation controller
        let roomCoordinatorParameters = RoomCoordinatorParameters(navigationRouterStore: NavigationRouterStore.shared,
                                                                  userIndicatorPresenter: detailUserIndicatorPresenter,
                                                                  session: matrixSession,
                                                                  parentSpaceId: self.currentSpaceId,
                                                                  roomId: roomId,
                                                                  eventId: eventId,
                                                                  showSettingsInitially: false)
        
        self.showRoom(with: roomCoordinatorParameters, completion: completion)
    }
    
    private func showRoomPreview(with previewData: RoomPreviewData) {
                
        // RoomCoordinator will be presented by the split view
        // We don't which navigation controller instance will be used
        // Give the NavigationRouterStore instance and let it find the associated navigation controller if needed
        let roomCoordinatorParameters = RoomCoordinatorParameters(navigationRouterStore: NavigationRouterStore.shared,
                                                                  userIndicatorPresenter: detailUserIndicatorPresenter,
                                                                  parentSpaceId: self.currentSpaceId,
                                                                  previewData: previewData)
        
        self.showRoom(with: roomCoordinatorParameters)
    }
    
    private func showRoomPreview(withNavigationParameters roomPreviewNavigationParameters: RoomPreviewNavigationParameters, completion: (() -> Void)?) {
        
        let roomCoordinatorParameters = RoomCoordinatorParameters(navigationRouterStore: NavigationRouterStore.shared,
                                                                  userIndicatorPresenter: detailUserIndicatorPresenter,
                                                                  parentSpaceId: self.currentSpaceId,
                                                                  previewData: roomPreviewNavigationParameters.previewData)
        
        self.showRoom(with: roomCoordinatorParameters,
                      stackOnSplitViewDetail: roomPreviewNavigationParameters.presentationParameters.stackAboveVisibleViews,
                      completion: completion)
    }
    
    private func showRoom(with parameters: RoomCoordinatorParameters,
                          stackOnSplitViewDetail: Bool = false,
                          completion: (() -> Void)? = nil) {
        
        //  try to find the desired room screen in the stack
        if let roomCoordinator = self.splitViewMasterPresentableDelegate?.detailModules.last(where: { presentable in
            guard let roomCoordinator = presentable as? RoomCoordinatorProtocol else {
                return false
            }
            return roomCoordinator.roomId == parameters.roomId
                && roomCoordinator.threadId == parameters.threadId
                && roomCoordinator.mxSession == parameters.session
        }) as? RoomCoordinatorProtocol {
            self.splitViewMasterPresentableDelegate?.splitViewMasterPresentable(self, wantsToPopTo: roomCoordinator)
            //  go to a specific event if provided
            if let eventId = parameters.eventId {
                roomCoordinator.start(withEventId: eventId, completion: completion)
            } else {
                completion?()
            }
            return
        }
                        
        let coordinator = RoomCoordinator(parameters: parameters)
        coordinator.delegate = self
        coordinator.start(withCompletion: completion)
        self.add(childCoordinator: coordinator)
        
        self.showSplitViewDetails(with: coordinator, stackedOnSplitViewDetail: stackOnSplitViewDetail) { [weak self] in
            // NOTE: The RoomDataSource releasing is handled in SplitViewCoordinator
            self?.remove(childCoordinator: coordinator)
        }
    }

    private func showRoomAndThread(with roomNavigationParameters: RoomNavigationParameters,
                                   completion: (() -> Void)? = nil) {
        self.activityIndicatorPresenter.presentActivityIndicator(on: toPresentable().view, animated: false)
        let dispatchGroup = DispatchGroup()

        //  create room coordinator
        let roomCoordinatorParameters = RoomCoordinatorParameters(navigationRouterStore: NavigationRouterStore.shared,
                                                                  userIndicatorPresenter: detailUserIndicatorPresenter,
                                                                  session: roomNavigationParameters.mxSession,
                                                                  parentSpaceId: self.currentSpaceId,
                                                                  roomId: roomNavigationParameters.roomId,
                                                                  eventId: nil,
                                                                  threadId: nil,
                                                                  showSettingsInitially: false)

        dispatchGroup.enter()
        let roomCoordinator = RoomCoordinator(parameters: roomCoordinatorParameters)
        roomCoordinator.delegate = self
        roomCoordinator.start {
            dispatchGroup.leave()
        }
        self.add(childCoordinator: roomCoordinator)

        //  create thread coordinator
        let threadCoordinatorParameters = RoomCoordinatorParameters(navigationRouterStore: NavigationRouterStore.shared,
                                                                    userIndicatorPresenter: detailUserIndicatorPresenter,
                                                                    session: roomNavigationParameters.mxSession,
                                                                    parentSpaceId: self.currentSpaceId,
                                                                    roomId: roomNavigationParameters.roomId,
                                                                    eventId: roomNavigationParameters.eventId,
                                                                    threadId: roomNavigationParameters.threadParameters?.threadId,
                                                                    showSettingsInitially: false,
                                                                    displayConfiguration: .forThreads)

        dispatchGroup.enter()
        let threadCoordinator = RoomCoordinator(parameters: threadCoordinatorParameters)
        threadCoordinator.delegate = self
        threadCoordinator.start {
            dispatchGroup.leave()
        }
        self.add(childCoordinator: threadCoordinator)

        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            let modules: [NavigationModule] = [
                NavigationModule(presentable: roomCoordinator, popCompletion: { [weak self] in
                    // NOTE: The RoomDataSource releasing is handled in SplitViewCoordinator
                    self?.remove(childCoordinator: roomCoordinator)
                }),
                NavigationModule(presentable: threadCoordinator, popCompletion: { [weak self] in
                    // NOTE: The RoomDataSource releasing is handled in SplitViewCoordinator
                    self?.remove(childCoordinator: threadCoordinator)
                })
            ]

            self.showSplitViewDetails(with: modules,
                                      stack: roomNavigationParameters.presentationParameters.stackAboveVisibleViews)

            self.activityIndicatorPresenter.removeCurrentActivityIndicator(animated: true)
        }
    }

    // MARK: Sign out process
    
    private func signOut() {
        guard let keyBackup = currentMatrixSession?.crypto.backup else {
            return
        }
        
        signOutAlertPresenter.present(for: keyBackup.state,
                                      areThereKeysToBackup: keyBackup.hasKeysToBackup,
                                      from: self.allChatsViewController,
                                      sourceView: avatarMenuButton,
                                      animated: true)
    }
    
    // MARK: - SecureBackupSetupCoordinatorBridgePresenter
    
    private var secureBackupSetupCoordinatorBridgePresenter: SecureBackupSetupCoordinatorBridgePresenter?
    private var crossSigningSetupCoordinatorBridgePresenter: CrossSigningSetupCoordinatorBridgePresenter?

    private func showSecureBackupSetupFromSignOutFlow() {
        if canSetupSecureBackup {
            setupSecureBackup2()
        } else {
            // Set up cross-signing first
            setupCrossSigning(title: VectorL10n.secureKeyBackupSetupIntroTitle,
                              message: VectorL10n.securitySettingsUserPasswordDescription) { [weak self] result in
                switch result {
                case .success(let isCompleted):
                    if isCompleted {
                        self?.setupSecureBackup2()
                    }
                case .failure:
                    break
                }
            }
        }
    }
    
    private var canSetupSecureBackup: Bool {
        return currentMatrixSession?.vc_canSetupSecureBackup() ?? false
    }
    
    private func setupSecureBackup2() {
        guard let session = currentMatrixSession else {
            return
        }
        
        let secureBackupSetupCoordinatorBridgePresenter = SecureBackupSetupCoordinatorBridgePresenter(session: session, allowOverwrite: true)
        secureBackupSetupCoordinatorBridgePresenter.delegate = self
        secureBackupSetupCoordinatorBridgePresenter.present(from: allChatsViewController, animated: true)
        self.secureBackupSetupCoordinatorBridgePresenter = secureBackupSetupCoordinatorBridgePresenter
    }
    
    private func setupCrossSigning(title: String, message: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let session = currentMatrixSession else {
            return
        }

        allChatsViewController.startActivityIndicator()
        allChatsViewController.view.isUserInteractionEnabled = false
        
        let dismissAnimation = { [weak self] in
            guard let self = self else { return }
            
            self.allChatsViewController.stopActivityIndicator()
            self.allChatsViewController.view.isUserInteractionEnabled = true
            self.crossSigningSetupCoordinatorBridgePresenter?.dismiss(animated: true, completion: {
                self.crossSigningSetupCoordinatorBridgePresenter = nil
            })
        }
        
        let crossSigningSetupCoordinatorBridgePresenter = CrossSigningSetupCoordinatorBridgePresenter(session: session)
        crossSigningSetupCoordinatorBridgePresenter.present(with: title, message: message, from: allChatsViewController, animated: true) {
            dismissAnimation()
            completion(.success(true))
        } cancel: {
            dismissAnimation()
            completion(.success(false))
        } failure: { error in
            dismissAnimation()
            completion(.failure(error))
        }

        self.crossSigningSetupCoordinatorBridgePresenter = crossSigningSetupCoordinatorBridgePresenter
    }
    
    // MARK: - Private methods
    
    private func createVersionCheckCoordinator(withRootViewController rootViewController: UIViewController, bannerPresentrer: BannerPresentationProtocol) -> VersionCheckCoordinator {
        let versionCheckCoordinator = VersionCheckCoordinator(rootViewController: rootViewController,
                                                              bannerPresenter: bannerPresentrer,
                                                              themeService: ThemeService.shared())
        return versionCheckCoordinator
    }
    
    private func showInviteFriends(from sourceView: UIView?) {
        let myUserId = self.parameters.userSessionsService.mainUserSession?.userId ?? ""
        
        let inviteFriendsPresenter = InviteFriendsPresenter()
        inviteFriendsPresenter.present(for: myUserId, from: self.navigationRouter.toPresentable(), sourceView: sourceView, animated: true)
    }
    
    private func showBugReport() {
        let bugReportViewController = BugReportViewController()
        
        // Show in fullscreen to animate presentation along side menu dismiss
        bugReportViewController.modalPresentationStyle = .fullScreen
        bugReportViewController.modalTransitionStyle = .crossDissolve
        
        self.navigationRouter.present(bugReportViewController, animated: true)
    }

    private func userAvatarViewData(from mxSession: MXSession?) -> UserAvatarViewData? {
        guard let mxSession = mxSession, let userId = mxSession.myUserId, let mediaManager = mxSession.mediaManager, let myUser = mxSession.myUser else {
            return nil
        }
        
        let userDisplayName = myUser.displayname
        let avatarUrl = myUser.avatarUrl
        
        return UserAvatarViewData(userId: userId,
                                  displayName: userDisplayName,
                                  avatarUrl: avatarUrl,
                                  mediaManager: mediaManager)
    }

    private func createUnifiedSearchController() -> UnifiedSearchViewController {
        
        let viewController: UnifiedSearchViewController = UnifiedSearchViewController.instantiate()
        viewController.loadViewIfNeeded()
        
        for userSession in self.parameters.userSessionsService.userSessions {
            viewController.addMatrixSession(userSession.matrixSession)
        }
        
        return viewController
    }
    
    private func createSettingsViewController() -> SettingsViewController {
        let viewController: SettingsViewController = SettingsViewController.instantiate()
        viewController.loadViewIfNeeded()
        return viewController
    }
    
}

// MARK: - SignOutAlertPresenterDelegate
extension AllChatsCoordinator: SignOutAlertPresenterDelegate {
    
    func signOutAlertPresenterDidTapSignOutAction(_ presenter: SignOutAlertPresenter) {
        // Prevent user to perform user interaction in settings when sign out
        // TODO: Prevent user interaction in all application (navigation controller and split view controller included)
        allChatsViewController.view.isUserInteractionEnabled = false
        allChatsViewController.startActivityIndicator()
        
        AppDelegate.theDelegate().logout(withConfirmation: false) { [weak self] isLoggedOut in
            self?.allChatsViewController.stopActivityIndicator()
            self?.allChatsViewController.view.isUserInteractionEnabled = true
        }
    }
    
    func signOutAlertPresenterDidTapBackupAction(_ presenter: SignOutAlertPresenter) {
        showSecureBackupSetupFromSignOutFlow()
    }
    
}

// MARK: - SecureBackupSetupCoordinatorBridgePresenterDelegate
extension AllChatsCoordinator: SecureBackupSetupCoordinatorBridgePresenterDelegate {
    func secureBackupSetupCoordinatorBridgePresenterDelegateDidCancel(_ coordinatorBridgePresenter: SecureBackupSetupCoordinatorBridgePresenter) {
        coordinatorBridgePresenter.dismiss(animated: true) {
            self.secureBackupSetupCoordinatorBridgePresenter = nil
        }
    }
    
    func secureBackupSetupCoordinatorBridgePresenterDelegateDidComplete(_ coordinatorBridgePresenter: SecureBackupSetupCoordinatorBridgePresenter) {
        coordinatorBridgePresenter.dismiss(animated: true) {
            self.secureBackupSetupCoordinatorBridgePresenter = nil
        }
    }
}

// MARK: - AllChatsViewControllerDelegate
extension AllChatsCoordinator: AllChatsViewControllerDelegate {
    func allChatsViewControllerDidCompleteAuthentication(_ allChatsViewController: AllChatsViewController) {
        self.delegate?.splitViewMasterCoordinatorDidCompleteAuthentication(self)
    }
    
    func allChatsViewController(_ allChatsViewController: AllChatsViewController, didSelectRoomWithParameters roomNavigationParameters: RoomNavigationParameters, completion: @escaping () -> Void) {
        self.showRoom(withNavigationParameters: roomNavigationParameters, completion: completion)
    }
    
    func allChatsViewController(_ allChatsViewController: AllChatsViewController, didSelectRoomPreviewWithParameters roomPreviewNavigationParameters: RoomPreviewNavigationParameters, completion: (() -> Void)?) {
        self.showRoomPreview(withNavigationParameters: roomPreviewNavigationParameters, completion: completion)
    }
    
    func allChatsViewController(_ allChatsViewController: AllChatsViewController, didSelectContact contact: MXKContact, with presentationParameters: ScreenPresentationParameters) {
        self.showContactDetails(with: contact, presentationParameters: presentationParameters)
    }
}

// MARK: - RoomCoordinatorDelegate
extension AllChatsCoordinator: RoomCoordinatorDelegate {
    func roomCoordinatorDidDismissInteractively(_ coordinator: RoomCoordinatorProtocol) {
        self.remove(childCoordinator: coordinator)
    }
        
    func roomCoordinatorDidLeaveRoom(_ coordinator: RoomCoordinatorProtocol) {
        // For the moment when a room is left, reset the split detail with placeholder
        self.resetSplitViewDetails()
        indicatorPresenter
            .present(.success(label: VectorL10n.roomParticipantsLeaveSuccess))
            .store(in: &indicators)
    }
    
    func roomCoordinatorDidCancelRoomPreview(_ coordinator: RoomCoordinatorProtocol) {
        self.navigationRouter.popModule(animated: true)
    }
    
    func roomCoordinator(_ coordinator: RoomCoordinatorProtocol, didSelectRoomWithId roomId: String, eventId: String?) {
        self.showRoom(withId: roomId, eventId: eventId)
    }
    
    func roomCoordinator(_ coordinator: RoomCoordinatorProtocol, didReplaceRoomWithReplacementId roomId: String) {
        guard let matrixSession = self.parameters.userSessionsService.mainUserSession?.matrixSession else {
            return
        }

        let roomCoordinatorParameters = RoomCoordinatorParameters(navigationRouterStore: NavigationRouterStore.shared,
                                                                  userIndicatorPresenter: detailUserIndicatorPresenter,
                                                                  session: matrixSession,
                                                                  parentSpaceId: self.currentSpaceId,
                                                                  roomId: roomId,
                                                                  eventId: nil,
                                                                  showSettingsInitially: true)
        
        self.showRoom(with: roomCoordinatorParameters,
                      stackOnSplitViewDetail: false)
    }
    
    func roomCoordinatorDidCancelNewDirectChat(_ coordinator: RoomCoordinatorProtocol) {
        self.navigationRouter.popModule(animated: true)
    }
}
