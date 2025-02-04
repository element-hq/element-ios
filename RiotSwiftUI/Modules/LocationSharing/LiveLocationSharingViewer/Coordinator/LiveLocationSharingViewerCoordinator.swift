//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
            .environmentObject(AvatarViewModel(avatarService: AvatarService(mediaManager: parameters.session.mediaManager)))
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
