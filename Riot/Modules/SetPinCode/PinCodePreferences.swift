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
import LocalAuthentication
import MatrixSDK

/// Pin code preferences.
@objcMembers
final class PinCodePreferences: NSObject {
    // MARK: - Constants
    
    private enum PinConstants {
        static let pinCodeKeychainService: String = BuildSettings.baseBundleIdentifier + ".pin-service"
    }
    
    private enum StoreKeys {
        static let pin = "pin"
        static let biometricsEnabled = "biometricsEnabled"
        static let canUseBiometricsToUnlock = "canUseBiometricsToUnlock"
        static let numberOfPinFailures = "numberOfPinFailures"
        static let numberOfBiometricsFailures = "numberOfBiometricsFailures"
    }
    
    static let shared = PinCodePreferences()
    
    /// Store. Defaults to `KeychainStore`
    private let store: KeyValueStore
    
    override private init() {
        store = KeychainStore(withKeychain: Keychain(service: PinConstants.pinCodeKeychainService,
                                                     accessGroup: BuildSettings.keychainAccessGroup))
        super.init()
    }
    
    // MARK: - Public
    
    /// Setting to force protection by pin code
    var forcePinProtection: Bool {
        BuildSettings.forcePinProtection
    }
    
    /// Not allowed pin codes. User won't be able to select one of the pin in the list.
    var notAllowedPINs: [String] {
        BuildSettings.notAllowedPINs
    }
    
    /// Maximum number of allowed pin failures when unlocking, before force logging out the user
    var maxAllowedNumberOfPinFailures: Int {
        BuildSettings.maxAllowedNumberOfPinFailures
    }
    
    /// Maximum number of allowed biometrics failures when unlocking, before fallbacking the user to the pin
    var maxAllowedNumberOfBiometricsFailures: Int {
        BuildSettings.maxAllowedNumberOfBiometricsFailures
    }
    
    var isBiometricsAvailable: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }
    
    /// Allowed number of PIN trials before showing forgot help alert
    let allowedNumberOfTrialsBeforeAlert = 5
    
    /// Max allowed time to continue using the app without prompting PIN
    var graceTimeInSeconds: TimeInterval {
        BuildSettings.pinCodeGraceTimeInSeconds
    }
    
    /// Number of digits for the PIN
    let numberOfDigits = 4
    
    /// Is user has set a pin
    var isPinSet: Bool {
        pin != nil
    }
    
    /// Saved user PIN
    var pin: String? {
        get {
            do {
                return try store.string(forKey: StoreKeys.pin)
            } catch {
                MXLog.debug("[PinCodePreferences] Error when reading user pin from store: \(error)")
                return nil
            }
        } set {
            do {
                try store.set(newValue, forKey: StoreKeys.pin)
            } catch {
                MXLog.debug("[PinCodePreferences] Error when storing user pin to the store: \(error)")
            }
        }
    }
    
    var biometricsEnabled: Bool? {
        get {
            do {
                return try store.bool(forKey: StoreKeys.biometricsEnabled)
            } catch {
                MXLog.debug("[PinCodePreferences] Error when reading biometrics enabled from store: \(error)")
                return nil
            }
        } set {
            do {
                try store.set(newValue, forKey: StoreKeys.biometricsEnabled)
            } catch {
                MXLog.debug("[PinCodePreferences] Error when storing biometrics enabled to the store: \(error)")
            }
        }
    }
    
    var canUseBiometricsToUnlock: Bool? {
        get {
            do {
                return try store.bool(forKey: StoreKeys.canUseBiometricsToUnlock)
            } catch {
                MXLog.debug("[PinCodePreferences] Error when reading canUseBiometricsToUnlock from store: \(error)")
                return nil
            }
        } set {
            do {
                try store.set(newValue, forKey: StoreKeys.canUseBiometricsToUnlock)
            } catch {
                MXLog.debug("[PinCodePreferences] Error when storing canUseBiometricsToUnlock to the store: \(error)")
            }
        }
    }
    
    var numberOfPinFailures: Int {
        get {
            do {
                return try store.integer(forKey: StoreKeys.numberOfPinFailures) ?? 0
            } catch {
                MXLog.debug("[PinCodePreferences] Error when reading numberOfPinFailures from store: \(error)")
                return 0
            }
        } set {
            do {
                try store.set(newValue, forKey: StoreKeys.numberOfPinFailures)
            } catch {
                MXLog.debug("[PinCodePreferences] Error when storing numberOfPinFailures to the store: \(error)")
            }
        }
    }
    
    var numberOfBiometricsFailures: Int {
        get {
            do {
                return try store.integer(forKey: StoreKeys.numberOfBiometricsFailures) ?? 0
            } catch {
                MXLog.debug("[PinCodePreferences] Error when reading numberOfBiometricsFailures from store: \(error)")
                return 0
            }
        } set {
            do {
                try store.set(newValue, forKey: StoreKeys.numberOfBiometricsFailures)
            } catch {
                MXLog.debug("[PinCodePreferences] Error when storing numberOfBiometricsFailures to the store: \(error)")
            }
        }
    }
    
    var isBiometricsSet: Bool {
        biometricsEnabled == true && (canUseBiometricsToUnlock ?? true)
    }
    
    func localizedBiometricsName() -> String? {
        if isBiometricsAvailable {
            let context = LAContext()
            //  canEvaluatePolicy should be called for biometryType to be set
            _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
            switch context.biometryType {
            case .touchID:
                return VectorL10n.biometricsModeTouchId
            case .faceID:
                return VectorL10n.biometricsModeFaceId
            default:
                return nil
            }
        }
        return nil
    }
    
    func biometricsIcon() -> UIImage? {
        if isBiometricsAvailable {
            let context = LAContext()
            //  canEvaluatePolicy should be called for biometryType to be set
            _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
            switch context.biometryType {
            case .touchID:
                return Asset.Images.touchidIcon.image
            case .faceID:
                return Asset.Images.faceidIcon.image
            default:
                return nil
            }
        }
        return nil
    }
    
    /// Resets user PIN
    func reset() {
        pin = nil
        biometricsEnabled = nil
        canUseBiometricsToUnlock = nil
        resetCounters()
    }
    
    /// Reset number of failures for both pin and biometrics
    func resetCounters() {
        numberOfPinFailures = 0
        numberOfBiometricsFailures = 0
    }
}
