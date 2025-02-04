// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import Combine

extension RiotSettings {
    func publisher(for key: String) -> AnyPublisher<Notification, Never> {
        NotificationCenter.default.publisher(for: .userDefaultValueUpdated)
            .filter({ $0.object as? String == key })
            .eraseToAnyPublisher()
    }
}
