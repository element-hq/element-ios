// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftJWT

/// `JitsiJWTPayload` represents the Jitsi JWT payload
/// More details here: https://github.com/matrix-org/prosody-mod-auth-matrix-user-verification#widget-initialization
struct JitsiJWTPayload: Claims {
    let iss: String
    let sub: String
    let aud: String
    let room: String
    let context: JitsiJWTPayloadContext
}

// MARK: - JitsiJWTPayloadContext

struct JitsiJWTPayloadContext: Codable {
    let matrix: JitsiJWTPayloadContextMatrix
    let user: JitsiJWTPayloadContextUser
}

// MARK: - JitsiJWTPayloadContextMatrix

struct JitsiJWTPayloadContextMatrix {
    let token: String
    let roomId: String
    let serverName: String?
}

extension JitsiJWTPayloadContextMatrix: Codable {
    enum CodingKeys: String, CodingKey {
        case token
        case roomId = "room_id"
        case serverName = "server_name"
    }
}

// MARK: - JitsiJWTPayloadContextUser

struct JitsiJWTPayloadContextUser: Codable {
    let avatar: String
    let name: String
}
