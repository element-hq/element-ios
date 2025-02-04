//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

class MockRendezvousTransport: RendezvousTransportProtocol {
    var rendezvousURL: URL?
    
    private var currentPayload: Data?
    
    func create<T: Encodable>(body: T) async -> Result<(), RendezvousTransportError> {
        guard let url = URL(string: "rendezvous.mock/1234") else {
            fatalError()
        }
        
        rendezvousURL = url
        
        guard let encodedBody = try? JSONEncoder().encode(body) else {
            fatalError()
        }
        
        currentPayload = encodedBody
        
        return .success(())
    }
    
    func get() async -> Result<Data, RendezvousTransportError> {
        guard let data = currentPayload else {
            fatalError()
        }
        
        return .success(data)
    }
    
    func send<T: Encodable>(body: T) async -> Result<(), RendezvousTransportError> {
        guard let encodedBody = try? JSONEncoder().encode(body) else {
            fatalError()
        }
        
        currentPayload = encodedBody
        
        return .success(())
    }
    
    func tearDown() async -> Result<(), RendezvousTransportError> {
        return .success(())
    }
}
