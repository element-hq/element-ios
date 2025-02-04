//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

protocol PollEditFormViewModelProtocol {
    var completion: ((PollEditFormViewModelResult) -> Void)? { get set }
    
    func startLoading()
    func stopLoading(errorAlertType: PollEditFormErrorAlertInfo.AlertType?)
}

extension PollEditFormViewModelProtocol {
    func stopLoading() {
        stopLoading(errorAlertType: nil)
    }
}
