/*
 Copyright 2020 New Vector Ltd
 
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

@import Foundation;

/**
 UserEncryptionTrustLevel represents the user trust level in an encrypted room.
 */
typedef NS_ENUM(NSUInteger, UserEncryptionTrustLevel) {
    UserEncryptionTrustLevelTrusted,            // The user is verified and they have trusted all their devices
    UserEncryptionTrustLevelWarning,            // The user is verified but they have not trusted all their devices
    UserEncryptionTrustLevelNotVerified,        // The user is not verified yet
    UserEncryptionTrustLevelNoCrossSigning,     // The user has not bootstrapped cross-signing yet
    UserEncryptionTrustLevelNone,               // Crypto is not enabled. Should not happen
    UserEncryptionTrustLevelUnknown             // Computation in progress
};
