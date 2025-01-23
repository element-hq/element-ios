// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine

extension RiotSettings: UserSessionSettingsProtocol {
    var showIPAddressesInSessionsManagerPublisher: AnyPublisher<Bool, Never> {
        NotificationCenter.default
            .publisher(for: .userDefaultValueUpdated)
            .compactMap { $0.object as? String }
            .filter { $0 == RiotSettings.UserDefaultsKeys.showIPAddressesInSessionsManager }
            .map { _ in RiotSettings.shared.showIPAddressesInSessionsManager }
            .eraseToAnyPublisher()
    }
}
