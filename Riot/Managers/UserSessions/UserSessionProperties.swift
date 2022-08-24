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

/// User properties that are tied to a particular user ID.
class UserSessionProperties: NSObject {
    
    // MARK: - Constants
    private enum Constants {
        static let useCaseKey = "useCase"
        static let activeFilterKey = "activeFilter"
    }
    
    // MARK: - Properties
    
    // MARK: Private
    
    /// The user ID for these properties
    private let userId: String
    
    /// The underlying dictionary for this userId from user defaults.
    private var dictionary: [String: Any] {
        get {
            RiotSettings.shared.userSessionProperties[userId] ?? [:]
        }
        set {
            var sharedProperties = RiotSettings.shared.userSessionProperties
            sharedProperties[userId] = newValue
            RiotSettings.shared.userSessionProperties = sharedProperties
        }
    }
    
    // MARK: Public
    
    /// The user's use case selection if this session was the one used to register the account.
    var useCase: UseCase? {
        get {
            guard let useCaseRawValue = dictionary[Constants.useCaseKey] as? String else { return nil }
            return UseCase(rawValue: useCaseRawValue)
        } set {
            dictionary[Constants.useCaseKey] = newValue?.rawValue
        }
    }
    
    /// Represents a selected use case for the app.
    /// Note: The raw string value is used for storage.
    enum UseCase: String {
        case personalMessaging
        case workMessaging
        case communityMessaging
        case skipped
    }
    
    /// The active filter in the All Chats screen.
    var allChatsActiveFilter: AllChatsActiveFilter? {
        get {
            guard let rawValue = dictionary[Constants.activeFilterKey] as? String else { return nil }
            return AllChatsActiveFilter(rawValue: rawValue)
        } set {
            dictionary[Constants.activeFilterKey] = newValue?.rawValue
        }
    }
    
    /// Represents the active filter in the All Chats screen.
    /// Note: The raw string value is used for storage.
    public enum AllChatsActiveFilter: String {
        case all
        case favourites
        case people
        case unreads
    }

    // MARK: - Setup
    
    /// Create new properties for the specified user ID.
    /// - Parameter userId: The user ID to load properties for.
    init(userId: String) {
        self.userId = userId
        super.init()
    }
    
    // MARK: - Public
    
    /// Clear all of the stored properties.
    func delete() {
        dictionary = [:]
        
        var sharedProperties = RiotSettings.shared.userSessionProperties
        sharedProperties[userId] = nil
        RiotSettings.shared.userSessionProperties = sharedProperties
    }
}
