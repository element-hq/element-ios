//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import CommonKit
import SwiftUI

struct UserSessionNameCoordinatorParameters {
    let session: MXSession
    let sessionInfo: UserSessionInfo
}

final class UserSessionNameCoordinator: NSObject, Coordinator, Presentable {
    private let parameters: UserSessionNameCoordinatorParameters
    private let userSessionNameHostingController: UIViewController
    private var userSessionNameViewModel: UserSessionNameViewModelProtocol
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: ((UserSessionNameCoordinatorResult) -> Void)?
    
    init(parameters: UserSessionNameCoordinatorParameters) {
        self.parameters = parameters
        
        let viewModel = UserSessionNameViewModel(sessionInfo: parameters.sessionInfo)
        let view = UserSessionName(viewModel: viewModel.context)
        userSessionNameViewModel = viewModel
        userSessionNameHostingController = VectorHostingController(rootView: view)
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: userSessionNameHostingController)
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[UserSessionNameCoordinator] did start.")
        userSessionNameViewModel.completion = { [weak self] result in
            guard let self = self else { return }
            
            MXLog.debug("[UserSessionNameCoordinator] UserSessionNameViewModel did complete with result: \(result).")
            switch result {
            case .updateName(let newName):
                self.updateName(newName)
            case .cancel:
                self.completion?(.cancel)
            case .learnMore:
                self.showInfoSheet(parameters: .init(title: VectorL10n.userSessionRenameSessionTitle,
                                                     description: VectorL10n.userSessionRenameSessionDescription,
                                                     action: .init(text: VectorL10n.userSessionGotIt, action: {}),
                                                     parentSize: self.toPresentable().view.bounds.size))
            }
        }
    }
    
    func toPresentable() -> UIViewController { userSessionNameHostingController }
    
    // MARK: - Private
    
    /// Updates the name of the device, completing the screen's presentation if successful.
    private func updateName(_ newName: String) {
        startLoading()
        parameters.session.matrixRestClient.setDeviceName(newName, forDevice: parameters.sessionInfo.id) { [weak self] response in
            guard let self = self else { return }
            
            guard response.isSuccess else {
                MXLog.debug("[UserSessionNameCoordinator] Rename device (\(self.parameters.sessionInfo.id)) failed")
                self.userSessionNameViewModel.processError(response.error as NSError?)
                return
            }
            
            self.stopLoading()
            self.completion?(.sessionNameUpdated)
        }
    }
    
    /// Show an activity indicator whilst loading.
    /// - Parameters:
    ///   - label: The label to show on the indicator.
    ///   - isInteractionBlocking: Whether the indicator should block any user interaction.
    private func startLoading(label: String = VectorL10n.loading, isInteractionBlocking: Bool = true) {
        loadingIndicator = indicatorPresenter.present(.loading(label: label, isInteractionBlocking: isInteractionBlocking))
    }
    
    /// Hide the currently displayed activity indicator.
    private func stopLoading() {
        loadingIndicator = nil
    }
    
    private func showInfoSheet(parameters: InfoSheetCoordinatorParameters) {
        let coordinator = InfoSheetCoordinator(parameters: parameters)
        coordinator.toPresentable().presentationController?.delegate = self
        coordinator.completion = { [weak self, weak coordinator] result in
            guard let self = self, let coordinator = coordinator else { return }
            
            switch result {
            case .actionTriggered:
                self.toPresentable().dismiss(animated: true)
                self.remove(childCoordinator: coordinator)
            }
        }
        
        add(childCoordinator: coordinator)
        coordinator.start()
        toPresentable().present(coordinator.toPresentable(), animated: true)
    }
}

// MARK: UIAdaptivePresentationControllerDelegate

extension UserSessionNameCoordinator: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        guard let coordinator = childCoordinators.last else {
            return
        }
        
        remove(childCoordinator: coordinator)
    }
}
