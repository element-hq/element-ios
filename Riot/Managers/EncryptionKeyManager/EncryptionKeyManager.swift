// 
// Copyright 2020 New Vector Ltd
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

import UIKit
import KeychainAccess
import MatrixKit
import CommonCrypto

@objcMembers
class EncryptionKeyManager: NSObject, MXKeyProviderDelegate {
    static let shared = EncryptionKeyManager()
    
    private static let keychainService: String = BuildSettings.baseBundleIdentifier + ".encryption-manager-service"
    private static let contactsIv: KeyValueStoreKey = "contactsIv"
    private static let contactsAesKey: KeyValueStoreKey = "contactsKey"
    private static let accountIv: KeyValueStoreKey = "acountIv"
    private static let accountAesKey: KeyValueStoreKey = "acountKey"
    private static let realmCryptoKey: KeyValueStoreKey = "realmCryptoKey"

    private let keychainStore: KeychainStore = KeychainStore(withKeychain: Keychain(service: keychainService, accessGroup: BuildSettings.keychainAccessGroup))

    private override init() {
    }
    
    func initKeys() {
        generateIvIfNotExists(forKey: EncryptionKeyManager.accountIv)
        generateAesKeyIfNotExists(forKey: EncryptionKeyManager.accountAesKey)
        generateIvIfNotExists(forKey: EncryptionKeyManager.contactsIv)
        generateAesKeyIfNotExists(forKey: EncryptionKeyManager.contactsAesKey)
        generateKeyIfNotExists(forKey: EncryptionKeyManager.realmCryptoKey, size: 64)

        assert(keychainStore.containsObject(forKey: EncryptionKeyManager.contactsIv), "[EncryptionKeyManager] initKeys: Failed to generate IV for acount")
        assert(keychainStore.containsObject(forKey: EncryptionKeyManager.contactsAesKey), "[EncryptionKeyManager] initKeys: Failed to generate AES Key for acount")
        assert(keychainStore.containsObject(forKey: EncryptionKeyManager.contactsIv), "[EncryptionKeyManager] initKeys: Failed to generate IV for contacts")
        assert(keychainStore.containsObject(forKey: EncryptionKeyManager.contactsAesKey), "[EncryptionKeyManager] initKeys: Failed to generate AES Key for contacts")
        assert(keychainStore.containsObject(forKey: EncryptionKeyManager.realmCryptoKey), "[EncryptionKeyManager] initKeys: Failed to generate Key for realmCrypto")
    }
    
    // MARK: - MXKeyProviderDelegate
    
    func isEncryptionAvailableForData(ofType dataType: String) -> Bool {
        return dataType == kMXKContactManagerDataType
            || dataType == kMXKAccountManagerDataType
            || dataType == kMXRealmCryptoStoreDataType
    }
            
    func hasKeyForData(ofType dataType: String) -> Bool {
        switch dataType {
        case kMXKContactManagerDataType:
            return keychainStore.containsObject(forKey: EncryptionKeyManager.contactsIv) && keychainStore.containsObject(forKey: EncryptionKeyManager.contactsAesKey)
        case kMXKAccountManagerDataType:
            return keychainStore.containsObject(forKey: EncryptionKeyManager.accountIv) && keychainStore.containsObject(forKey: EncryptionKeyManager.accountAesKey)
        case kMXRealmCryptoStoreDataType:
            return keychainStore.containsObject(forKey: EncryptionKeyManager.realmCryptoKey)
        default:
            return false
        }
    }
    
    func keyDataForData(ofType dataType: String) -> MXKeyData? {
        switch dataType {
        case kMXKContactManagerDataType:
            if let ivKey = try? keychainStore.data(forKey: EncryptionKeyManager.contactsIv),
               let aesKey = try? keychainStore.data(forKey: EncryptionKeyManager.contactsAesKey) {
                return MXAesKeyData(iv: ivKey, key: aesKey)
            }
        case kMXKAccountManagerDataType:
            if let ivKey = try? keychainStore.data(forKey: EncryptionKeyManager.accountIv),
               let aesKey = try? keychainStore.data(forKey: EncryptionKeyManager.accountAesKey) {
                return MXAesKeyData(iv: ivKey, key: aesKey)
            }
        case kMXRealmCryptoStoreDataType:
            if let key = try? keychainStore.data(forKey: EncryptionKeyManager.realmCryptoKey) {
                return MXRawDataKey(key: key)
            }
        default:
            return nil
        }
        return nil
    }
    
    // MARK: - Private methods
    
    private func generateIvIfNotExists(forKey key: String) {
        if !keychainStore.containsObject(forKey: key) {
            do {
                try keychainStore.set(MXAes.iv(), forKey: key)
            } catch {
                NSLog("[EncryptionKeyManager] initKeys: Failed to generate IV: %@", error.localizedDescription)
            }
        }
    }
    
    private func generateAesKeyIfNotExists(forKey key: String) {
        generateKeyIfNotExists(forKey: key, size: kCCKeySizeAES256)
    }
    
    private func generateKeyIfNotExists(forKey key: String, size: Int) {
        if !keychainStore.containsObject(forKey: key) {
            do {
                var keyBytes = [UInt8](repeating: 0, count: size)
                  _ = SecRandomCopyBytes(kSecRandomDefault, size, &keyBytes)
                try keychainStore.set(Data(bytes: keyBytes, count: size), forKey: key)
            } catch {
                NSLog("[EncryptionKeyManager] initKeys: Failed to generate Key[%@]: %@", key, error.localizedDescription)
            }
        }
    }
}
