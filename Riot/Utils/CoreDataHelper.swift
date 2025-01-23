// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

class CoreDataHelper {
    /// Returns the magic URL to use for an in memory SQLite database. This is
    /// favourable over an `NSInMemoryStoreType` based store which is missing
    /// of the feature set available to an SQLite store.
    ///
    /// This style of in memory SQLite store is useful for testing purposes as
    /// every new instance of the store will contain a fresh database.
    static var inMemoryURL: URL { URL(fileURLWithPath: "/dev/null") }
}
