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
    
    init(mapStyleURL: URL, avatarData: AvatarInputProtocol, location: CLLocationCoordinate2D? = nil) {
        let viewState = LocationSharingViewState(mapStyleURL: mapStyleURL, avatarData: avatarData, location: location)
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
            if let location = state.location {
                completion?(.share(latitude: location.latitude, longitude: location.longitude))
                return
            }
            
            guard let location = state.bindings.userLocation else {
                processError(.failedLocatingUser)
                return
            }
            
            completion?(.share(latitude: location.latitude, longitude: location.longitude))
        }
    }
    
    // MARK: - LocationSharingViewModelProtocol
    
    public func startLoading() {
        state.showLoadingIndicator = true
    }
    
    func stopLoading(error: LocationSharingErrorAlertInfo.AlertType?) {
        state.showLoadingIndicator = false
        
        if let error = error {
            state.bindings.alertInfo = LocationSharingErrorAlertInfo(id: error,
                                                                     title: VectorL10n.locationSharingPostFailureTitle,
                                                                     subtitle: VectorL10n.locationSharingPostFailureSubtitle(AppInfo.current.displayName),
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
            state.bindings.alertInfo = LocationSharingErrorAlertInfo(id: .mapLoadingError,
                                                                     title: VectorL10n.locationSharingLoadingMapErrorTitle(AppInfo.current.displayName),
                                                                     primaryButton: (VectorL10n.ok, primaryButtonCompletion))
        case .failedLocatingUser:
            state.bindings.alertInfo = LocationSharingErrorAlertInfo(id: .userLocatingError,
                                                                     title: VectorL10n.locationSharingLocatingUserErrorTitle(AppInfo.current.displayName),
                                                                     primaryButton: (VectorL10n.ok, primaryButtonCompletion))
        case .invalidLocationAuthorization:
            state.bindings.alertInfo = LocationSharingErrorAlertInfo(id: .authorizationError,
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
