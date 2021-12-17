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

@available(iOS 14, *)
typealias LocationSharingViewModelType = StateStoreViewModel< LocationSharingViewState,
                                                              LocationSharingStateAction,
                                                              LocationSharingViewAction >
@available(iOS 14, *)
class LocationSharingViewModel: LocationSharingViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    // MARK: Public
    
    let tileServerMapURL: URL
    let avatarData: AvatarInputProtocol
    
    var completion: ((LocationSharingViewModelResult) -> Void)?
    
    // MARK: - Setup
    
    init(tileServerMapURL: URL, avatarData: AvatarInputProtocol) {
        self.tileServerMapURL = tileServerMapURL
        self.avatarData = avatarData
        
        super.init(initialViewState: LocationSharingViewState(tileServerMapURL: tileServerMapURL, avatarData: avatarData))
        
        state.errorSubject.sink { [weak self] error in
            guard let self = self else { return }
            self.dispatch(action: .error(error, self.completion))
        }.store(in: &cancellables)
    }
    
    // MARK: - Public
    
    override func process(viewAction: LocationSharingViewAction) {
        switch viewAction {
        case .cancel:
            completion?(.cancel)
        case .share:
            guard let location = state.bindings.userLocation else {
                dispatch(action: .error(.failedLocatingUser, completion))
                return
            }
            
            completion?(.share(location.latitude, location.longitude))
        }
    }
    
    override class func reducer(state: inout LocationSharingViewState, action: LocationSharingStateAction) {
        switch action {
        case .error(let error, let completion):
            
            switch error {
            case .failedLoadingMap:
                state.bindings.alertInfo = ErrorAlertInfo(id: .mapLoadingError,
                                                          title: VectorL10n.locationSharingLoadingMapErrorTitle,
                                                          primaryButton: (VectorL10n.ok, { completion?(.cancel) }),
                                                          secondaryButton: nil)
            case .failedLocatingUser:
                state.bindings.alertInfo = ErrorAlertInfo(id: .userLocatingError,
                                                          title: VectorL10n.locationSharingLocatingUserErrorTitle,
                                                          primaryButton: (VectorL10n.ok, { completion?(.cancel) }),
                                                          secondaryButton: nil)
            case .invalidLocationAuthorization:
                state.bindings.alertInfo = ErrorAlertInfo(id: .authorizationError,
                                                          title: VectorL10n.locationSharingInvalidAuthorizationErrorTitle,
                                                          primaryButton: (VectorL10n.locationSharingInvalidAuthorizationNotNow, { completion?(.cancel) }),
                                                          secondaryButton: (VectorL10n.locationSharingInvalidAuthorizationSettings, {
                                                            if let applicationSettingsURL = URL(string:UIApplication.openSettingsURLString) {
                                                                UIApplication.shared.open(applicationSettingsURL)
                                                            }
                                                          }))
            default:
                break
            }
            
        case .startLoading:
            state.showLoadingIndicator = true
            state.shareButtonEnabled = false
        case .stopLoading(let error):
            state.showLoadingIndicator = false
            state.shareButtonEnabled = true
            
            if error != nil {
                state.bindings.alertInfo = ErrorAlertInfo(id: .locationSharingError,
                                                          title: VectorL10n.locationSharingInvalidAuthorizationErrorTitle,
                                                          primaryButton: (VectorL10n.ok, nil),
                                                          secondaryButton: nil)
            }
        }
    }
}
