//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation

protocol SpaceSelectorServiceProtocol {
    var spaceListSubject: CurrentValueSubject<[SpaceSelectorListItemData], Never> { get }
    var parentSpaceNameSubject: CurrentValueSubject<String?, Never> { get }
    var selectedSpaceId: String? { get }
}
