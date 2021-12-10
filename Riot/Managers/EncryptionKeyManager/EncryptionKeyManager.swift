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
import CommonCrypto
import MatrixSDK

@objcMembers
class EncryptionKeyManager: NSObject, MXKeyProviderDelegate {
    static let shared = EncryptionKeyManager()
    
    private static let keychainService: String = BuildSettings.baseBundleIdentifier + ".encryption-manager-service"
    private static let contactsIv: KeyValueStoreKey = "contactsIv"
    private static let contactsAesKey: KeyValueStoreKey = "contactsAesKey"
    private static let accountIv: KeyValueStoreKey = "accountIv"
    private static let accountAesKey: KeyValueStoreKey = "accountAesKey"
    private static let cryptoOlmPickleKey: KeyValueStoreKey = "cryptoOlmPickleKey"
    private static let roomLastMessageIv: KeyValueStoreKey = "roomLastMessageIv"
    private static let roomLastMessageAesKey: KeyValueStoreKey = "roomLastMessageAesKey"

    private let keychainStore: KeyValueStore = KeychainStore(withKeychain: Keychain(service: keychainService, accessGroup: BuildSettings.keychainAccessGroup))

    private override init() {
        super.init()
        initKeys()
    }
    
    private func initKeys() {
        generateIvIfNotExists(forKey: EncryptionKeyManager.accountIv)
        generateAesKeyIfNotExists(forKey: EncryptionKeyManager.accountAesKey)
        generateIvIfNotExists(forKey: EncryptionKeyManager.contactsIv)
        generateAesKeyIfNotExists(forKey: EncryptionKeyManager.contactsAesKey)
        generateKeyIfNotExists(forKey: EncryptionKeyManager.cryptoOlmPickleKey, size: 32)
        generateIvIfNotExists(forKey: EncryptionKeyManager.roomLastMessageIv)
        generateAesKeyIfNotExists(forKey: EncryptionKeyManager.roomLastMessageAesKey)

        assert(keychainStore.containsObject(forKey: EncryptionKeyManager.contactsIv), "[EncryptionKeyManager] initKeys: Failed to generate IV for acount")
        assert(keychainStore.containsObject(forKey: EncryptionKeyManager.contactsAesKey), "[EncryptionKeyManager] initKeys: Failed to generate AES Key for acount")
        assert(keychainStore.containsObject(forKey: EncryptionKeyManager.contactsIv), "[EncryptionKeyManager] initKeys: Failed to generate IV for contacts")
        assert(keychainStore.containsObject(forKey: EncryptionKeyManager.contactsAesKey), "[EncryptionKeyManager] initKeys: Failed to generate AES Key for contacts")
        assert(keychainStore.containsObject(forKey: EncryptionKeyManager.cryptoOlmPickleKey), "[EncryptionKeyManager] initKeys: Failed to generate Key for olm pickle key")
        assert(keychainStore.containsObject(forKey: EncryptionKeyManager.roomLastMessageIv), "[EncryptionKeyManager] initKeys: Failed to generate IV for room last message")
        assert(keychainStore.containsObject(forKey: EncryptionKeyManager.roomLastMessageAesKey), "[EncryptionKeyManager] initKeys: Failed to generate AES Key for room last message encryption")
    }
    
    // MARK: - MXKeyProviderDelegate
    
    func isEncryptionAvailableForData(ofType dataType: String) -> Bool {
        return dataType == MXKContactManagerDataType
            || dataType == MXKAccountManagerDataType
            || dataType == MXCryptoOlmPickleKeyDataType
            || dataType == MXRoomLastMessageDataType
    }
            
    func hasKeyForData(ofType dataType: String) -> Bool {
        switch dataType {
        case MXKContactManagerDataType:
            return keychainStore.containsObject(forKey: EncryptionKeyManager.contactsIv) && keychainStore.containsObject(forKey: EncryptionKeyManager.contactsAesKey)
        case MXKAccountManagerDataType:
            return keychainStore.containsObject(forKey: EncryptionKeyManager.accountIv) && keychainStore.containsObject(forKey: EncryptionKeyManager.accountAesKey)
        case MXCryptoOlmPickleKeyDataType:
            return keychainStore.containsObject(forKey: EncryptionKeyManager.cryptoOlmPickleKey)
        case MXRoomLastMessageDataType:
            return keychainStore.containsObject(forKey: EncryptionKeyManager.roomLastMessageIv) &&
                keychainStore.containsObject(forKey: EncryptionKeyManager.roomLastMessageAesKey)
        default:
            return false
        }
    }
    
    func keyDataForData(ofType dataType: String) -> MXKeyData? {
        switch dataType {
        case MXKContactManagerDataType:
            if let ivKey = try? keychainStore.data(forKey: EncryptionKeyManager.contactsIv),
               let aesKey = try? keychainStore.data(forKey: EncryptionKeyManager.contactsAesKey) {
                return MXAesKeyData(iv: ivKey, key: aesKey)
            }
        case MXKAccountManagerDataType:
            if let ivKey = try? keychainStore.data(forKey: EncryptionKeyManager.accountIv),
               let aesKey = try? keychainStore.data(forKey: EncryptionKeyManager.accountAesKey) {
                return MXAesKeyData(iv: ivKey, key: aesKey)
            }
        case MXCryptoOlmPickleKeyDataType:
            if let key = try? keychainStore.data(forKey: EncryptionKeyManager.cryptoOlmPickleKey) {
                return MXRawDataKey(key: key)
            }
        case MXRoomLastMessageDataType:
            if let ivKey = try? keychainStore.data(forKey: EncryptionKeyManager.roomLastMessageIv),
               let aesKey = try? keychainStore.data(forKey: EncryptionKeyManager.roomLastMessageAesKey) {
                return MXAesKeyData(iv: ivKey, key: aesKey)
            }
        default:
            return nil
        }
        return nil
    }
    
    // MARK: - Private methods
    
    private func generateIvIfNotExists(forKey key: String) {
        guard !keychainStore.containsObject(forKey: key) else {
            return
        }
        
        do {
            try keychainStore.set(MXAes.iv(), forKey: key)
        } catch {
            MXLog.debug("[EncryptionKeyManager] initKeys: Failed to generate IV: \(error.localizedDescription)")
        }
    }
    
    private func generateAesKeyIfNotExists(forKey key: String) {
        generateKeyIfNotExists(forKey: key, size: kCCKeySizeAES256)
    }
    
    private func generateKeyIfNotExists(forKey key: String, size: Int) {
        guard !keychainStore.containsObject(forKey: key) else {
            return
        }
        
        do {
            var keyBytes = [UInt8](repeating: 0, count: size)
              _ = SecRandomCopyBytes(kSecRandomDefault, size, &keyBytes)
            try keychainStore.set(Data(bytes: keyBytes, count: size), forKey: key)
        } catch {
            MXLog.debug("[EncryptionKeyManager] initKeys: Failed to generate Key[\(key)]: \(error.localizedDescription)")
        }
    }
}
