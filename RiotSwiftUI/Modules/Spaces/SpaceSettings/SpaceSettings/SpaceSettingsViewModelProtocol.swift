//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

protocol SpaceSettingsViewModelProtocol {
    var completion: ((SpaceSettingsViewModelResult) -> Void)? { get set }
    static func makeSpaceSettingsViewModel(service: SpaceSettingsServiceProtocol) -> SpaceSettingsViewModelProtocol
    var context: SpaceSettingsViewModelType.Context { get }
    func updateAvatarImage(with image: UIImage?)
}
