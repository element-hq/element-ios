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

struct StaticLocationSharingViewerCoordinatorParameters {
    let roomDataSource: MXKRoomDataSource
    let mediaManager: MXMediaManager
    let avatarData: AvatarInputProtocol
    let location: CLLocationCoordinate2D
    let coordinateType: LocationSharingCoordinateType
}

final class StaticLocationSharingViewerCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: StaticLocationSharingViewerCoordinatorParameters
    private let staticLocationSharingViewerHostingController: UIViewController
    private var staticLocationSharingViewerViewModel: StaticLocationSharingViewerViewModelProtocol
    
    private let shareLocationActivityControllerBuilder = ShareLocationActivityControllerBuilder()
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: (() -> Void)?
    
    // MARK: - Setup
    
    @available(iOS 14.0, *)
    init(parameters: StaticLocationSharingViewerCoordinatorParameters) {
        self.parameters = parameters
        
        let viewModel = StaticLocationSharingViewerViewModel(mapStyleURL: BuildSettings.tileServerMapStyleURL,
                                                             avatarData: parameters.avatarData,
                                                             location: parameters.location,
                                                             coordinateType: parameters.coordinateType)
        let view = StaticLocationSharingViewer(viewModel: viewModel.context)
        staticLocationSharingViewerViewModel = viewModel
        staticLocationSharingViewerHostingController = VectorHostingController(rootView: view)
    }
    
    // MARK: - Public
    func start() {
        MXLog.debug("[StaticLocationSharingViewerCoordinator] did start.")
        staticLocationSharingViewerViewModel.completion = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[StaticLocationSharingViewerCoordinator] StaticLocationSharingViewerViewModel did complete with result: \(result).")
            switch result {
            case .cancel:
                self.completion?()
            case .share(let coordinate):
                self.presentLocationActivityController(with: coordinate)
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.staticLocationSharingViewerHostingController
    }
    
    func presentLocationActivityController(with coordinate: CLLocationCoordinate2D) {
        
        let shareActivityController = shareLocationActivityControllerBuilder.build(with: coordinate)
        
        self.staticLocationSharingViewerHostingController.present(shareActivityController, animated: true)
    }
}
