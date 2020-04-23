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

import Foundation

/// Key verification flow used by KeyVerificationCoordinator
///
/// - verifyUser: Start a user verification.
/// - verifyDevice: Start a verification of another device.
/// - completeSecurity: Wait to be verified by another session after login on a new device.
/// - incomingRequest: Manage an incoming key verification request.
/// - incomingSASTransaction: Manage an incoming SAS verification transaction
enum KeyVerificationFlow {
    case verifyUser(_ roomMember: MXRoomMember)
    case verifyDevice(userId: String, deviceId: String)
    case completeSecurity(_ isNewSignIn: Bool)
    case incomingRequest(_ request: MXKeyVerificationRequest)
    case incomingSASTransaction(_ transaction: MXIncomingSASTransaction)
}
