//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import CoreLocation
import SwiftUI

typealias LocationSharingViewModelType = StateStoreViewModel<LocationSharingViewState, LocationSharingViewAction>

class LocationSharingViewModel: LocationSharingViewModelType, LocationSharingViewModelProtocol {
    // MARK: - Properties
    
    // MARK: Private
    
    private let locationSharingService: LocationSharingServiceProtocol
    
    // MARK: Public
    
    var completion: ((LocationSharingViewModelResult) -> Void)?
    
    // MARK: - Setup
    
    init(mapStyleURL: URL, avatarData: AvatarInputProtocol, isLiveLocationSharingEnabled: Bool = false, service: LocationSharingServiceProtocol) {
        locationSharingService = service
        
        let viewState = LocationSharingViewState(mapStyleURL: mapStyleURL,
                                                 userAvatarData: avatarData,
                                                 annotations: [],
                                                 highlightedAnnotation: nil,
                                                 showsUserLocationMode: .follow,
                                                 isLiveLocationSharingEnabled: isLiveLocationSharingEnabled)
        
        super.init(initialViewState: viewState)
        
        state.errorSubject.sink { [weak self] error in
            guard let self = self else { return }
            self.processError(error)
        }.store(in: &cancellables)
    }
    
    // MARK: - Public
    
    override func process(viewAction: LocationSharingViewAction) {
        switch viewAction {
        case .cancel:
            completion?(.cancel)
        case .share:
            // Share current user location
            guard let location = state.bindings.userLocation else {
                processError(.failedLocatingUser)
                return
            }
            
            completion?(.share(latitude: location.latitude, longitude: location.longitude, coordinateType: .user))
        case .sharePinLocation:
            guard let pinLocation = state.bindings.pinLocation else {
                processError(.failedLocatingUser)
                return
            }
            
            completion?(.share(latitude: pinLocation.latitude, longitude: pinLocation.longitude, coordinateType: .pin))
        case .goToUserLocation:
            state.showsUserLocationMode = .follow
            state.isPinDropSharing = false
        case .startLiveSharing:
            startLiveLocationSharing()
        case .shareLiveLocation(let timeout):
            state.bindings.showingTimerSelector = false
            completion?(.shareLiveLocation(timeout: timeout.rawValue))
        case .userDidPan:
            state.showsUserLocationMode = .hide
            state.isPinDropSharing = true
        case .mapCreditsDidTap:
            state.bindings.showMapCreditsSheet.toggle()
        }
    }
    
    // MARK: - LocationSharingViewModelProtocol
    
    public func startLoading() {
        state.showLoadingIndicator = true
    }
    
    func stopLoading(error: LocationSharingAlertType?) {
        state.showLoadingIndicator = false
        
        if let error = error {
            let alertInfo: AlertInfo<LocationSharingAlertType>
            
            switch error {
            case .locationSharingPowerLevelError:
                alertInfo = AlertInfo(id: error,
                                      title: VectorL10n.locationSharingInvalidPowerLevelTitle,
                                      message: VectorL10n.locationSharingInvalidPowerLevelMessage,
                                      primaryButton: (VectorL10n.ok, nil))
            default:
                alertInfo = AlertInfo(id: error,
                                      title: VectorL10n.locationSharingPostFailureTitle,
                                      message: VectorL10n.locationSharingPostFailureSubtitle(AppInfo.current.displayName),
                                      primaryButton: (VectorL10n.ok, nil))
            }
            
            state.bindings.alertInfo = alertInfo
        }
    }
    
    // MARK: - Private
    
    private func processError(_ error: LocationSharingViewError) {
        guard state.bindings.alertInfo == nil else {
            return
        }
        
        let primaryButtonCompletion: (() -> Void)? = { [weak self] () in
            self?.completion?(.cancel)
        }
        
        switch error {
        case .failedLoadingMap:
            state.bindings.alertInfo = AlertInfo(id: .mapLoadingError,
                                                 title: VectorL10n.locationSharingLoadingMapErrorTitle(AppInfo.current.displayName),
                                                 primaryButton: (VectorL10n.ok, primaryButtonCompletion))
            
            state.showMapLoadingError = true
            
        case .failedLocatingUser:
            state.bindings.alertInfo = AlertInfo(id: .userLocatingError,
                                                 title: VectorL10n.locationSharingLocatingUserErrorTitle(AppInfo.current.displayName),
                                                 primaryButton: (VectorL10n.ok, primaryButtonCompletion))
        case .invalidLocationAuthorization:
            state.bindings.alertInfo = AlertInfo(id: .authorizationError,
                                                 title: VectorL10n.locationSharingInvalidAuthorizationErrorTitle(AppInfo.current.displayName),
                                                 primaryButton: (VectorL10n.locationSharingInvalidAuthorizationNotNow, primaryButtonCompletion),
                                                 secondaryButton: (VectorL10n.locationSharingInvalidAuthorizationSettings, {
                                                     UIApplication.shared.vc_openSettings()
                                                 }))
        default:
            break
        }
    }
    
    private func checkLocationAuthorizationAndPresentTimerSelector() {
        locationSharingService.requestAuthorization { [weak self] authorizationStatus in
            
            guard let self = self else {
                return
            }
            
            switch authorizationStatus {
            case .unknown, .denied:
                // Show error alert
                self.state.bindings.alertInfo = AlertInfo(id: .userLocatingError,
                                                          title: VectorL10n.locationSharingLocatingUserErrorTitle(AppInfo.current.displayName),
                                                          primaryButton: (VectorL10n.ok, { UIApplication.shared.vc_openSettings()
                                                          }))
            case .authorizedInForeground:
                // When user only authorized location in foreground, advize to use background location
                self.state.bindings.alertInfo = AlertInfo(id: .userLocatingError,
                                                          title: VectorL10n.locationSharingAllowBackgroundLocationTitle,
                                                          message: VectorL10n.locationSharingAllowBackgroundLocationMessage,
                                                          primaryButton: (VectorL10n.locationSharingAllowBackgroundLocationCancelAction, { }),
                                                          secondaryButton: (VectorL10n.locationSharingAllowBackgroundLocationValidateAction, { UIApplication.shared.vc_openSettings() }))
            case .authorizedAlways:
                self.state.bindings.showingTimerSelector = true
            }
        }
    }
    
    private func startLiveLocationSharing() {
        guard let completion = completion else {
            return
        }
        
        completion(.checkLiveLocationCanBeStarted { result in
            
            switch result {
            case .success:
                self.checkLocationAuthorizationAndPresentTimerSelector()
            case .failure(let error):
                if case LiveLocationStartError.powerLevelNotHighEnough = error {
                    self.stopLoading(error: .locationSharingPowerLevelError)
                }
            }
        })
    }
}
