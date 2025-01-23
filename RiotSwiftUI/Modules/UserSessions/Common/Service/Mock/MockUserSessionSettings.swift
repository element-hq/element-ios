// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine

final class MockUserSessionSettings: UserSessionSettingsProtocol {
    var showIPAddressesInSessionsManager: Bool = false
    
    var showIPAddressesInSessionsManagerPublisher: AnyPublisher<Bool, Never> {
        Just(showIPAddressesInSessionsManager).eraseToAnyPublisher()
    }
}
