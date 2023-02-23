// 
// Copyright 2022 New Vector Ltd
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
