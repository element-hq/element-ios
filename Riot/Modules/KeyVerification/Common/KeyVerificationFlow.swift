/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
    case incomingSASTransaction(_ transaction: MXSASTransaction)
}
