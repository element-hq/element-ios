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

struct HomeserverAddress {
    /// Ensures the address contains a scheme, otherwise makes it `https`.
    static func sanitized(_ address: String) -> String {
        !address.contains("://") ? "https://\(address.lowercased())" : address.lowercased()
    }
    
    /// Strips the `https://` away from the address (but leaves `http://`) for display in labels.
    ///
    /// `http://` is left in the string to make it clear when a chosen server doesn't use SSL.
    static func displayable(_ address: String) -> String {
        address.replacingOccurrences(of: "https://", with: "")
    }
}
