// 
// Copyright 2024 New Vector Ltd.
// Copyright 2020 Vector Creations Ltd
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
                MXLog.debug("[PinCodePreferences] Error when reading push token from store: \(error)")
                return nil
            }
        } set {
            do {
                try store.set(newValue, forKey: StoreKeys.pushToken)
            } catch let error {
                MXLog.debug("[PinCodePreferences] Error when storing push token to the store: \(error)")
            }
        }
    }
    
    func callInvite(forEventId eventId: String) -> MXEvent? {
        guard let data = try? store.data(forKey: eventId) else {
            return nil
        }
        return NSKeyedUnarchiver.unarchiveObject(with: data) as? MXEvent
    }
    
    func storeCallInvite(_ event: MXEvent) {
        let data = NSKeyedArchiver.archivedData(withRootObject: event)
        try? store.set(data, forKey: event.eventId)
    }
    
    func removeCallInvite(withEventId eventId: String) {
        try? store.removeObject(forKey: eventId)
    }
    
    func reset() {
        try? store.removeAll()
    }
}
