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

struct LocationSharingCoordinatorParameters {
    let roomDataSource: MXKRoomDataSource
    let mediaManager: MXMediaManager
    let avatarData: AvatarInputProtocol
}

// Map between type from MatrixSDK and type from SwiftUI target, as we don't want
// to add the SDK as a dependency to it. We need to translate from one to the other on this level.
extension MXEventAssetType {
    func locationSharingCoordinateType() -> LocationSharingCoordinateType? {
        let coordinateType: LocationSharingCoordinateType?
        switch self {
        case .user:
            coordinateType = .user
        case .pin:
            coordinateType = .pin
        default:
            coordinateType = nil
        }
        return coordinateType
    }
}

extension LocationSharingCoordinateType {
    func eventAssetType() -> MXEventAssetType {
        let eventAssetType: MXEventAssetType
        switch self {
        case .user:
            eventAssetType = .user
        case .pin:
            eventAssetType = .pin
        }
        return eventAssetType
    }
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
        
        
        let locationSharingService = LocationSharingService(userLocationService: parameters.roomDataSource.mxSession.userLocationService)
        
        let viewModel = LocationSharingViewModel(mapStyleURL: BuildSettings.tileServerMapStyleURL,
                                                 avatarData: parameters.avatarData,
                                                 isLiveLocationSharingEnabled: RiotSettings.shared.enableLiveLocationSharing, service: locationSharingService)
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
            case .share(let latitude, let longitude, let coordinateType):
                self.shareStaticLocation(latitude: latitude, longitude: longitude, coordinateType: coordinateType)
            case .shareLiveLocation(let timeout):
                self.startLiveLocationSharing(with: timeout)
            }
        }
    }
    
    static func shareLocationActivityController(_ location: CLLocationCoordinate2D) -> UIActivityViewController {
        return UIActivityViewController(activityItems: [ShareToMapsAppActivity.urlForMapsAppType(.apple, location: location)],
                                        applicationActivities: [ShareToMapsAppActivity(type: .apple, location: location),
                                                                ShareToMapsAppActivity(type: .google, location: location),
                                                                ShareToMapsAppActivity(type: .osm, location: location)])
    }
    
    // MARK: - Private
    
    private func presentShareLocationActivity(with location: CLLocationCoordinate2D) {
        self.locationSharingHostingController.present(Self.shareLocationActivityController(location), animated: true)
    }
    
    private func shareStaticLocation(latitude: Double, longitude: Double, coordinateType: LocationSharingCoordinateType) {
        self.locationSharingViewModel.startLoading()
        
        self.parameters.roomDataSource.sendLocation(withLatitude: latitude, longitude: longitude, description: nil, coordinateType: coordinateType.eventAssetType()) { [weak self] _ in
            guard let self = self else { return }
            
            self.locationSharingViewModel.stopLoading()
            self.completion?()
        } failure: { [weak self] error in
            guard let self = self else { return }
            
            MXLog.error("[LocationSharingCoordinator] Failed sharing location with error: \(String(describing: error))")
            self.locationSharingViewModel.stopLoading(error: .locationSharingError)
        }
    }
    
    private func startLiveLocationSharing(with timeout: TimeInterval) {
        guard let locationService = self.parameters.roomDataSource.mxSession.locationService, let roomId = self.parameters.roomDataSource.roomId else {
            self.locationSharingViewModel.stopLoading(error: .locationSharingError)
            return
        }
        
        locationService.startUserLocationSharing(withRoomId: roomId, description: nil, timeout: timeout) { [weak self] response in
            guard let self = self else { return }
            
            switch response {
            case .success:
                
                DispatchQueue.main.async {
                    self.locationSharingViewModel.stopLoading()
                    self.completion?()
                }
            case .failure(let error):
                MXLog.error("[LocationSharingCoordinator] Failed to start live location sharing with error: \(String(describing: error))")
                
                DispatchQueue.main.async {
                    self.locationSharingViewModel.stopLoading(error: .locationSharingError)
                }
            }
        }
    }
    
    // MARK: - Presentable
    
    func toPresentable() -> UIViewController {
        return locationSharingHostingController
    }
}
