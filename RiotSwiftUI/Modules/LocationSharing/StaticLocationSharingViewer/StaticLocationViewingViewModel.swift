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

import CoreLocation
import SwiftUI

typealias StaticLocationViewingViewModelType = StateStoreViewModel<StaticLocationViewingViewState, StaticLocationViewingViewAction>

class StaticLocationViewingViewModel: StaticLocationViewingViewModelType, StaticLocationViewingViewModelProtocol {
    // MARK: - Properties

    // MARK: Private
    
    private var mapViewErrorAlertInfoBuilder: MapViewErrorAlertInfoBuilder

    // MARK: Public
    
    var completion: ((StaticLocationViewingViewModelResult) -> Void)?
    
    // MARK: - Setup
    
    init(mapStyleURL: URL, avatarData: AvatarInputProtocol, location: CLLocationCoordinate2D, coordinateType: LocationSharingCoordinateType) {
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
}
