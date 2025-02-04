// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationPostProcess SpaceCreationPostProcess
//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

protocol SpaceCreationPostProcessViewModelProtocol {
    var completion: ((SpaceCreationPostProcessViewModelResult) -> Void)? { get set }
    static func makeSpaceCreationPostProcessViewModel(spaceCreationPostProcessService: SpaceCreationPostProcessServiceProtocol) -> SpaceCreationPostProcessViewModelProtocol
    var context: SpaceCreationPostProcessViewModelType.Context { get }
}
