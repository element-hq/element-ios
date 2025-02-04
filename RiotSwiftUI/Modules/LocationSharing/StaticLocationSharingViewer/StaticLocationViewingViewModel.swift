//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import CoreLocation
import SwiftUI

typealias StaticLocationViewingViewModelType = StateStoreViewModel<StaticLocationViewingViewState, StaticLocationViewingViewAction>

class StaticLocationViewingViewModel: StaticLocationViewingViewModelType, StaticLocationViewingViewModelProtocol {
    // MARK: - Properties

    // MARK: Private
    
    private var staticLocationSharingViewerService: StaticLocationSharingViewerServiceProtocol
    private var mapViewErrorAlertInfoBuilder: MapViewErrorAlertInfoBuilder

    // MARK: Public
    
    var completion: ((StaticLocationViewingViewModelResult) -> Void)?
    
    // MARK: - Setup
    
    init(mapStyleURL: URL, avatarData: AvatarInputProtocol, location: CLLocationCoordinate2D, coordinateType: LocationSharingCoordinateType, service: StaticLocationSharingViewerServiceProtocol) {
        
        staticLocationSharingViewerService = service
        
        let sharedAnnotation: LocationAnnotation
        switch coordinateType {
        case .user:
            sharedAnnotation = UserLocationAnnotation(avatarData: avatarData, coordinate: location)
        case .pin:
            sharedAnnotation = PinLocationAnnotation(coordinate: location)
        }
        
        let viewState = StaticLocationViewingViewState(mapStyleURL: mapStyleURL,
                                                       userAvatarData: avatarData,
                                                       sharedAnnotation: sharedAnnotation)
        
        mapViewErrorAlertInfoBuilder = MapViewErrorAlertInfoBuilder()
        
        super.init(initialViewState: viewState)
        
        state.errorSubject.sink { [weak self] error in
            guard let self = self else { return }
            self.processError(error)
        }.store(in: &cancellables)
    }

    // MARK: - Public

    override func process(viewAction: StaticLocationViewingViewAction) {
        switch viewAction {
        case .close:
            completion?(.close)
        case .share:
            completion?(.share(state.sharedAnnotation.coordinate))
        case .showUserLocation:
            showsCurrentUserLocation()
        }
    }
    
    // MARK: - Private
    
    private func processError(_ error: LocationSharingViewError) {
        guard state.bindings.alertInfo == nil else {
            return
        }
        
        let alertInfo = mapViewErrorAlertInfoBuilder.build(with: error) { [weak self] in
            
            switch error {
            case .invalidLocationAuthorization:
                if let applicationSettingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(applicationSettingsURL)
                } else {
                    self?.completion?(.close)
                }
            default:
                self?.completion?(.close)
            }
        }
        
        state.bindings.alertInfo = alertInfo
    }
    
    private func showsCurrentUserLocation() {
        if staticLocationSharingViewerService.requestAuthorizationIfNeeded() {
            state.showsUserLocationMode = .follow
        } else {
            state.errorSubject.send(.invalidLocationAuthorization)
        }
    }
}
