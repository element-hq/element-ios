//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import CryptoKit
import Combine
import MatrixSDK

enum RendezvousServiceError: Error {
    case invalidInterlocutorKey
    case decodingError
    case internalError
    case channelNotReady
    case transportError(RendezvousTransportError)
}

/// Algorithm name as per MSC3903
enum RendezvousChannelAlgorithm: String {
    case ECDH_V1 = "org.matrix.msc3903.rendezvous.v1.curve25519-aes-sha256"
    case ECDH_V2 = "org.matrix.msc3903.rendezvous.v2.curve25519-aes-sha256"
}

/// Algorithm name as per MSC3906
enum RendezvousFlow: String {
    /// The v1 value never actually appears in JSON
    case SETUP_ADDITIONAL_DEVICE_V1 = "org.matrix.msc3906.v1"
    case SETUP_ADDITIONAL_DEVICE_V2 = "org.matrix.msc3906.setup.additional_device.v2"
}

// n.b MSC3886/MSC3903/MSC3906 that this is based on are now closed.
// However, we want to keep this implementation around for some time.
// TODO: define an end-of-life date for this implementation.

/// Allows communication through a secure channel. Based on MSC3886 and MSC3903
@MainActor
class RendezvousService {
    private let transport: RendezvousTransportProtocol
    
    private var privateKey: Curve25519.KeyAgreement.PrivateKey!
    private var interlocutorPublicKey: Curve25519.KeyAgreement.PublicKey?
    private var symmetricKey: SymmetricKey?
    private var algorithm: RendezvousChannelAlgorithm
    
    init(transport: RendezvousTransportProtocol, algorithm: RendezvousChannelAlgorithm) {
        self.transport = transport
        self.algorithm = algorithm
    }
    
    /// Creates a new rendezvous endpoint and publishes the creator's public key
    func createRendezvous() async -> Result<RendezvousDetails, RendezvousServiceError> {
        privateKey = Curve25519.KeyAgreement.PrivateKey()
        let algorithm = RendezvousChannelAlgorithm.ECDH_V2
        
        let publicKeyString = encodeBase64(data: privateKey.publicKey.rawRepresentation)
        let details = RendezvousDetails(algorithm: algorithm.rawValue)
        
        switch await transport.create(body: details) {
        case .failure(let transportError):
            return .failure(.transportError(transportError))
        case .success:
            guard let rendezvousURL = transport.rendezvousURL else {
                return .failure(.transportError(.rendezvousURLInvalid))
            }
            
            let fullDetails = RendezvousDetails(algorithm: algorithm.rawValue,
                                                transport: RendezvousTransportDetails(type: "org.matrix.msc3886.http.v1",
                                                                                      uri: rendezvousURL.absoluteString),
                                                key: publicKeyString)
            return .success(fullDetails)
        }
    }
        
    /// After creation we need to wait for the pair to publish its public key as well
    /// At the end of this a symmetric key will be available for encryption
    func waitForInterlocutor() async -> Result<String, RendezvousServiceError> {
        switch await transport.get() {
        case .failure(let error):
            return .failure(.transportError(error))
        case .success(let data):
            guard let response = try? JSONDecoder().decode(RendezvousDetails.self, from: data) else {
                return .failure(.decodingError)
            }
                    
            guard let key = response.key,
                  let interlocutorPublicKeyData = decodeBase64(input: key),
                  let interlocutorPublicKey = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: interlocutorPublicKeyData) else {
                return .failure(.invalidInterlocutorKey)
            }
            
            self.interlocutorPublicKey = interlocutorPublicKey
            
            guard let sharedSecret = try? privateKey.sharedSecretFromKeyAgreement(with: interlocutorPublicKey) else {
                return .failure(.internalError)
            }
            
            self.symmetricKey = generateSymmetricKeyFrom(sharedSecret: sharedSecret,
                                                         initiatorPublicKey: privateKey.publicKey,
                                                         recipientPublicKey: interlocutorPublicKey)
            
            let validationCode = generateValidationCodeFrom(symmetricKey: generateSymmetricKeyFrom(sharedSecret: sharedSecret,
                                                                                                   initiatorPublicKey: privateKey.publicKey,
                                                                                                   recipientPublicKey: interlocutorPublicKey,
                                                                                                   byteCount: 5))
            
            return .success(validationCode)
        }
    }
    
    /// Joins an existing rendezvous and publishes the joiner's public key
    /// At the end of this a symmetric key will be available for encryption
    func joinRendezvous(withPublicKey publicKey: String) async -> Result<String, RendezvousServiceError> {
        guard let interlocutorPublicKeyData = decodeBase64(input: publicKey),
              let interlocutorPublicKey = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: interlocutorPublicKeyData) else {
            MXLog.debug("[RendezvousService] Invalid interlocutor data")
            return .failure(.invalidInterlocutorKey)
        }
        
        privateKey = Curve25519.KeyAgreement.PrivateKey()
        
        let publicKeyString = encodeBase64(data: privateKey.publicKey.rawRepresentation)
        let payload = RendezvousDetails(algorithm: algorithm.rawValue,
                                        key: publicKeyString)
        
        guard case .success = await transport.send(body: payload) else {
            return .failure(.internalError)
        }
                
        self.interlocutorPublicKey = interlocutorPublicKey
        
        guard let sharedSecret = try? privateKey.sharedSecretFromKeyAgreement(with: interlocutorPublicKey) else {
            MXLog.debug("[RendezvousService] Couldn't create shared secret")
            return .failure(.internalError)
        }
        
        symmetricKey = generateSymmetricKeyFrom(sharedSecret: sharedSecret,
                                                initiatorPublicKey: interlocutorPublicKey,
                                                recipientPublicKey: privateKey.publicKey)
        
        let validationCode = generateValidationCodeFrom(symmetricKey: generateSymmetricKeyFrom(sharedSecret: sharedSecret,
                                                                                               initiatorPublicKey: interlocutorPublicKey,
                                                                                               recipientPublicKey: privateKey.publicKey,
                                                                                               byteCount: 5))
        
        return .success(validationCode)
    }
    
    private func encodeBase64(data: Data) -> String {
        if algorithm == .ECDH_V2 {
            return MXBase64Tools.unpaddedBase64(from: data)
        }
        return MXBase64Tools.base64(from: data)
    }
    
    private func decodeBase64(input: String) -> Data? {
        // MXBase64Tools will decode both padded and unpadded data so we don't need to take account of algorithm here
        return MXBase64Tools.data(fromBase64: input)
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

        let body = RendezvousMessage(iv: encodeBase64(data: Data(nonce)),
                                     ciphertext: encodeBase64(data: ciphertext))
        
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
            
            MXLog.debug("Received rendezvous response: \(response)")
            
            guard let ciphertextData = decodeBase64(input: response.ciphertext),
                  let nonceData = decodeBase64(input: response.iv),
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
    
    func tearDown() async -> Result<(), RendezvousServiceError> {
        switch await transport.tearDown() {
        case .failure(let error):
            return .failure(.transportError(error))
        case .success:
            privateKey = nil
            interlocutorPublicKey = nil
            symmetricKey = nil
            
            return .success(())
        }
    }
    
    // MARK: - Private
    
    private func generateValidationCodeFrom(symmetricKey: SymmetricKey) -> String {
        let bytes = symmetricKey.withUnsafeBytes {
            return Data(Array($0))
        }.map { UInt($0) }
        
        let first = (bytes[0] << 5 | bytes[1] >> 3) + 1000
        let secondPart1 = UInt(bytes[1] & 0x7) << 10
        let secondPart2 = bytes[2] << 2 | bytes[3] >> 6
        let second = (secondPart1 | secondPart2) + 1000
        let third = ((bytes[3] & 0x3f) << 7 | bytes[4] >> 1) + 1000
        
        return "\(first)-\(second)-\(third)"
    }
    
    private func generateSymmetricKeyFrom(sharedSecret: SharedSecret,
                                          initiatorPublicKey: Curve25519.KeyAgreement.PublicKey,
                                          recipientPublicKey: Curve25519.KeyAgreement.PublicKey,
                                          byteCount: Int = SHA256Digest.byteCount) -> SymmetricKey {
        guard let sharedInfoData = [algorithm.rawValue,
                                    encodeBase64(data: initiatorPublicKey.rawRepresentation),
                                    encodeBase64(data: recipientPublicKey.rawRepresentation)]
            .joined(separator: "|")
            .data(using: .utf8) else {
            fatalError("[RendezvousService] Failed creating symmetric key shared data")
        }
        
        // MSC3903 asks for a 8 zero byte salt when deriving the keys
        let salt = Data(repeating: 0, count: 8)
        return sharedSecret.hkdfDerivedSymmetricKey(using: SHA256.self,
                                                    salt: salt,
                                                    sharedInfo: sharedInfoData,
                                                    outputByteCount: byteCount)
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
