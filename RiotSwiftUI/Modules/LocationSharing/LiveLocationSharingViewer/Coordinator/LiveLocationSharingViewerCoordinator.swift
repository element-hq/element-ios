//
// Copyright 2021 New Vector Ltd
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

import SwiftUI

struct LiveLocationSharingViewerCoordinatorParameters {
    let session: MXSession
    let roomId: String
    let navigationRouter: NavigationRouterType?
}

final class LiveLocationSharingViewerCoordinator: Coordinator, Presentable {
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: LiveLocationSharingViewerCoordinatorParameters
    private let navigationRouter: NavigationRouterType
    private let liveLocationSharingViewerHostingController: UIViewController
    private var liveLocationSharingViewerViewModel: LiveLocationSharingViewerViewModelProtocol
    
    private let shareLocationActivityControllerBuilder = ShareLocationActivityControllerBuilder()
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    var completion: (() -> Void)?
    
    // MARK: - Setup
    
    init(parameters: LiveLocationSharingViewerCoordinatorParameters) {
        self.parameters = parameters
        
        let service = LiveLocationSharingViewerService(session: parameters.session, roomId: parameters.roomId)
        
        let viewModel = LiveLocationSharingViewerViewModel(
            mapStyleURL: parameters.session.vc_homeserverConfiguration().tileServer.mapStyleURL,
            service: service
        )
        let view = LiveLocationSharingViewer(viewModel: viewModel.context)
            .addDependency(AvatarService.instantiate(mediaManager: parameters.session.mediaManager))
        liveLocationSharingViewerViewModel = viewModel
        liveLocationSharingViewerHostingController = VectorHostingController(rootView: view)
        
        navigationRouter = parameters.navigationRouter ?? NavigationRouter()
    }
    
    // MARK: - Public

    func start() {
        MXLog.debug("[LiveLocationSharingViewerCoordinator] did start.")
        liveLocationSharingViewerViewModel.completion = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[LiveLocationSharingViewerCoordinator] LiveLocationSharingViewerViewModel did complete with result: \(result).")
            switch result {
            case .done:
                self.completion?()
            case .share(let coordinate):
                self.presentLocationActivityController(with: coordinate)
            }
        }
        
        let viewController: UIViewController = liveLocationSharingViewerHostingController
        
        if navigationRouter.modules.count > 1 {
            navigationRouter.push(viewController, animated: true, popCompletion: nil)
        } else {
            navigationRouter.setRootModule(viewController)
        }
    }
    
    func toPresentable() -> UIViewController {
        navigationRouter.toPresentable()
            .vc_setModalFullScreen(true) // Set fullscreen as DSBottomSheet is not working with modal pan gesture recognizer
    }
    
    func presentLocationActivityController(with coordinate: CLLocationCoordinate2D) {
        let shareActivityController = shareLocationActivityControllerBuilder.build(with: coordinate)
        
        liveLocationSharingViewerHostingController.present(shareActivityController, animated: true)
    }
}
