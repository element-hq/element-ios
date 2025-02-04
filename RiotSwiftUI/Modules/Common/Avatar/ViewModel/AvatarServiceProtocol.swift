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

/// Provides a simple api to retrieve and cache avatar images
protocol AvatarServiceProtocol {
    func avatarImage(mxContentUri: String, avatarSize: AvatarSize) -> Future<UIImage, Error>
}
