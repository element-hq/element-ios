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
    let navigationRouter: NavigationRouterType
    let roomDataSource: MXKRoomDataSource
    let mediaManager: MXMediaManager
    let user: MXUser
}

final class LocationSharingCoordinator: Coordinator {
    
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
    
    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    // MARK: - Setup
    
    @available(iOS 14.0, *)
    init(parameters: LocationSharingCoordinatorParameters) {
        self.parameters = parameters

        let avatarData = AvatarInput(mxContentUri: parameters.user.avatarUrl,
                                     matrixItemId: parameters.user.userId,
                                     displayName: parameters.user.displayname)
        
        let viewModel = LocationSharingViewModel(accessToken: "bDAfUcrMPWTAB1KB38r6", avatarData: avatarData)
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
        
        parameters.navigationRouter.present(locationSharingHostingController, animated: true)
        
        locationSharingViewModel.completion = { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .cancel:
                self.parameters.navigationRouter.dismissModule(animated: true, completion: nil)
            case .share(let latitude, let longitude):
                self.locationSharingViewModel.dispatch(action: .startLoading)
                
                self.parameters.roomDataSource.sendLocation(withLatitude: latitude,
                                                            longitude: longitude,
                                                            description: nil) { [weak self] _ in
                    guard let self = self else { return }
                    
                    self.parameters.navigationRouter.dismissModule(animated: true, completion: nil)
                    self.locationSharingViewModel.dispatch(action: .stopLoading(nil))
                } failure: { [weak self] error in
                    guard let self = self else { return }
                    
                    MXLog.error("[LocationSharingCoordinator] Failed sharing location with error: \(String(describing: error))")
                    self.locationSharingViewModel.dispatch(action: .stopLoading(error))
                }
            }
            
        }
    }
}
