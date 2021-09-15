// 
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
