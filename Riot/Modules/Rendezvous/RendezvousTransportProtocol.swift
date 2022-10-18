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

enum RendezvousTransportError: Error {
    case rendezvousURLInvalid
    case encodingError
    case networkError
    case rendezvousCancelled
}

/// HTTP based MSC3886 channel implementation
@MainActor
protocol RendezvousTransportProtocol {
    /// The current rendezvous endpoint.
    /// Automatically assigned after a successful creation
    var rendezvousURL: URL? { get }
    
    /// Creates a new rendezvous point containing the body
    /// - Parameter body: arbitrary data to publish on the rendevous
    /// - Returns:a transport error in case of failure
    func create<T: Encodable>(body: T) async -> Result<(), RendezvousTransportError>
    
    /// Waits for and returns newly availalbe rendezvous data
    func get() async -> Result<Data, RendezvousTransportError>
        
    /// Publishes new rendezvous data
    func send<T: Encodable>(body: T) async -> Result<(), RendezvousTransportError>
    
    /// Deletes the resource at the current rendezvous endpoint
    func tearDown() async -> Result<(), RendezvousTransportError>
}
