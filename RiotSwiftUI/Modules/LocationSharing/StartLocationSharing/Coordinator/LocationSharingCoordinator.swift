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
import MatrixSDK
import SwiftUI
import UIKit

struct LocationSharingCoordinatorParameters {
    let session: MXSession
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
    
    init(parameters: LocationSharingCoordinatorParameters) {
        self.parameters = parameters
        
        let locationSharingService = LocationSharingService(session: parameters.roomDataSource.mxSession)
        
        let viewModel = LocationSharingViewModel(
            mapStyleURL: parameters.session.vc_homeserverConfiguration().tileServer.mapStyleURL,
            avatarData: parameters.avatarData,
            isLiveLocationSharingEnabled: true,
            service: locationSharingService
        )
        
        let view = LocationSharingView(context: viewModel.context)
            .addDependency(AvatarService.instantiate(mediaManager: parameters.mediaManager))
        
        locationSharingViewModel = viewModel
        locationSharingHostingController = VectorHostingController(rootView: view)
    }
    
    // MARK: - Public

    func start() {
        locationSharingViewModel.completion = { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .cancel:
                self.completion?()
            case .share(let latitude, let longitude, let coordinateType):
                self.shareStaticLocation(latitude: latitude, longitude: longitude, coordinateType: coordinateType)
                self.completion?()
            case .shareLiveLocation(let timeout):
                self.startLiveLocationSharing(with: timeout)
                self.completion?()
            case .checkLiveLocationCanBeStarted(let completion):
                self.checkLiveLocationCanBeStarted(completion: completion)
            }
        }
    }
    
    static func shareLocationActivityController(_ location: CLLocationCoordinate2D) -> UIActivityViewController {
        UIActivityViewController(activityItems: [ShareToMapsAppActivity.urlForMapsAppType(.apple, location: location)],
                                 applicationActivities: [ShareToMapsAppActivity(type: .apple, location: location),
                                                         ShareToMapsAppActivity(type: .google, location: location),
                                                         ShareToMapsAppActivity(type: .osm, location: location)])
    }
    
    // MARK: - Private
    
    private func presentShareLocationActivity(with location: CLLocationCoordinate2D) {
        locationSharingHostingController.present(Self.shareLocationActivityController(location), animated: true)
    }
    
    private func shareStaticLocation(latitude: Double, longitude: Double, coordinateType: LocationSharingCoordinateType) {
        parameters.roomDataSource.sendLocation(withLatitude: latitude, longitude: longitude, description: nil, coordinateType: coordinateType.eventAssetType()) { _ in
        } failure: { error in
            MXLog.error("[LocationSharingCoordinator] Failed sharing location", context: error)
        }
    }
    
    private func startLiveLocationSharing(with timeout: TimeInterval) {
        guard let locationService = parameters.roomDataSource.mxSession.locationService, let roomId = parameters.roomDataSource.roomId else {
            return
        }
        
        locationService.startUserLocationSharing(withRoomId: roomId, description: nil, timeout: timeout) { response in
            switch response {
            case .success:
                break
            case .failure(let error):
                MXLog.error("[LocationSharingCoordinator] Failed to start live location sharing", context: error)
            }
        }
    }
    
    private func checkLiveLocationCanBeStarted(completion: @escaping ((Result<Void, Error>) -> Void)) {
        guard canShareLiveLocation() else {
            completion(.failure(LiveLocationStartError.powerLevelNotHighEnough))
            return
        }

        showLabFlagPromotionIfNeeded { labFlagEnabled in
            
            if labFlagEnabled {
                completion(.success(()))
            } else {
                completion(.failure(LiveLocationStartError.labFlagNotEnabled))
            }
        }
    }
    
    // Check if user can send beacon info state event
    private func canShareLiveLocation() -> Bool {
        guard let myUserId = parameters.roomDataSource.mxSession.myUserId else {
            return false
        }
        
        let userPowerLevelRawValue = parameters.roomDataSource.roomState.powerLevels.powerLevelOfUser(withUserID: myUserId)
        
        guard let userPowerLevel = RoomPowerLevel(rawValue: userPowerLevelRawValue) else {
            return false
        }
        
        return userPowerLevel.rawValue >= RoomPowerLevel.moderator.rawValue
    }
    
    private func showLabFlagPromotionIfNeeded(completion: @escaping ((Bool) -> Void)) {
        guard RiotSettings.shared.enableLiveLocationSharing == false else {
            // Live location sharing lab flag is already enabled, do not present lab flag promotion screen
            completion(true)
            return
        }
        
        showLabFlagPromotion(completion: completion)
    }
    
    private func showLabFlagPromotion(completion: @escaping ((Bool) -> Void)) {
        // TODO: Use a NavigationRouter instead of using NavigationView inside LocationSharingView
        // In order to use `NavigationRouter.present`
        
        let coordinator = LiveLocationLabPromotionCoordinator()
        coordinator.start()
        
        coordinator.completion = { [weak self, weak coordinator] enableLiveLocation in
            guard let self = self, let coordinator = coordinator else { return }
            completion(enableLiveLocation)
            
            coordinator.toPresentable().dismiss(animated: true) {
                self.remove(childCoordinator: coordinator)
            }
        }
        
        locationSharingHostingController.present(coordinator.toPresentable(), animated: true)
        
        add(childCoordinator: coordinator)
    }
    
    // MARK: - Presentable
    
    func toPresentable() -> UIViewController {
        locationSharingHostingController
    }
}
