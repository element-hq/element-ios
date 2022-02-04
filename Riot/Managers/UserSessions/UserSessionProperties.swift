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
        static let suiteName = BuildSettings.baseBundleIdentifier + ".UserSession"
        static let useCaseKey = "useCase"
    }
    
    // MARK: - Properties
    
    // MARK: Private
    
    /// The user ID for these properties
    private let userId: String
    /// The underlying dictionary that stores the properties in user defaults.
    private var dictionary: [String: Any] {
        didSet {
            UserDefaults(suiteName: Constants.suiteName)?.set(dictionary, forKey: userId)
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
    
    // MARK: - Setup
    
    /// Create new properties for the specified user ID.
    /// - Parameter userId: The user ID to load properties for.
    init(userId: String) {
        self.userId = userId
        self.dictionary = UserDefaults(suiteName: Constants.suiteName)?.dictionary(forKey: userId) ?? [:]
        
        super.init()
    }
    
    // MARK: - Public
    
    /// Clear all of the stored properties.
    func delete() {
        dictionary = [:]
        UserDefaults(suiteName: Constants.suiteName)?.removeObject(forKey: userId)
    }
}
