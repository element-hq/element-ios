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

struct LocationSharingCoordinatorParameters {
    let roomDataSource: MXKRoomDataSource
    let mediaManager: MXMediaManager
    let avatarData: AvatarInputProtocol
    let location: CLLocationCoordinate2D?
}

final class LocationSharingCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: LocationSharingCoordinatorParameters
    private let locationSharingHostingController: UIViewController
    private var locationSharingViewModel: LocationSharingViewModelProtocol
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    var completion: (() -> Void)?
    
    // MARK: - Setup
    
    @available(iOS 14.0, *)
    init(parameters: LocationSharingCoordinatorParameters) {
        self.parameters = parameters
        
        let viewModel = LocationSharingViewModel(mapStyleURL: BuildSettings.tileServerMapStyleURL,
                                                 avatarData: parameters.avatarData,
                                                 location: parameters.location,
                                                 isLiveLocationSharingEnabled: BuildSettings.liveLocationSharingEnabled)
        let view = LocationSharingView(context: viewModel.context)
            .addDependency(AvatarService.instantiate(mediaManager: parameters.mediaManager))
        
        locationSharingViewModel = viewModel
        locationSharingHostingController = VectorHostingController(rootView: view)
    }
    
    // MARK: - Public
    func start() {
        guard #available(iOS 14.0, *) else {
            MXLog.error("[LocationSharingCoordinator] start: Invalid iOS version, returning.")
            return
        }
        
        locationSharingViewModel.completion = { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .cancel:
                self.completion?()
            case .share(let latitude, let longitude):
                
                // Show share sheet on existing location display
                if let location = self.parameters.location {
                    self.locationSharingHostingController.present(Self.shareLocationActivityController(location), animated: true)
                    return
                }
                
                self.locationSharingViewModel.startLoading()
                
                self.parameters.roomDataSource.sendLocation(withLatitude: latitude, longitude: longitude, description: nil) { [weak self] _ in
                    guard let self = self else { return }
                    
                    self.locationSharingViewModel.stopLoading()
                    self.completion?()
                } failure: { [weak self] error in
                    guard let self = self else { return }
                    
                    MXLog.error("[LocationSharingCoordinator] Failed sharing location with error: \(String(describing: error))")
                    self.locationSharingViewModel.stopLoading(error: .locationSharingError)
                }
            }
            
        }
    }
    
    static func shareLocationActivityController(_ location: CLLocationCoordinate2D) -> UIActivityViewController {
        return UIActivityViewController(activityItems: [ShareToMapsAppActivity.urlForMapsAppType(.apple, location: location)],
                                        applicationActivities: [ShareToMapsAppActivity(type: .apple, location: location),
                                                                ShareToMapsAppActivity(type: .google, location: location),
                                                                ShareToMapsAppActivity(type: .osm, location: location)])
    }
    
    // MARK: - Presentable
    
    func toPresentable() -> UIViewController {
        return locationSharingHostingController
    }
}
