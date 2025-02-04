// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationPostProcess SpaceCreationPostProcess
//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import UIKit

protocol SpaceCreationPostProcessServiceProtocol: AnyObject {
    var tasksSubject: CurrentValueSubject<[SpaceCreationPostProcessTask], Never> { get }
    var createdSpaceId: String? { get }
    var avatar: AvatarInput { get }
    var avatarImage: UIImage? { get }
    func run()
}
