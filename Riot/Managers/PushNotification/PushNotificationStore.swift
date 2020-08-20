// 
// Copyright 2020 Vector Creations Ltd
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
import KeychainAccess
import MatrixSDK

@objcMembers
final class PushNotificationStore: NSObject {
    
    // MARK: - Constants
    
    private struct PushNotificationConstants {
        static let pushNotificationKeychainService: String = BuildSettings.baseBundleIdentifier + ".pushnotification-service"
    }
    
    private struct StoreKeys {
        static let pushToken: String = "pushtoken"
        static let lastCallInvite: String = "lastCallInvite"
    }
    
    /// Store. Defaults to `KeychainStore`
    private let store: KeyValueStore
    
    override init() {
        store = KeychainStore(withKeychain: Keychain(service: PushNotificationConstants.pushNotificationKeychainService,
                                                     accessGroup: BuildSettings.keychainAccessGroup))
        super.init()
    }
    
    /// Saved PushKit token
    var pushKitToken: Data? {
        get {
            do {
                return try store.data(forKey: StoreKeys.pushToken)
            } catch let error {
                NSLog("[PinCodePreferences] Error when reading push token from store: \(error)")
                return nil
            }
        } set {
            do {
                try store.set(newValue, forKey: StoreKeys.pushToken)
            } catch let error {
                NSLog("[PinCodePreferences] Error when storing push token to the store: \(error)")
            }
        }
    }
    
    var lastCallInvite: MXEvent? {
        get {
            do {
                guard let data = try store.data(forKey: StoreKeys.lastCallInvite) else {
                    return nil
                }
                return NSKeyedUnarchiver.unarchiveObject(with: data) as? MXEvent
            } catch let error {
                NSLog("[PinCodePreferences] Error when reading push token from store: \(error)")
                return nil
            }
        } set {
            do {
                guard let newValue = newValue else {
                    return try store.removeObject(forKey: StoreKeys.lastCallInvite)
                }
                let data = NSKeyedArchiver.archivedData(withRootObject: newValue)
                try store.set(data, forKey: StoreKeys.lastCallInvite)
            } catch let error {
                NSLog("[PinCodePreferences] Error when storing push token to the store: \(error)")
            }
        }
    }
    
    func reset() {
        pushKitToken = nil
        lastCallInvite = nil
    }
}
