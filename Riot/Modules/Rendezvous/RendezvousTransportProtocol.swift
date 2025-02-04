// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
