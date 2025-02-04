// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Account deactivation parameters for password deactivation.
struct DeactivateAccountPasswordParameters: DictionaryEncodable {
    /// The type of authentication being used.
    let type = kMXLoginFlowTypePassword
    /// The account's matrix ID.
    let user: String
    /// The account's password.
    let password: String
}

/// Account deactivation parameters for use after fallback authentication has completed.
struct DeactivateAccountDummyParameters: DictionaryEncodable {
    /// The type of authentication being used.
    let type = kMXLoginFlowTypeDummy
    /// The account's matrix ID.
    let user: String
    /// The session ID used when completing authentication.
    let session: String
}
