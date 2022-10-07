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

/// Algorithm name as per MSC3903
enum RendezvousChannelAlgorithm: String {
    case ECDH_V1 = "m.rendezvous.v1.curve25519-aes-sha256"
}

/// Allows communication through a secure channel. Based on MSC3886 and MSC3903
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
    
    /// Creates a new rendezvous endpoint and publishes the creator's public key
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
    
    /// After creation we need to wait for the pair to publish its public key as well
    /// At the end of this a symmetric key will be available for encryption
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
    
    /// Joins an existing rendezvous and publishes the joiner's public key
    /// At the end of this a symmetric key will be available for encryption
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
        
        self.interlocutorPublicKey = interlocutorPublicKey
        
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
    
    /// Send arbitrary data over the secure channel
    /// This will use the previously generated symmetric key to AES encrypt the payload
    /// - Parameter data: the data to be encrypted and sent
    /// - Returns: nothing if succeeded or a RendezvousServiceError failure
    func send(data: Data) async -> Result<(), RendezvousServiceError> {
        guard let symmetricKey = symmetricKey else {
            return .failure(.channelNotReady)
        }
        
        // Generate a custom random 256 bit nonce/iv as per MSC3903. The default one is 96 bit.
        guard let nonce = try? AES.GCM.Nonce(data: generateRandomData(ofLength: 32)),
              let sealedBox = try? AES.GCM.seal(data, using: symmetricKey, nonce: nonce) else {
            return .failure(.internalError)
        }
        
        // The resulting cipher text needs to contain both the message and the authentication tag
        // in order to play nicely with other platforms
        var ciphertext = sealedBox.ciphertext
        ciphertext.append(contentsOf: sealedBox.tag)

        let body = RendezvousMessage(iv: Data(nonce).base64EncodedString(),
                                     ciphertext: ciphertext.base64EncodedString())
        
        switch await transport.send(body: body) {
        case .failure(let transportError):
            return .failure(.transportError(transportError))
        case .success:
            return .success(())
        }
    }
    
    
    /// Waits for and returns newly available rendezvous channel data
    /// - Returns: The unencrypted data or a RendezvousServiceError
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
            
            guard let ciphertextData = Data(base64Encoded: response.ciphertext),
                  let nonceData = Data(base64Encoded: response.iv),
                  let nonce = try? AES.GCM.Nonce(data: nonceData) else {
                return .failure(.decodingError)
            }
            
            // Split the ciphertext into the message and authentication tag data
            let messageData = ciphertextData.dropLast(16) // The last 16 bytes are the tag
            let tagData = ciphertextData.dropFirst(messageData.count)
            
            guard let sealedBox = try? AES.GCM.SealedBox(nonce: nonce, ciphertext: messageData, tag: tagData),
                  let messageData = try? AES.GCM.open(sealedBox, using: symmetricKey) else {
                return .failure(.decodingError)
            }
            
            return .success(messageData)
        }
    }
    
    // MARK: - Private
    
    private func generateSymmetricKeyFrom(sharedSecret: SharedSecret) -> SymmetricKey {
        // MSC3903 asks for a 8 zero byte salt when deriving the keys
        let salt = Data(repeating: 0, count: 8)
        return sharedSecret.hkdfDerivedSymmetricKey(using: SHA256.self, salt: salt, sharedInfo: Data(), outputByteCount: 32)
    }
    
    private func generateRandomData(ofLength length: Int) -> Data {
        var data = Data(count: length)
        _ = data.withUnsafeMutableBytes { pointer -> Int32 in
            if let baseAddress = pointer.baseAddress {
                return SecRandomCopyBytes(kSecRandomDefault, length, baseAddress)
            }
            
            return 0
        }
        
        return data
    }
}
