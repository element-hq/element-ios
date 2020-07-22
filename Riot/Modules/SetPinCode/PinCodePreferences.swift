/*
Copyright 2018 New Vector Ltd

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

import Foundation
import KeychainAccess

/// Pin code preferences.
@objcMembers
final class PinCodePreferences: NSObject {
    
    // MARK: - Constants
    
    private struct PinConstants {
        static let pinCodeKeychainService: String = "im.vector.app.pin-service"
    }
    
    private struct StoreKeys {
        static let pin: String = "pin"
    }
    
    static let shared = PinCodePreferences()
    
    /// Store. Defaults to `KeychainStore`
    let store: KeyValueStore
    
    override init() {
        store = KeychainStore(withKeychain: Keychain(service: PinConstants.pinCodeKeychainService,
                                                     accessGroup: Constants.keychainAccessGroup))
    }
    
    // MARK: - Public
    
    /// Setting to force protection by pin code
    var forcePinProtection: Bool {
        return RiotSettings.shared.forcePinProtection
    }
    
    /// Allowed number of PIN trials before showing forgot help alert
    let allowedNumberOfTrialsBeforeAlert: Int = 5
    
    /// Max allowed time to continue using the app without prompting PIN
    let graceTimeInSeconds: TimeInterval = 120
    
    /// Number of digits for the PIN
    let numberOfDigits: Int = 4
    
    /// Is user has set a pin
    var isPinSet: Bool {
        return pin != nil
    }
    
    /// Saved user PIN
    var pin: String? {
        get {
            do {
                return try store.object(forKey: StoreKeys.pin) as? String
            } catch let error {
                NSLog("[PinCodePreferences] Error when reading user pin from store: \(error)")
                return nil
            }
        } set {
            do {
                try store.set(newValue, forKey: StoreKeys.pin)
            } catch let error {
                NSLog("[PinCodePreferences] Error when storing user pin to the store: \(error)")
            }
        }
    }
    
    /// Resets user PIN
    func reset() {
        pin = nil
    }
}
