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

import Foundation
import UIKit
import SwiftUI
import MatrixSDK

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
            coordinateType: parameters.coordinateType)
        let view = StaticLocationView(viewModel: viewModel.context)
            .addDependency(AvatarService.instantiate(mediaManager: parameters.mediaManager))
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
        return self.staticLocationViewingHostingController
    }
    
    func presentLocationActivityController(with coordinate: CLLocationCoordinate2D) {
        
        let shareActivityController = shareLocationActivityControllerBuilder.build(with: coordinate)
        
        self.staticLocationViewingHostingController.present(shareActivityController, animated: true)
    }
}
