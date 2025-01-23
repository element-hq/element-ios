// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
