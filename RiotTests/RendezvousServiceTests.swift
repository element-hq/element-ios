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

import XCTest
@testable import Element

@MainActor
class RendezvousServiceTests: XCTestCase {
    func testEnd2End() async {
        let mockTransport = MockRendezvousTransport()
        
        let aliceService = RendezvousService(transport: mockTransport)
        
        guard case .success(let rendezvousDetails) = await aliceService.createRendezvous(),
              let alicePublicKey = rendezvousDetails.key else {
            XCTFail("Rendezvous creation failed")
            return
        }
        
        XCTAssertNotNil(mockTransport.rendezvousURL)
        
        let bobService = RendezvousService(transport: mockTransport)
        
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
