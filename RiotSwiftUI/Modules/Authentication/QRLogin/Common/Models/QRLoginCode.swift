//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct QRLoginCode: Codable {
    let rendezvous: RendezvousDetails
    let flow: String?
    let intent: String
}

struct RendezvousDetails: Codable {
    let algorithm: String
    var transport: RendezvousTransportDetails?
    var key: String?
}

struct RendezvousTransportDetails: Codable {
    let type: String
    let uri: String
}

struct RendezvousMessage: Codable {
    let iv: String
    let ciphertext: String
}

struct QRLoginRendezvousPayload: Codable {
    let type: `Type`
    
    var intent: Intent?
    var outcome: Outcome?
    var reason: FailureReason?

    // swiftformat:disable:next redundantBackticks
    var protocols: [`Protocol`]?
    
    // swiftformat:disable:next redundantBackticks
    var `protocol`: `Protocol`?
    
    var homeserver: String?
    var user: String?
    var loginToken: String?
    var deviceId: String?
    var deviceKey: String?
    
    var verifyingDeviceId: String?
    var verifyingDeviceKey: String?
    
    var masterKey: String?
    
    enum CodingKeys: String, CodingKey {
        case type
        case intent
        case outcome
        case reason
        case homeserver
        case user
        case protocols
        case `protocol`
        case loginToken = "login_token"
        case deviceId = "device_id"
        case deviceKey = "device_key"
        case verifyingDeviceId = "verifying_device_id"
        case verifyingDeviceKey = "verifying_device_key"
        case masterKey = "master_key"
    }
    
    enum `Type`: String, Codable {
        case loginProgress = "m.login.progress"
        /**
         This is only used in MSC3906 v1 and will be removed
         */
        case loginFinish = "m.login.finish"
        case loginFailure = "m.login.failure"
        case loginProtocol = "m.login.protocol"
        case loginProtocols = "m.login.protocols"
        case loginApproved = "m.login.approved"
        case loginDeclined = "m.login.declined"
        case loginSuccess = "m.login.success"
        case loginVerified = "m.login.verified"
    }

    enum Intent: String, Codable {
        case loginStart = "login.start"
        case loginReciprocate = "login.reciprocate"
    }
    
    /**
     This is only used in MSC306 v1 and will be removed
     */
    enum Outcome: String, Codable {
        case success
        case declined
        case verified
    }
    
    // swiftformat:disable:next redundantBackticks
    enum `Protocol`: String, Codable {
        case loginToken = "org.matrix.msc3906.login_token"
    }
    
    enum FailureReason: String, Codable {
        case cancelled
        case unsupported
        case e2eeSecurityError = "e2ee_security_error"
        case incompatibleIntent = "incompatible_intent"
    }
}
