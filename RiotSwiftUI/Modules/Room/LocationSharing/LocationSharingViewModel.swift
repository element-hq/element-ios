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

import SwiftUI
import Combine
import CoreLocation

@available(iOS 14, *)
typealias LocationSharingViewModelType = StateStoreViewModel<LocationSharingViewState,
                                                             Never,
                                                             LocationSharingViewAction>
@available(iOS 14, *)
class LocationSharingViewModel: LocationSharingViewModelType, LocationSharingViewModelProtocol {
    
    // MARK: - Properties
    
    // MARK: Private
    
    // MARK: Public
    
    var completion: ((LocationSharingViewModelResult) -> Void)?
    
    // MARK: - Setup
    
    init(mapStyleURL: URL, avatarData: AvatarInputProtocol, isLiveLocationSharingEnabled: Bool = false) {
        let viewState = LocationSharingViewState(mapStyleURL: mapStyleURL,
                                                 userAvatarData: avatarData,
                                                 annotations: [],
                                                 highlightedAnnotation: nil,
                                                 showsUserLocation: true,
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
            state.bindings.pinLocation = nil
        case .startLiveSharing:
            state.bindings.showingTimerSelector = true
        case .shareLiveLocation(let timeout):
            state.bindings.showingTimerSelector = false
            completion?(.shareLiveLocation(timeout: timeout.rawValue))
        }
    }
    
    // MARK: - LocationSharingViewModelProtocol
    
    public func startLoading() {
        state.showLoadingIndicator = true
    }
    
    func stopLoading(error: LocationSharingAlertType?) {
        state.showLoadingIndicator = false
        
        if let error = error {
            state.bindings.alertInfo = AlertInfo(id: error,
                                                 title: VectorL10n.locationSharingPostFailureTitle,
                                                 message: VectorL10n.locationSharingPostFailureSubtitle(AppInfo.current.displayName),
                                                 primaryButton: (VectorL10n.ok, nil))
        }
    }
    
    // MARK: - Private
    
    private func processError(_ error: LocationSharingViewError) {
        guard state.bindings.alertInfo == nil else {
            return
        }
        
        let primaryButtonCompletion = { [weak self] () -> Void in
            self?.completion?(.cancel)
        }
        
        switch error {
        case .failedLoadingMap:
            state.bindings.alertInfo = AlertInfo(id: .mapLoadingError,
                                                 title: VectorL10n.locationSharingLoadingMapErrorTitle(AppInfo.current.displayName),
                                                 primaryButton: (VectorL10n.ok, primaryButtonCompletion))
        case .failedLocatingUser:
            state.bindings.alertInfo = AlertInfo(id: .userLocatingError,
                                                 title: VectorL10n.locationSharingLocatingUserErrorTitle(AppInfo.current.displayName),
                                                 primaryButton: (VectorL10n.ok, primaryButtonCompletion))
        case .invalidLocationAuthorization:
            state.bindings.alertInfo = AlertInfo(id: .authorizationError,
                                                 title: VectorL10n.locationSharingInvalidAuthorizationErrorTitle(AppInfo.current.displayName),
                                                 primaryButton: (VectorL10n.locationSharingInvalidAuthorizationNotNow, primaryButtonCompletion),
                                                 secondaryButton: (VectorL10n.locationSharingInvalidAuthorizationSettings, {
                if let applicationSettingsURL = URL(string:UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(applicationSettingsURL)
                }
            }))
        default:
            break
        }
    }
}
