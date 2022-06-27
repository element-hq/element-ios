// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationEmailInvites SpaceCreationEmailInvites
/*
 Copyright 2021 New Vector Ltd
 
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
import SwiftUI

final class SpaceCreationEmailInvitesCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: SpaceCreationEmailInvitesCoordinatorParameters
    private let spaceCreationEmailInvitesHostingController: UIViewController
    private var spaceCreationEmailInvitesViewModel: SpaceCreationEmailInvitesViewModelProtocol
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var callback: ((SpaceCreationEmailInvitesCoordinatorAction) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: SpaceCreationEmailInvitesCoordinatorParameters) {
        self.parameters = parameters
        let service = SpaceCreationEmailInvitesService(session: parameters.session)
        let viewModel = SpaceCreationEmailInvitesViewModel(creationParameters: parameters.creationParams, service: service)
        let view = SpaceCreationEmailInvites(viewModel: viewModel.context)
            .addDependency(AvatarService.instantiate(mediaManager: parameters.session.mediaManager))
        spaceCreationEmailInvitesViewModel = viewModel
        let hostingController = VectorHostingController(rootView: view)
        hostingController.isNavigationBarHidden = true
        spaceCreationEmailInvitesHostingController = hostingController
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[SpaceCreationEmailInvitesCoordinator] did start.")
        spaceCreationEmailInvitesViewModel.completion = { [weak self] result in
            MXLog.debug("[SpaceCreationEmailInvitesCoordinator] SpaceCreationEmailInvitesViewModel did complete with result: \(result).")
            guard let self = self else { return }
            switch result {
            case .cancel:
                self.callback?(.cancel)
            case .back:
                self.callback?(.back)
            case .done:
                self.callback?(.done)
            case .inviteByUsername:
                self.callback?(.inviteByUsername)
            case .needIdentityServiceTerms(let baseUrl, let accessToken):
                self.presentIdentityServerTerms(with: baseUrl, accessToken: accessToken)
            case .identityServiceFailure(let error):
                self.showIdentityServiceFailure(error)
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.spaceCreationEmailInvitesHostingController
    }
    
    // MARK: - Identity service
    
    private var serviceTermsModalCoordinatorBridgePresenter: ServiceTermsModalCoordinatorBridgePresenter?
    
    private func presentIdentityServerTerms(with baseUrl: String?, accessToken: String?) {
        guard let baseUrl = baseUrl, let accessToken = accessToken else {
            showIdentityServiceFailure(nil)
            return
        }

        let presenter = ServiceTermsModalCoordinatorBridgePresenter(session: parameters.session, baseUrl: baseUrl, serviceType: MXServiceTypeIdentityService, accessToken: accessToken)
        presenter.delegate = self
        presenter.present(from: self.toPresentable(), animated: true)
        serviceTermsModalCoordinatorBridgePresenter = presenter
    }
    
    private func showIdentityServiceFailure(_ error: Error?) {
        let alertController = UIAlertController(title: VectorL10n.findYourContactsIdentityServiceError, message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: VectorL10n.ok, style: .default, handler: nil))
        self.toPresentable().present(alertController, animated: true, completion: nil);
    }
}

extension SpaceCreationEmailInvitesCoordinator: ServiceTermsModalCoordinatorBridgePresenterDelegate {
    func serviceTermsModalCoordinatorBridgePresenterDelegateDidAccept(_ coordinatorBridgePresenter: ServiceTermsModalCoordinatorBridgePresenter) {
        coordinatorBridgePresenter.dismiss(animated: true) {
            self.serviceTermsModalCoordinatorBridgePresenter = nil;
            self.callback?(.done)
        }
    }
    
    func serviceTermsModalCoordinatorBridgePresenterDelegateDidDecline(_ coordinatorBridgePresenter: ServiceTermsModalCoordinatorBridgePresenter, session: MXSession) {
        coordinatorBridgePresenter.dismiss(animated: true) {
            self.serviceTermsModalCoordinatorBridgePresenter = nil;
        }
    }
    
    func serviceTermsModalCoordinatorBridgePresenterDelegateDidClose(_ coordinatorBridgePresenter: ServiceTermsModalCoordinatorBridgePresenter) {
        coordinatorBridgePresenter.dismiss(animated: true) {
            self.serviceTermsModalCoordinatorBridgePresenter = nil;
        }
    }
}
