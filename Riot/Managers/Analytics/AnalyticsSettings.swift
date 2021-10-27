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
        static let optInKey = "pseudonymousAnalyticsOptIn"
        static let showPromptKey = "showPseudonymousAnalyticsPrompt"
    }
    
    /// A randomly generated analytics token for this user.
    /// This is suggested to be a 128-bit hex encoded string.
    var id: String?
    
    /// Boolean indicating whether the user has opted in.
    /// If nil, the user hasn't yet given consent either way
    var pseudonymousAnalyticsOptIn: Bool?
    
    /// Boolean indicating whether to show the analytics opt-in prompt.
    var showPseudonymousAnalyticsPrompt: Bool
    
    mutating func generateIDIfMissing() {
        guard id == nil else { return }
        
        // Generate a 32 character analytics ID containing the characters 0-f.
        id = [UInt8](repeating: 0, count: 16)
            .map { _ in String(format: "%02x", UInt8.random(in: 0...UInt8.max)) }
            .joined()
    }
}

extension AnalyticsSettings {
    init(dictionary: Dictionary<AnyHashable, Any>?) {
        self.id = dictionary?[Constants.idKey] as? String
        self.pseudonymousAnalyticsOptIn = dictionary?[Constants.optInKey] as? Bool
        self.showPseudonymousAnalyticsPrompt = dictionary?[Constants.showPromptKey] as? Bool ?? true
    }
    
    var dictionary: Dictionary<AnyHashable, Any> {
        var dictionary = [AnyHashable: Any]()
        dictionary[Constants.idKey] = id
        dictionary[Constants.optInKey] = pseudonymousAnalyticsOptIn
        dictionary[Constants.showPromptKey] = showPseudonymousAnalyticsPrompt
        
        return dictionary
    }
}

extension AnalyticsSettings {
    init(session: MXSession) {
        self.init(dictionary: session.accountData.accountData(forEventType: AnalyticsSettings.eventType))
    }
}
