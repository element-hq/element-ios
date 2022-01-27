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
    private var _locationSharingViewModel: Any? = nil
    
    @available(iOS 14.0, *)
    fileprivate var locationSharingViewModel: LocationSharingViewModel {
        return _locationSharingViewModel as! LocationSharingViewModel
    }
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    var completion: (() -> Void)?
    
    // MARK: - Setup
    
    @available(iOS 14.0, *)
    init(parameters: LocationSharingCoordinatorParameters) {
        self.parameters = parameters
        
        let viewModel = LocationSharingViewModel(tileServerMapURL: BuildSettings.tileServerMapURL,
                                                 avatarData: parameters.avatarData,
                                                 location: parameters.location)
        let view = LocationSharingView(context: viewModel.context)
            .addDependency(AvatarService.instantiate(mediaManager: parameters.mediaManager))
        
        _locationSharingViewModel = viewModel
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
                if let location = self.parameters.location {
                    self.showActivityControllerForLocation(location)
                    return
                }
                
                self.locationSharingViewModel.dispatch(action: .startLoading)
                
                self.parameters.roomDataSource.sendLocation(withLatitude: latitude,
                                                            longitude: longitude,
                                                            description: nil) { [weak self] _ in
                    guard let self = self else { return }
                    
                    self.locationSharingViewModel.dispatch(action: .stopLoading(nil))
                    self.completion?()
                } failure: { [weak self] error in
                    guard let self = self else { return }
                    
                    MXLog.error("[LocationSharingCoordinator] Failed sharing location with error: \(String(describing: error))")
                    self.locationSharingViewModel.dispatch(action: .stopLoading(error))
                }
            }
            
        }
    }
    
    // MARK: - Presentable
    
    func toPresentable() -> UIViewController {
        return locationSharingHostingController
    }
    
    // MARK: - Private
    
    private func showActivityControllerForLocation(_ location: CLLocationCoordinate2D) {   
        let vc = UIActivityViewController(activityItems: [ShareToMapsAppActivity.urlForMapsAppType(.apple, location: location)],
                                          applicationActivities: [ShareToMapsAppActivity(type: .apple, location: location),
                                                                  ShareToMapsAppActivity(type: .google, location: location)])
        
        locationSharingHostingController.present(vc, animated: true)
    }
}
