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

struct AnalyticsSettings {
    static let eventType = "im.vector.analytics"
    
    private enum Constants {
        static let idKey = "id"
        static let webOptInKey = "pseudonymousAnalyticsOptIn"
    }
    
    /// A randomly generated analytics token for this user.
    /// This is suggested to be a 128-bit hex encoded string.
    var id: String?
    
    /// Unused on iOS but necessary to load the value in case opt in was declined on web,
    /// but accepted on iOS. Otherwise generating an ID would wipe out the existing value.
    private var webOptIn: Bool?
    
    /// Generate a new random analytics ID. This method has no effect if an ID already exists.
    mutating func generateID() {
        guard id == nil else { return }
        id = UUID().uuidString
    }
}

extension AnalyticsSettings {
    init(dictionary: Dictionary<AnyHashable, Any>?) {
        self.id = dictionary?[Constants.idKey] as? String
        self.webOptIn = dictionary?[Constants.webOptInKey] as? Bool
    }
    
    var dictionary: Dictionary<AnyHashable, Any> {
        var dictionary = [AnyHashable: Any]()
        dictionary[Constants.idKey] = id
        dictionary[Constants.webOptInKey] = webOptIn
        
        return dictionary
    }
}

extension AnalyticsSettings {
    init(session: MXSession) {
        self.init(dictionary: session.accountData.accountData(forEventType: AnalyticsSettings.eventType))
    }
}
