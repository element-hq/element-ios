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

import CommonKit
import Foundation

struct UserSessionsFlowCoordinatorParameters {
    let session: MXSession
    let router: NavigationRouterType
}

final class UserSessionsFlowCoordinator: Coordinator, Presentable {
    private let parameters: UserSessionsFlowCoordinatorParameters
    
    private let navigationRouter: NavigationRouterType
    private var reauthenticationPresenter: ReauthenticationCoordinatorBridgePresenter?
    private var errorPresenter: MXKErrorPresentation
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?
    
    /// The root coordinator for user session management.
    private weak var sessionsOverviewCoordinator: UserSessionsOverviewCoordinator?
    
    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: (() -> Void)?
    
    init(parameters: UserSessionsFlowCoordinatorParameters) {
        self.parameters = parameters
        
        self.navigationRouter = parameters.router
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
        let parameters = UserSessionsOverviewCoordinatorParameters(session: parameters.session)
        
        let coordinator = UserSessionsOverviewCoordinator(parameters: parameters)
        coordinator.completion = { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .renameSession(sessionInfo):
                break
            case let .logoutOfSession(sessionInfo):
                self.showLogoutConfirmation(for: sessionInfo)
            case let .openSessionOverview(sessionInfo: sessionInfo):
                self.openSessionOverview(sessionInfo: sessionInfo)
            case let .openOtherSessions(sessionsInfo: sessionsInfo, filter: filter):
                self.openOtherSessions(sessionsInfo: sessionsInfo,
                                       filterBy: filter,
                                       title: VectorL10n.userOtherSessionSecurityRecommendationTitle)
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
            case let .renameSession(sessionInfo):
                break
            case let .logoutOfSession(sessionInfo):
                self.showLogoutConfirmation(for: sessionInfo)
            }
        }
        pushScreen(with: coordinator)
    }
    
    private func createUserSessionOverviewCoordinator(sessionInfo: UserSessionInfo) -> UserSessionOverviewCoordinator {
        let parameters = UserSessionOverviewCoordinatorParameters(session: parameters.session,
                                                                  sessionInfo: sessionInfo)
        return UserSessionOverviewCoordinator(parameters: parameters)
    }
    
    private func openOtherSessions(sessionsInfo: [UserSessionInfo], filterBy filter: OtherUserSessionsFilter, title: String) {
        let coordinator = createOtherSessionsCoordinator(sessionsInfo: sessionsInfo,
                                                         filterBy: filter,
                                                         title: title)
        coordinator.completion = { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .openSessionDetails(sessionInfo: session):
                self.openSessionDetails(sessionInfo: session)
            }
        }
        pushScreen(with: coordinator)
    }
    
    private func createOtherSessionsCoordinator(sessionsInfo: [UserSessionInfo],
                                                filterBy filter: OtherUserSessionsFilter,
                                                title: String) -> UserOtherSessionsCoordinator {
        let parameters = UserOtherSessionsCoordinatorParameters(sessionsInfo: sessionsInfo,
                                                                filter: filter,
                                                                title: title)
        return UserOtherSessionsCoordinator(parameters: parameters)
    }
    
    
    /// Shows a confirmation dialog to the user to sign out of a session.
    private func showLogoutConfirmation(for sessionInfo: UserSessionInfo) {
        // Use a UIAlertController as we don't have confirmationDialog in SwiftUI on iOS 14.
        let alert = UIAlertController(title: VectorL10n.signOutConfirmationMessage, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: VectorL10n.signOut, style: .destructive) { [weak self] _ in
            self?.showLogoutAuthentication(for: sessionInfo)
        })
        alert.addAction(UIAlertAction(title: VectorL10n.cancel, style: .cancel))
        alert.popoverPresentationController?.sourceView = toPresentable().view
        
        navigationRouter.present(alert, animated: true)
    }
    
    /// Prompts the user to authenticate (if necessary) in order to log out of a specific session.
    private func showLogoutAuthentication(for sessionInfo: UserSessionInfo) {
        startLoading()
        
        let deleteDeviceRequest = AuthenticatedEndpointRequest.deleteDevice(sessionInfo.id)
        let coordinatorParameters = ReauthenticationCoordinatorParameters(session: parameters.session,
                                                                          presenter: navigationRouter.toPresentable(),
                                                                          title: VectorL10n.deviceDetailsDeletePromptTitle,
                                                                          message: VectorL10n.deviceDetailsDeletePromptMessage,
                                                                          authenticatedEndpointRequest: deleteDeviceRequest)
        let presenter = ReauthenticationCoordinatorBridgePresenter()
        presenter.present(with: coordinatorParameters, animated: true) { [weak self] authenticationParameters in
            self?.finalizeLogout(of: sessionInfo, with: authenticationParameters)
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
    
    /// Finishes the logout process by deleting the device from the user's account.
    /// - Parameters:
    ///   - sessionInfo: The `UserSessionInfo` for the session to be removed.
    ///   - authenticationParameters: The parameters from performing interactive authentication on the `devices` endpoint.
    private func finalizeLogout(of sessionInfo: UserSessionInfo, with authenticationParameters: [String: Any]?) {
        parameters.session.matrixRestClient.deleteDevice(sessionInfo.id,
                                                         authParameters: authenticationParameters ?? [:]) { [weak self] response in
            guard let self = self else { return }
            
            self.stopLoading()

            guard response.isSuccess else {
                MXLog.debug("[LogoutDeviceService] Delete device (\(sessionInfo.id) failed")
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
    
    /// Pops back to the root coordinator in the session management flow.
    private func popToSessionsOverview() {
        guard let sessionsOverviewCoordinator = sessionsOverviewCoordinator else { return }
        navigationRouter.popToModule(sessionsOverviewCoordinator, animated: true)
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
