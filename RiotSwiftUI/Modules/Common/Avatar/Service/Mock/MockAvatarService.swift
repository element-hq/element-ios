//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import DesignKit
import Foundation
import UIKit

class MockAvatarService: AvatarServiceProtocol {
    static let example: AvatarServiceProtocol = MockAvatarService()
    func avatarImage(mxContentUri: String, avatarSize: AvatarSize) -> Future<UIImage, Error> {
        Future { promise in
            promise(.success(Asset.Images.appSymbol.image))
        }
    }
}
