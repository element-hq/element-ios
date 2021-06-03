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
