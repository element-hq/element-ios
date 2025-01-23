//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest
@testable import Element

@MainActor
class RendezvousServiceTests: XCTestCase {
    func testEnd2EndV1() async {
        let mockTransport = MockRendezvousTransport()
        
        let aliceService = RendezvousService(transport: mockTransport, algorithm: .ECDH_V1)
        
        guard case .success(let rendezvousDetails) = await aliceService.createRendezvous(),
              let alicePublicKey = rendezvousDetails.key else {
            XCTFail("Rendezvous creation failed")
            return
        }
        
        XCTAssertNotNil(mockTransport.rendezvousURL)
        
        let bobService = RendezvousService(transport: mockTransport, algorithm: .ECDH_V1)
        
        guard case .success = await bobService.joinRendezvous(withPublicKey: alicePublicKey) else {
            XCTFail("Bob failed to join")
            return
        }
         
        guard case .success = await aliceService.waitForInterlocutor() else {
            XCTFail("Alice failed to establish connection")
            return
        }
        
        guard let messageData = "Hello from alice".data(using: .utf8) else {
            fatalError()
        }
        
        guard case .success = await aliceService.send(data: messageData) else {
            XCTFail("Alice failed to send message")
            return
        }
        
        guard case .success(let data) = await bobService.receive() else {
            XCTFail("Bob failed to receive message")
            return
        }
        
        XCTAssertEqual(messageData, data)
    }
    
    func testEnd2EndV2() async {
        let mockTransport = MockRendezvousTransport()
        
        let aliceService = RendezvousService(transport: mockTransport, algorithm: .ECDH_V2)
        
        guard case .success(let rendezvousDetails) = await aliceService.createRendezvous(),
              let alicePublicKey = rendezvousDetails.key else {
            XCTFail("Rendezvous creation failed")
            return
        }
        
        XCTAssertNotNil(mockTransport.rendezvousURL)
        
        let bobService = RendezvousService(transport: mockTransport, algorithm: .ECDH_V2)
        
        guard case .success = await bobService.joinRendezvous(withPublicKey: alicePublicKey) else {
            XCTFail("Bob failed to join")
            return
        }
         
        guard case .success = await aliceService.waitForInterlocutor() else {
            XCTFail("Alice failed to establish connection")
            return
        }
        
        guard let messageData = "Hello from alice".data(using: .utf8) else {
            fatalError()
        }
        
        guard case .success = await aliceService.send(data: messageData) else {
            XCTFail("Alice failed to send message")
            return
        }
        
        guard case .success(let data) = await bobService.receive() else {
            XCTFail("Bob failed to receive message")
            return
        }
        
        XCTAssertEqual(messageData, data)
    }
}
