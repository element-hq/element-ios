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
    
    @available(iOS 14.0, *)
    init(parameters: SpaceCreationEmailInvitesCoordinatorParameters) {
        self.parameters = parameters
        let service = SpaceCreationEmailInvitesService()
        let viewModel = SpaceCreationEmailInvitesViewModel(creationParameters: parameters.creationParams, service: service)
        let view = SpaceCreationEmailInvites(viewModel: viewModel.context)
            .addDependency(AvatarService.instantiate(mediaManager: parameters.session.mediaManager))
        spaceCreationEmailInvitesViewModel = viewModel
        let hostingController = VectorHostingController(rootView: view)
        hostingController.hidesBackTitleWhenPushed = true
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
            case .done:
                self.callback?(.done)
            case .inviteByUsername:
                self.callback?(.inviteByUsername)
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.spaceCreationEmailInvitesHostingController
    }
}
