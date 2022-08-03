// 
// Copyright 2022 New Vector Ltd
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

struct MapViewErrorAlertInfoBuilder {
    
    func build(with error: LocationSharingViewError, primaryButtonCompletion: (() -> Void)?) -> AlertInfo<LocationSharingAlertType>? {
        
        let alertInfo: AlertInfo<LocationSharingAlertType>?
        
        switch error {
        case .failedLoadingMap:
            alertInfo = AlertInfo(id: .mapLoadingError,
                                                 title: VectorL10n.locationSharingLoadingMapErrorTitle(AppInfo.current.displayName),
                                                 primaryButton: (VectorL10n.ok, primaryButtonCompletion))
        case .failedLocatingUser:
            alertInfo = AlertInfo(id: .userLocatingError,
                                                 title: VectorL10n.locationSharingLocatingUserErrorTitle(AppInfo.current.displayName),
                                                 primaryButton: (VectorL10n.ok, primaryButtonCompletion))
        case .invalidLocationAuthorization:
            alertInfo = AlertInfo(id: .authorizationError,
                                                 title: VectorL10n.locationSharingInvalidAuthorizationErrorTitle(AppInfo.current.displayName),
                                                 primaryButton: (VectorL10n.locationSharingInvalidAuthorizationNotNow, primaryButtonCompletion),
                                                 secondaryButton: (VectorL10n.locationSharingInvalidAuthorizationSettings, primaryButtonCompletion))
        default:
            alertInfo = nil
        }
        
        return alertInfo
    }
    
}
