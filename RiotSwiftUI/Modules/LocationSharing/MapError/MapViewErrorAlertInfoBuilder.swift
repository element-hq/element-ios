//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
                                  primaryButton: (VectorL10n.locationSharingInvalidAuthorizationNotNow, {}),
                                  secondaryButton: (VectorL10n.locationSharingInvalidAuthorizationSettings, primaryButtonCompletion))
        default:
            alertInfo = nil
        }
        
        return alertInfo
    }
}
