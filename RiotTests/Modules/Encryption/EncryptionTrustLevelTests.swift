// 
// Copyright 2023 New Vector Ltd
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
import XCTest
@testable import Element
@testable import MatrixSDK

class EncryptionTrustLevelTests: XCTestCase {
    
    var encryption: EncryptionTrustLevel!
    override func setUp() {
        encryption = EncryptionTrustLevel()
    }
    
    // MARK: - Helpers
    
    func makeCrossSigning(isVerified: Bool) -> MXCrossSigningInfo {
        return .init(
            userIdentity: .init(
                identity: .other(
                    userId: "Bob",
                    masterKey: "MSK",
                    selfSigningKey: "SSK"
                ),
                isVerified: isVerified
            )
        )
    }
    
    func makeSummary(trusted: Int, total: Int) -> MXTrustSummary {
        MXTrustSummary(trustedCount: trusted, totalCount: total)
    }
    
    // MARK: - Users
    
    func test_userTrustLevel_whenCrossSigningDisabled() {
        let devicesToTrustLevel: [(MXTrustSummary, UserEncryptionTrustLevel)] = [
            (makeSummary(trusted: 0, total: 0), .notVerified),
            (makeSummary(trusted: 0, total: 2), .notVerified),
            (makeSummary(trusted: 1, total: 2), .warning),
            (makeSummary(trusted: 3, total: 4), .warning),
            (makeSummary(trusted: 5, total: 5), .trusted)
        ]
        
        for (devices, expected) in devicesToTrustLevel {
            let trustLevel = encryption.userTrustLevel(
                crossSigning: nil,
                devicesTrust: devices
            )
            XCTAssertEqual(trustLevel, expected, "\(devices.trustedCount) trusted device(s) out of \(devices.totalCount)")
        }
    }
    
    func test_userTrustLevel_whenCrossSigningNotVerified() {
        let devicesToTrustLevel: [(MXTrustSummary, UserEncryptionTrustLevel)] = [
            (makeSummary(trusted: 0, total: 0), .notVerified),
            (makeSummary(trusted: 0, total: 2), .notVerified),
            (makeSummary(trusted: 1, total: 2), .notVerified),
            (makeSummary(trusted: 3, total: 4), .notVerified),
            (makeSummary(trusted: 5, total: 5), .notVerified)
        ]
        
        for (devices, expected) in devicesToTrustLevel {
            let trustLevel = encryption.userTrustLevel(
                crossSigning: makeCrossSigning(isVerified: false),
                devicesTrust: devices
            )
            XCTAssertEqual(trustLevel, expected, "\(devices.trustedCount) trusted device(s) out of \(devices.totalCount)")
        }
    }
    
    func test_userTrustLevel_whenCrossSigningVerified() {
        let devicesToTrustLevel: [(MXTrustSummary, UserEncryptionTrustLevel)] = [
            (makeSummary(trusted: 0, total: 0), .trusted),
            (makeSummary(trusted: 0, total: 2), .warning),
            (makeSummary(trusted: 1, total: 2), .warning),
            (makeSummary(trusted: 3, total: 4), .warning),
            (makeSummary(trusted: 5, total: 5), .trusted)
        ]
        
        for (devices, expected) in devicesToTrustLevel {
            let trustLevel = encryption.userTrustLevel(
                crossSigning: makeCrossSigning(isVerified: true),
                devicesTrust: devices
            )
            XCTAssertEqual(trustLevel, expected, "\(devices.trustedCount) trusted device(s) out of \(devices.totalCount)")
        }
    }
    
    // MARK: - Rooms
    
    func test_roomTrustLevel() {
        let usersDevicesToTrustLevel: [(MXTrustSummary, MXTrustSummary, RoomEncryptionTrustLevel)] = [
            // No users verified
            (makeSummary(trusted: 0, total: 0), makeSummary(trusted: 0, total: 0), .normal),
            
            // Only some users verified
            (makeSummary(trusted: 0, total: 1), makeSummary(trusted: 0, total: 1), .normal),
            (makeSummary(trusted: 3, total: 4), makeSummary(trusted: 5, total: 5), .normal),
            (makeSummary(trusted: 3, total: 4), makeSummary(trusted: 5, total: 5), .normal),
            
            // All users verified
            (makeSummary(trusted: 2, total: 2), makeSummary(trusted: 0, total: 0), .trusted),
            (makeSummary(trusted: 3, total: 3), makeSummary(trusted: 0, total: 1), .warning),
            (makeSummary(trusted: 3, total: 3), makeSummary(trusted: 3, total: 4), .warning),
            (makeSummary(trusted: 4, total: 4), makeSummary(trusted: 5, total: 5), .trusted),
        ]
        
        for (users, devices, expected) in usersDevicesToTrustLevel {
            let trustLevel = encryption.roomTrustLevel(
                summary: MXUsersTrustLevelSummary(
                    usersTrust: users,
                    devicesTrust: devices
                )
            )
            XCTAssertEqual(trustLevel, expected, "\(users.trustedCount)/\(users.totalCount) trusted users(s), \(devices.trustedCount)/\(devices.totalCount) trusted device(s)")
        }
    }
}

extension UserEncryptionTrustLevel: CustomStringConvertible {
    public var description: String {
        switch self {
        case .trusted:
            return "trusted"
        case .warning:
            return "warning"
        case .notVerified:
            return "notVerified"
        case .noCrossSigning:
            return "noCrossSigning"
        case .none:
            return "none"
        case .unknown:
            return "unknown"
        @unknown default:
            return "unknown"
        }
    }
}

extension RoomEncryptionTrustLevel: CustomStringConvertible {
    public var description: String {
        switch self {
        case .trusted:
            return "trusted"
        case .warning:
            return "warning"
        case .normal:
            return "normal"
        case .unknown:
            return "unknown"
        @unknown default:
            return "unknown"
        }
    }
}
