//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixSDK
import SwiftUI
import UIKit

struct StaticLocationViewingCoordinatorParameters {
    let session: MXSession
    let mediaManager: MXMediaManager
    let avatarData: AvatarInputProtocol
    let location: CLLocationCoordinate2D
    let coordinateType: LocationSharingCoordinateType
}

final class StaticLocationViewingCoordinator: Coordinator, Presentable {
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: StaticLocationViewingCoordinatorParameters
    private let staticLocationViewingHostingController: UIViewController
    private var staticLocationViewingViewModel: StaticLocationViewingViewModelProtocol
    
    private let shareLocationActivityControllerBuilder = ShareLocationActivityControllerBuilder()
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: (() -> Void)?
    
    // MARK: - Setup
    
    init(parameters: StaticLocationViewingCoordinatorParameters) {
        self.parameters = parameters

        let viewModel = StaticLocationViewingViewModel(
            mapStyleURL: parameters.session.vc_homeserverConfiguration().tileServer.mapStyleURL,
            avatarData: parameters.avatarData,
            location: parameters.location,
            coordinateType: parameters.coordinateType,
            service: StaticLocationSharingViewerService()
        )
        let view = StaticLocationView(viewModel: viewModel.context)
            .environmentObject(AvatarViewModel(avatarService: AvatarService(mediaManager: parameters.mediaManager)))

        staticLocationViewingViewModel = viewModel
        staticLocationViewingHostingController = VectorHostingController(rootView: view)
    }
    
    // MARK: - Public

    func start() {
        MXLog.debug("[StaticLocationSharingViewerCoordinator] did start.")
        staticLocationViewingViewModel.completion = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[StaticLocationSharingViewerCoordinator] StaticLocationSharingViewerViewModel did complete with result: \(result).")
            switch result {
            case .close:
                self.completion?()
            case .share(let coordinate):
                self.presentLocationActivityController(with: coordinate)
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        staticLocationViewingHostingController
    }
    
    func presentLocationActivityController(with coordinate: CLLocationCoordinate2D) {
        let shareActivityController = shareLocationActivityControllerBuilder.build(with: coordinate)
        
        staticLocationViewingHostingController.present(shareActivityController, animated: true)
    }
}
