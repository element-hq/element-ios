//
// Copyright 2024 New Vector Ltd
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

protocol LiveLocationSharingViewerViewModelProtocol {
    var completion: ((LiveLocationSharingViewerViewModelResult) -> Void)? { get set }
    var context: LiveLocationSharingViewerViewModelType.Context { get }
}
