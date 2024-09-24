// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationPostProcess SpaceCreationPostProcess
//
// Copyright 2017-2024 New Vector Ltd
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
