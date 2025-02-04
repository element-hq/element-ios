//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

protocol TemplateUserProfileServiceProtocol: Avatarable {
    var userId: String { get }
    var displayName: String? { get }
    var avatarUrl: String? { get }
    var presenceSubject: CurrentValueSubject<TemplateUserProfilePresence, Never> { get }
}

// MARK: Avatarable

extension TemplateUserProfileServiceProtocol {
    var mxContentUri: String? {
        avatarUrl
    }

    var matrixItemId: String {
        userId
    }
}
