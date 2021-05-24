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

/// Create a JWT token for jitsi openidtoken-jwt authentication
/// See https://github.com/matrix-org/prosody-mod-auth-matrix-user-verification
final class JitsiJWTTokenBuilder {
    
    // MARK: - Constants
    
    private enum Constants {
        static let privateKey = "notused"
    }
    
    // MARK: - Public
    
    func build(jitsiServerDomain: String,
               openIdToken: MXOpenIdToken,
               roomId: String,
               userAvatarUrl: String,
               userDisplayName: String) throws -> String {
        
        // Create Jitsi JWT
        let jitsiJWTPayloadContextMatrix = JitsiJWTPayloadContextMatrix(token: openIdToken.accessToken,
                                                                        roomId: roomId,
                                                                        serverName: openIdToken.matrixServerName)
        let jitsiJWTPayloadContextUser = JitsiJWTPayloadContextUser(avatar: userAvatarUrl, name: userDisplayName)
        let jitsiJWTPayloadContext = JitsiJWTPayloadContext(matrix: jitsiJWTPayloadContextMatrix, user: jitsiJWTPayloadContextUser)
        
        let jitsiJWTPayload = JitsiJWTPayload(iss: jitsiServerDomain,
                                      sub: jitsiServerDomain,
                                      aud: "https://\(jitsiServerDomain)",
            room: "*",
            context: jitsiJWTPayloadContext)
        
        let jitsiJWT = JWT(claims: jitsiJWTPayload)
                        
        // Sign JWT
        // The secret string here is irrelevant, we're only using the JWT
        // to transport data to Prosody in the Jitsi stack.
        let privateKeyData = self.generatePivateKeyData()
        let jwtSigner = JWTSigner.hs256(key: privateKeyData)
        
        // Encode JWT token
        let jwtEncoder = JWTEncoder(jwtSigner: jwtSigner)
        let jwtString = try jwtEncoder.encodeToString(jitsiJWT)
        
        return jwtString
    }
    
    // MARK: - Private
    
    private func generatePivateKeyData() -> Data {
        guard let privateKeyData = Constants.privateKey.data(using: .utf8) else {
            fatalError("[JitsiJWTTokenBuilder] Fail to generate private key")
        }
        return privateKeyData
    }
}
