//
// Copyright 2022 New Vector Ltd
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
import CryptoKit
import Combine

enum RendezvousServiceError: Error {
    case invalidInterlocutorKey
    case decodingError
    case internalError
    case channelNotReady
    case transportError(RendezvousTransportError)
}

enum RendezvousServiceCallback {
    case error(RendezvousServiceError)
}

enum RendezvousChannelAlgorithm: String {
    case ECDH_V1 = "m.rendezvous.v1.x25519-aes-sha256"
}

@MainActor
class RendezvousService {
    private let transport: RendezvousTransportProtocol
    private let privateKey: Curve25519.KeyAgreement.PrivateKey
    
    private var interlocutorPublicKey: Curve25519.KeyAgreement.PublicKey?
    private var symmetricKey: SymmetricKey?
    
    init(transport: RendezvousTransportProtocol) {
        self.transport = transport
        self.privateKey = Curve25519.KeyAgreement.PrivateKey()
    }
    
    func createRendezvous() async -> Result<(), RendezvousServiceError> {
        let publicKeyString = self.privateKey.publicKey.rawRepresentation.base64EncodedString()
        let payload = RendezvousDetails(algorithm: RendezvousChannelAlgorithm.ECDH_V1.rawValue,
                                        key: publicKeyString)
        
        switch await transport.create(body: payload) {
        case .failure(let transportError):
            return .failure(.transportError(transportError))
        case .success:
            return .success(())
        }
    }
    
    func waitForInterlocutor() async -> Result<(), RendezvousServiceError> {
        switch await transport.get() {
        case .failure(let error):
            return .failure(.transportError(error))
        case .success(let data):
            guard let response = try? JSONDecoder().decode(RendezvousDetails.self, from: data) else {
                return .failure(.decodingError)
            }
                    
            guard let interlocutorPublicKeyData = Data(base64Encoded: response.key),
                  let interlocutorPublicKey = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: interlocutorPublicKeyData) else {
                return .failure(.invalidInterlocutorKey)
            }
            
            self.interlocutorPublicKey = interlocutorPublicKey
            
            guard let sharedSecret = try? privateKey.sharedSecretFromKeyAgreement(with: interlocutorPublicKey) else {
                return .failure(.internalError)
            }
            
            self.symmetricKey = generateSymmetricKeyFrom(sharedSecret: sharedSecret)
            
            return .success(())
        }
    }
    
    func joinRendezvous() async -> Result<(), RendezvousServiceError> {
        guard case let .success(data) = await transport.get() else {
            return .failure(.internalError)
        }
        
        guard let response = try? JSONDecoder().decode(RendezvousDetails.self, from: data) else {
            return .failure(.decodingError)
        }
        
        guard let interlocutorPublicKeyData = Data(base64Encoded: response.key),
              let interlocutorPublicKey = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: interlocutorPublicKeyData) else {
            return .failure(.invalidInterlocutorKey)
        }
        
        let publicKeyString = self.privateKey.publicKey.rawRepresentation.base64EncodedString()
        let payload = RendezvousDetails(algorithm: RendezvousChannelAlgorithm.ECDH_V1.rawValue,
                                        key: publicKeyString)
        
        guard case .success = await transport.send(body: payload) else {
            return .failure(.internalError)
        }
        
        // Channel established
        guard let sharedSecret = try? privateKey.sharedSecretFromKeyAgreement(with: interlocutorPublicKey) else {
            return .failure(.internalError)
        }
        
        self.symmetricKey = generateSymmetricKeyFrom(sharedSecret: sharedSecret)
        
        return .success(())
    }
    
    func send(data: Data) async -> Result<(), RendezvousServiceError> {
        guard let symmetricKey = symmetricKey else {
            return .failure(.channelNotReady)
        }
                
        guard let sealedBox = try? AES.GCM.seal(data, using: symmetricKey),
              let combinedData = sealedBox.combined else {
            return .failure(.internalError)
        }
        
        let body = RendezvousMessage(combined: combinedData.base64EncodedString())
        
        switch await transport.send(body: body) {
        case .failure(let transportError):
            return .failure(.transportError(transportError))
        case .success:
            return .success(())
        }
    }
    
    func receive() async -> Result<Data, RendezvousServiceError> {
        guard let symmetricKey = symmetricKey else {
            return .failure(.channelNotReady)
        }
        
        switch await transport.get() {
        case.failure(let transportError):
            return .failure(.transportError(transportError))
        case .success(let data):
            guard let response = try? JSONDecoder().decode(RendezvousMessage.self, from: data) else {
                return .failure(.decodingError)
            }
            
            guard let combinedData = Data(base64Encoded: response.combined),
                  let sealedBox = try? AES.GCM.SealedBox(combined: combinedData),
                  let messageData = try? AES.GCM.open(sealedBox, using: symmetricKey) else {
                return .failure(.decodingError)
            }
            
            return .success(messageData)
        }
    }
    
    // MARK: - Private
    
    private func generateSymmetricKeyFrom(sharedSecret: SharedSecret) -> SymmetricKey {
        let salt = Data(repeating: 0, count: 8)
        return sharedSecret.hkdfDerivedSymmetricKey(using: SHA256.self, salt: salt, sharedInfo: Data(), outputByteCount: 32)
    }
}
