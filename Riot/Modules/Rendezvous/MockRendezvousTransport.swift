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
