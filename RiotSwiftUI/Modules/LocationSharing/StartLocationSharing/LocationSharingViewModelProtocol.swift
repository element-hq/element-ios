//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

protocol LocationSharingViewModelProtocol {
    var completion: ((LocationSharingViewModelResult) -> Void)? { get set }
    
    func startLoading()
    func stopLoading(error: LocationSharingAlertType?)
}

extension LocationSharingViewModelProtocol {
    func stopLoading() {
        stopLoading(error: nil)
    }
}
