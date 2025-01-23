// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// An analytics settings event from the user's account data.
struct AnalyticsSettings {
    static let eventType = "im.vector.analytics"
    
    enum Constants {
        static let idKey = "id"
        static let webOptInKey = "pseudonymousAnalyticsOptIn"
    }
    
    /// A randomly generated analytics token for this user.
    /// This is suggested to be a UUID string.
    let id: String?
    
    /// Whether the user has opted in on web or not. This is unused on iOS but necessary
    /// to store here so that it's value is preserved when updating the account data if we
    /// generated an ID on iOS.
    ///
    /// `true` if opted in on web, `false` if opted out on web and `nil` if the web prompt is not yet seen.
    private let webOptIn: Bool?
}

extension AnalyticsSettings {
    // Private as AnalyticsSettings should only be created from an MXSession
    private init(dictionary: Dictionary<AnyHashable, Any>?) {
        self.id = dictionary?[Constants.idKey] as? String
        self.webOptIn = dictionary?[Constants.webOptInKey] as? Bool
    }
    
    /// A dictionary representation of the settings.
    var dictionary: Dictionary<AnyHashable, Any> {
        var dictionary = [AnyHashable: Any]()
        dictionary[Constants.idKey] = id
        dictionary[Constants.webOptInKey] = webOptIn
        
        return dictionary
    }
}

// MARK: - Public initializer

extension AnalyticsSettings {
    /// Create the analytics settings from account data.
    /// - Parameter accountData: The account data to read the event from.
    init(accountData: MXAccountData) {
        self.init(dictionary: accountData.accountData(forEventType: AnalyticsSettings.eventType))
    }
}
