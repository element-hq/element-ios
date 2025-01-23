// 
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixSDKCrypto

extension CryptoStoreError: LocalizedError {
    public var errorDescription: String? {
        // We dont really care about the type of error here when showing to the user.
        // Details about the error are tracked independently
        return VectorL10n.e2eNeedLogInAgain
    }
}
