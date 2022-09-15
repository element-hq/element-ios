// File created from FlowTemplate
// $ createRootCoordinator.sh Folder UserSessionFlow UserSessionOverview
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

import CommonKit
import UIKit

protocol UserSessionFlowCoordinatorDelegate: AnyObject {
//    func userSessionFlowCoordinatorDidComplete(_ coordinator: UserSessionFlowCoordinatorProtocol)
//
//    /// Called when the view has been dismissed by gesture when presented modally (not in full screen).
//    func userSessionFlowCoordinatorDidDismissInteractively(_ coordinator: UserSessionFlowCoordinatorProtocol)
}

struct UserSessionFlowCoordinatorParameters {
    let session: MXSession
    let navigationRouter: NavigationRouterType
    let userSessionInfo: UserSessionInfo
}

final class UserSessionFlowCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
        
    private let parameters: UserSessionFlowCoordinatorParameters
    private let userSessionDetailsViewHostingController: UIViewController
    private var userSessionDetailsViewModel: UserSessionDetailsViewModel
   
    private var navigationRouter: NavigationRouterType {
        return self.parameters.navigationRouter
    }
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: UserSessionFlowCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(parameters: UserSessionFlowCoordinatorParameters) {
        self.parameters = parameters
        
        // todo: builder
        let viewModel = UserSessionDetailsViewModel(userSessionInfo: parameters.userSessionInfo)
        let view = UserSessionDetailsView(viewModel: viewModel.context)
        userSessionDetailsViewModel = viewModel
        userSessionDetailsViewHostingController = VectorHostingController(rootView: view)
    }    
    
    // MARK: - Public
    
    func start() {
        // TODO: change to showUserSessionOverview()
        showUserSessionDetails()
      }
    
    private func showUserSessionOverview() {
        // TODO: PSG-690
    }
    
    private func showUserSessionDetails() {
        self.navigationRouter.push(self.userSessionDetailsViewHostingController, animated: true, popCompletion: nil)
    }
    
    func toPresentable() -> UIViewController {
        return self.navigationRouter.toPresentable()
    }
    
    // MARK: - Private

}
