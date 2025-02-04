//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import CommonKit
import Foundation

struct UserSessionsFlowCoordinatorParameters {
    let session: MXSession
    let router: NavigationRouterType
}

final class UserSessionsFlowCoordinator: NSObject, Coordinator, Presentable {
    private let parameters: UserSessionsFlowCoordinatorParameters
    private let allSessionsService: UserSessionsOverviewService
    
    private let navigationRouter: NavigationRouterType
    private var reauthenticationPresenter: ReauthenticationCoordinatorBridgePresenter?
    private var signOutFlowPresenter: SignOutFlowPresenter?
    private var errorPresenter: MXKErrorPresentation
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?
    private var ssoAuthenticationPresenter: SSOAuthenticationPresenter?
    
    /// The root coordinator for user session management.
    private weak var sessionsOverviewCoordinator: UserSessionsOverviewCoordinator?
    
    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: (() -> Void)?
    
    init(parameters: UserSessionsFlowCoordinatorParameters) {
        self.parameters = parameters
        
        let dataProvider = UserSessionsDataProvider(session: parameters.session)
        allSessionsService = UserSessionsOverviewService(dataProvider: dataProvider)
        
        navigationRouter = parameters.router
        errorPresenter = MXKErrorAlertPresentation()
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: parameters.router.toPresentable())
    }
    
    // MARK: - Private
    
    private func pushScreen(with coordinator: Coordinator & Presentable) {
        add(childCoordinator: coordinator)
        
        navigationRouter.push(coordinator, animated: true, popCompletion: { [weak self] in
            self?.remove(childCoordinator: coordinator)
        })
        
        coordinator.start()
    }
    
    private func createUserSessionsOverviewCoordinator() -> UserSessionsOverviewCoordinator {
        let parameters = UserSessionsOverviewCoordinatorParameters(session: parameters.session,
                                                                   service: allSessionsService)
        
        let coordinator = UserSessionsOverviewCoordinator(parameters: parameters)
        coordinator.completion = { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .verifyCurrentSession:
                self.showCompleteSecurity()
            case let .renameSession(sessionInfo):
                self.showRenameSessionScreen(for: sessionInfo)
            case let .logoutOfSession(sessionInfo):
                if sessionInfo.isCurrent {
                    self.showLogoutConfirmationForCurrentSession()
                } else {
                    self.showLogoutConfirmation(for: [sessionInfo])
                }
            case let .openSessionOverview(sessionInfo: sessionInfo):
                self.openSessionOverview(sessionInfo: sessionInfo)
            case let .openOtherSessions(sessionInfos: sessionInfos, filter: filter):
                self.openOtherSessions(sessionInfos: sessionInfos, filterBy: filter)
            case .linkDevice:
                self.openQRLoginScreen()
            case let .logoutFromUserSessions(sessionInfos: sessionInfos):
                self.showLogoutConfirmation(for: sessionInfos)
            }
        }
        return coordinator
    }
    
    private func openSessionDetails(sessionInfo: UserSessionInfo) {
        let coordinator = createUserSessionDetailsCoordinator(sessionInfo: sessionInfo)
        pushScreen(with: coordinator)
    }
    
    private func createUserSessionDetailsCoordinator(sessionInfo: UserSessionInfo) -> UserSessionDetailsCoordinator {
        let parameters = UserSessionDetailsCoordinatorParameters(sessionInfo: sessionInfo)
        return UserSessionDetailsCoordinator(parameters: parameters)
    }
    
    private func openSessionOverview(sessionInfo: UserSessionInfo) {
        let coordinator = createUserSessionOverviewCoordinator(sessionInfo: sessionInfo)
        coordinator.completion = { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .openSessionDetails(sessionInfo: sessionInfo):
                self.openSessionDetails(sessionInfo: sessionInfo)
            case let .verifySession(sessionInfo):
                if sessionInfo.isCurrent {
                    self.showCompleteSecurity()
                } else {
                    self.showVerification(for: sessionInfo)
                }
            case let .renameSession(sessionInfo):
                self.showRenameSessionScreen(for: sessionInfo)
            case let .logoutOfSession(sessionInfo):
                self.handleLogoutOfSession(sessionInfo: sessionInfo)
            case let .showSessionStateInfo(sessionInfo):
                self.showInfoSheet(parameters: .init(userSessionInfo: sessionInfo, parentSize: self.toPresentable().view.bounds.size))
            }
        }
        pushScreen(with: coordinator)
    }
    
    private func handleLogoutOfSession(sessionInfo: UserSessionInfo) {
        if sessionInfo.isCurrent {
            self.showLogoutConfirmationForCurrentSession()
        } else {
            if let authentication = self.parameters.session.homeserverWellknown.authentication {
                if let logoutURL = authentication.getLogoutDeviceURL(fromID: sessionInfo.id) {
                    self.openDeviceLogoutRedirectURL(logoutURL)
                } else {
                    self.showDeviceLogoutRedirectError()
                }
            } else {
                self.showLogoutConfirmation(for: [sessionInfo])
            }
        }
    }

    /// Shows the QR login screen.
    private func openQRLoginScreen() {
        let service = QRLoginService(client: parameters.session.matrixRestClient,
                                     mode: .authenticated)
        let parameters = AuthenticationQRLoginStartCoordinatorParameters(navigationRouter: navigationRouter,
                                                                         qrLoginService: service)
        let coordinator = AuthenticationQRLoginStartCoordinator(parameters: parameters)
        coordinator.callback = { [weak self, weak coordinator] _ in
            guard let self = self, let coordinator = coordinator else { return }
            self.remove(childCoordinator: coordinator)
        }

        pushScreen(with: coordinator)
    }
    
    private func createUserSessionOverviewCoordinator(sessionInfo: UserSessionInfo) -> UserSessionOverviewCoordinator {
        let parameters = UserSessionOverviewCoordinatorParameters(session: parameters.session,
                                                                  sessionInfo: sessionInfo,
                                                                  sessionsOverviewDataPublisher: allSessionsService.overviewDataPublisher)
        return UserSessionOverviewCoordinator(parameters: parameters)
    }
    
    private func openOtherSessions(sessionInfos: [UserSessionInfo], filterBy filter: UserOtherSessionsFilter) {
        let title = filter == .all ? VectorL10n.userSessionsOverviewOtherSessionsSectionTitle : VectorL10n.userOtherSessionSecurityRecommendationTitle
        let coordinator = createOtherSessionsCoordinator(sessionInfos: sessionInfos,
                                                         filterBy: filter,
                                                         title: title)
        coordinator.completion = { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .openSessionOverview(sessionInfo: session):
                self.openSessionOverview(sessionInfo: session)
            case let .logoutFromUserSessions(sessionInfos: sessionInfos):
                self.showLogoutConfirmation(for: sessionInfos)
            case let .showSessionStateByFilter(filter):
                self.showInfoSheet(parameters: .init(filter: filter, parentSize: self.toPresentable().view.bounds.size))
            }
        }
        pushScreen(with: coordinator)
    }
    
    private func createOtherSessionsCoordinator(sessionInfos: [UserSessionInfo],
                                                filterBy filter: UserOtherSessionsFilter,
                                                title: String) -> UserOtherSessionsCoordinator {
        let shouldShowDeviceLogout = parameters.session.homeserverWellknown.authentication == nil
        let parameters = UserOtherSessionsCoordinatorParameters(sessionInfos: sessionInfos,
                                                                filter: filter,
                                                                title: title,
                                                                showDeviceLogout: shouldShowDeviceLogout)
        return UserOtherSessionsCoordinator(parameters: parameters)
    }
    
    private func openDeviceLogoutRedirectURL(_ url: URL) {
        let alert = UIAlertController(title: VectorL10n.manageSessionRedirect, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: VectorL10n.ok, style: .default) { [weak self] _ in
            guard let self else { return }
            
            let service = SSOAccountService(accountURL: url)
            let presenter = SSOAuthenticationPresenter(ssoAuthenticationService: service)
            presenter.delegate = self
            self.ssoAuthenticationPresenter = presenter
            
            presenter.present(forIdentityProvider: nil, with: "", from: self.toPresentable(), animated: true)
        })
        alert.popoverPresentationController?.sourceView = toPresentable().view
        navigationRouter.present(alert, animated: true)
    }
    
    private func showDeviceLogoutRedirectError() {
        let alert = UIAlertController(title: VectorL10n.manageSessionRedirectError, message: nil, preferredStyle: .alert)
        alert.popoverPresentationController?.sourceView = toPresentable().view
        navigationRouter.present(alert, animated: true)
    }
    
    /// Shows a confirmation dialog to the user to sign out of a session.
    private func showLogoutConfirmation(for sessionInfos: [UserSessionInfo]) {
        // Use a UIAlertController as we don't have confirmationDialog in SwiftUI on iOS 14.
        let alert = UIAlertController(title: VectorL10n.signOutConfirmationMessage, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: VectorL10n.signOut, style: .destructive) { [weak self] _ in
            self?.showLogoutAuthentication(for: sessionInfos)
        })
        alert.addAction(UIAlertAction(title: VectorL10n.cancel, style: .cancel))
        alert.popoverPresentationController?.sourceView = toPresentable().view
        
        navigationRouter.present(alert, animated: true)
    }
    
    private func showInfoSheet(parameters: InfoSheetCoordinatorParameters) {
        let coordinator = InfoSheetCoordinator(parameters: parameters)
        
        coordinator.toPresentable().presentationController?.delegate = self
        coordinator.completion = { [weak self, weak coordinator] result in
            guard let self = self, let coordinator = coordinator else { return }
            
            switch result {
            case .actionTriggered:
                self.navigationRouter.dismissModule(animated: true, completion: nil)
                self.remove(childCoordinator: coordinator)
            }
        }
        
        add(childCoordinator: coordinator)
        coordinator.start()
        navigationRouter.present(coordinator, animated: true)
    }
    
    private func showLogoutConfirmationForCurrentSession() {
        let flowPresenter = SignOutFlowPresenter(session: parameters.session, presentingViewController: toPresentable())
        flowPresenter.delegate = self
        
        flowPresenter.start()
        signOutFlowPresenter = flowPresenter
    }
    
    /// Prompts the user to authenticate (if necessary) in order to log out of specific sessions.
    private func showLogoutAuthentication(for sessionInfos: [UserSessionInfo]) {
        startLoading()
        
        let deviceIDs = sessionInfos.map(\.id)
        let deleteDevicesRequest = AuthenticatedEndpointRequest.deleteDevices(deviceIDs)
        let coordinatorParameters = ReauthenticationCoordinatorParameters(session: parameters.session,
                                                                          presenter: navigationRouter.toPresentable(),
                                                                          title: VectorL10n.deviceDetailsDeletePromptTitle,
                                                                          message: VectorL10n.deviceDetailsDeletePromptMessage,
                                                                          authenticatedEndpointRequest: deleteDevicesRequest)
        let presenter = ReauthenticationCoordinatorBridgePresenter()
        presenter.present(with: coordinatorParameters, animated: true) { [weak self] authenticationParameters in
            self?.finalizeLogout(of: deviceIDs, with: authenticationParameters)
            self?.reauthenticationPresenter = nil
        } cancel: { [weak self] in
            self?.stopLoading()
            self?.reauthenticationPresenter = nil
        } failure: { [weak self] error in
            guard let self = self else { return }
            self.stopLoading()
            self.errorPresenter.presentError(from: self.toPresentable(), forError: error, animated: true, handler: { })
            self.reauthenticationPresenter = nil
        }

        reauthenticationPresenter = presenter
    }

    /// Finishes the logout process by deleting the devices from the user's account.
    /// - Parameters:
    ///   - deviceIDs: IDs for the sessions to be removed.
    ///   - authenticationParameters: The parameters from performing interactive authentication on the `devices` endpoint.
    private func finalizeLogout(of deviceIDs: [String], with authenticationParameters: [String: Any]?) {
        parameters.session.matrixRestClient.deleteDevices(deviceIDs,
                                                          authParameters: authenticationParameters ?? [:]) { [weak self] response in
            guard let self = self else { return }
            
            self.stopLoading()

            guard response.isSuccess else {
                MXLog.debug("[UserSessionsFlowCoordinator] Delete devices failed")
                if let error = response.error {
                    self.errorPresenter.presentError(from: self.toPresentable(), forError: error, animated: true, handler: { })
                } else {
                    self.errorPresenter.presentGenericError(from: self.toPresentable(), animated: true, handler: { })
                }
                
                return
            }

            self.popToSessionsOverview()
        }
    }
    
    private func showRenameSessionScreen(for sessionInfo: UserSessionInfo) {
        let parameters = UserSessionNameCoordinatorParameters(session: parameters.session, sessionInfo: sessionInfo)
        let coordinator = UserSessionNameCoordinator(parameters: parameters)
        
        coordinator.completion = { [weak self, weak coordinator] result in
            guard let self = self, let coordinator = coordinator else { return }
            switch result {
            case .sessionNameUpdated:
                self.allSessionsService.updateOverviewData { [weak self] _ in
                    self?.navigationRouter.dismissModule(animated: true, completion: nil)
                    self?.remove(childCoordinator: coordinator)
                }
            case .cancel:
                self.navigationRouter.dismissModule(animated: true, completion: nil)
                self.remove(childCoordinator: coordinator)
            }
        }
        
        add(childCoordinator: coordinator)
        let modalRouter = NavigationRouter(navigationController: RiotNavigationController())
        modalRouter.setRootModule(coordinator)
        coordinator.start()
        modalRouter.toPresentable().presentationController?.delegate = self
        navigationRouter.present(modalRouter, animated: true)
    }
    
    /// Shows a prompt to the user that it is not possible to verify
    /// another session until the current session has been verified.
    private func showCannotVerifyOtherSessionPrompt() {
        let alert = UIAlertController(title: VectorL10n.securitySettingsCompleteSecurityAlertTitle,
                                      message: VectorL10n.securitySettingsCompleteSecurityAlertMessage,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: VectorL10n.later, style: .cancel))
        alert.addAction(UIAlertAction(title: VectorL10n.ok, style: .default) { [weak self] _ in
            self?.showCompleteSecurity()
        })
        
        navigationRouter.present(alert, animated: true)
    }
    
    /// Shows the Complete Security modal for the user to verify their current session.
    private func showCompleteSecurity() {
        AppDelegate.theDelegate().presentCompleteSecurity(for: parameters.session)
    }
    
    /// Shows the verification screen for the specified session.
    private func showVerification(for sessionInfo: UserSessionInfo) {
        if sessionInfo.verificationState == .unknown {
            showCannotVerifyOtherSessionPrompt()
            return
        }
        
        let coordinator = UserVerificationCoordinator(presenter: toPresentable(),
                                                      session: parameters.session,
                                                      userId: parameters.session.myUserId,
                                                      userDisplayName: nil,
                                                      deviceId: sessionInfo.id)
        coordinator.delegate = self
        
        add(childCoordinator: coordinator)
        coordinator.start()
    }
    
    /// Pops back to the root coordinator in the session management flow.
    private func popToSessionsOverview() {
        guard let sessionsOverviewCoordinator = sessionsOverviewCoordinator else { return }
        if let coordinator = navigationRouter.modules.last as? UserSessionsOverviewCoordinator {
            coordinator.refreshData()
        } else {
            navigationRouter.popToModule(sessionsOverviewCoordinator, animated: true)
        }
    }
    
    /// Show an activity indicator whilst loading.
    private func startLoading() {
        loadingIndicator = indicatorPresenter.present(.loading(label: VectorL10n.loading, isInteractionBlocking: true))
    }

    /// Hide the currently displayed activity indicator.
    private func stopLoading() {
        loadingIndicator = nil
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[UserSessionsFlowCoordinator] did start.")
        
        let rootCoordinator = createUserSessionsOverviewCoordinator()
        rootCoordinator.start()
        
        add(childCoordinator: rootCoordinator)
        
        if navigationRouter.modules.isEmpty == false {
            navigationRouter.push(rootCoordinator, animated: true, popCompletion: { [weak self] in
                self?.remove(childCoordinator: rootCoordinator)
                self?.completion?()
            })
        } else {
            navigationRouter.setRootModule(rootCoordinator) { [weak self] in
                self?.remove(childCoordinator: rootCoordinator)
                self?.completion?()
            }
        }
        
        sessionsOverviewCoordinator = rootCoordinator
    }
    
    func toPresentable() -> UIViewController {
        navigationRouter.toPresentable()
    }
}

// MARK: SignOutFlowPresenter

extension UserSessionsFlowCoordinator: SignOutFlowPresenterDelegate {
    func signOutFlowPresenterDidStartLoading(_ presenter: SignOutFlowPresenter) {
        startLoading()
    }
    
    func signOutFlowPresenterDidStopLoading(_ presenter: SignOutFlowPresenter) {
        stopLoading()
    }
    
    func signOutFlowPresenter(_ presenter: SignOutFlowPresenter, didFailWith error: Error) {
        errorPresenter.presentError(from: toPresentable(), forError: error, animated: true, handler: { })
    }
}

// MARK: CrossSigningSetupCoordinatorDelegate

extension UserSessionsFlowCoordinator: CrossSigningSetupCoordinatorDelegate {
    func crossSigningSetupCoordinatorDidComplete(_ coordinator: CrossSigningSetupCoordinatorType) {
        // The service is listening for changes so there's nothing to do here.
        remove(childCoordinator: coordinator)
    }
    
    func crossSigningSetupCoordinatorDidCancel(_ coordinator: CrossSigningSetupCoordinatorType) {
        remove(childCoordinator: coordinator)
    }
    
    func crossSigningSetupCoordinator(_ coordinator: CrossSigningSetupCoordinatorType, didFailWithError error: Error) {
        remove(childCoordinator: coordinator)
        errorPresenter.presentError(from: toPresentable(), forError: error, animated: true, handler: { })
    }
}

// MARK: UserVerificationCoordinatorDelegate

extension UserSessionsFlowCoordinator: UserVerificationCoordinatorDelegate {
    func userVerificationCoordinatorDidComplete(_ coordinator: UserVerificationCoordinatorType) {
        // The service is listening for changes so there's nothing to do here.
        remove(childCoordinator: coordinator)
    }
}

// MARK: UIAdaptivePresentationControllerDelegate

extension UserSessionsFlowCoordinator: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        guard let coordinator = childCoordinators.last else {
            return
        }
        
        remove(childCoordinator: coordinator)
    }
}

// MARK: Private

private extension InfoSheetCoordinatorParameters {
    init(userSessionInfo: UserSessionInfo, parentSize: CGSize) {
        self.init(title: userSessionInfo.bottomSheetTitle,
                  description: userSessionInfo.bottomSheetDescription,
                  action: .init(text: VectorL10n.userSessionGotIt, action: { }),
                  parentSize: parentSize)
    }
    
    init(filter: UserOtherSessionsFilter, parentSize: CGSize) {
        self.init(title: filter.bottomSheetTitle,
                  description: filter.bottomSheetDescription,
                  action: .init(text: VectorL10n.userSessionGotIt, action: { }),
                  parentSize: parentSize)
    }
}

private extension UserSessionInfo {
    var bottomSheetTitle: String {
        switch verificationState {
        case .unverified, .permanentlyUnverified:
            return VectorL10n.userSessionUnverifiedSessionTitle
        case .verified:
            return VectorL10n.userSessionVerifiedSessionTitle
        case .unknown:
            return ""
        }
    }

    var bottomSheetDescription: String {
        switch verificationState {
        case .unverified:
            return VectorL10n.userSessionUnverifiedSessionDescription
        case .permanentlyUnverified:
            return VectorL10n.userSessionPermanentlyUnverifiedSessionDescription
        case .verified:
            return VectorL10n.userSessionVerifiedSessionDescription
        case .unknown:
            return ""
        }
    }
}

private extension UserOtherSessionsFilter {
    var bottomSheetTitle: String {
        switch self {
        case .unverified:
            return VectorL10n.userSessionUnverifiedSessionTitle
        case .verified:
            return VectorL10n.userSessionVerifiedSessionTitle
        case .inactive:
            return VectorL10n.userSessionInactiveSessionTitle
        case .all:
            return ""
        }
    }
    
    var bottomSheetDescription: String {
        switch self {
        case .unverified:
            return VectorL10n.userSessionUnverifiedSessionDescription
        case .verified:
            return VectorL10n.userSessionVerifiedSessionDescription
        case .inactive:
            return VectorL10n.userSessionInactiveSessionDescription
        case .all:
            return ""
        }
    }
}

// MARK: ASWebAuthenticationPresentationContextProviding

extension UserSessionsFlowCoordinator: SSOAuthenticationPresenterDelegate {
    func ssoAuthenticationPresenterDidCancel(_ presenter: SSOAuthenticationPresenter) {
        ssoAuthenticationPresenter = nil
        MXLog.info("OIDC account management complete.")
        popToSessionsOverview()
    }
    
    func ssoAuthenticationPresenter(_ presenter: SSOAuthenticationPresenter, authenticationDidFailWithError error: Error) {
        ssoAuthenticationPresenter = nil
        MXLog.error("OIDC account management failed.")
    }
    
    func ssoAuthenticationPresenter(_ presenter: SSOAuthenticationPresenter,
                                    authenticationSucceededWithToken token: String,
                                    usingIdentityProvider identityProvider: SSOIdentityProvider?) {
        ssoAuthenticationPresenter = nil
        MXLog.warning("Unexpected callback after OIDC account management.")
    }
}
