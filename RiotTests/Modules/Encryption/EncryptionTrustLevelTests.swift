// 
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
    
    func makeProgress(trusted: Int, total: Int) -> Progress {
        let progress = Progress(totalUnitCount: Int64(total))
        progress.completedUnitCount = Int64(trusted)
        return progress
    }
    
    // MARK: - Users
    
    func test_userTrustLevel_whenCrossSigningDisabled() {
        let devicesToTrustLevel: [(Progress, UserEncryptionTrustLevel)] = [
            (makeProgress(trusted: 0, total: 0), .notVerified),
            (makeProgress(trusted: 0, total: 2), .notVerified),
            (makeProgress(trusted: 1, total: 2), .warning),
            (makeProgress(trusted: 3, total: 4), .warning),
            (makeProgress(trusted: 5, total: 5), .trusted),
            (makeProgress(trusted: 10, total: 5), .trusted)
        ]
        
        for (devices, expected) in devicesToTrustLevel {
            let trustLevel = encryption.userTrustLevel(
                crossSigning: nil,
                trustedDevicesProgress: devices
            )
            XCTAssertEqual(trustLevel, expected, "\(devices.completedUnitCount) trusted device(s) out of \(devices.totalUnitCount)")
        }
    }
    
    func test_userTrustLevel_whenCrossSigningNotVerified() {
        let devicesToTrustLevel: [(Progress, UserEncryptionTrustLevel)] = [
            (makeProgress(trusted: 0, total: 0), .notVerified),
            (makeProgress(trusted: 0, total: 2), .notVerified),
            (makeProgress(trusted: 1, total: 2), .notVerified),
            (makeProgress(trusted: 3, total: 4), .notVerified),
            (makeProgress(trusted: 5, total: 5), .notVerified),
            (makeProgress(trusted: 10, total: 5), .notVerified)
        ]
        
        for (devices, expected) in devicesToTrustLevel {
            let trustLevel = encryption.userTrustLevel(
                crossSigning: makeCrossSigning(isVerified: false),
                trustedDevicesProgress: devices
            )
            XCTAssertEqual(trustLevel, expected, "\(devices.completedUnitCount) trusted device(s) out of \(devices.totalUnitCount)")
        }
    }
    
    func test_userTrustLevel_whenCrossSigningVerified() {
        let devicesToTrustLevel: [(Progress, UserEncryptionTrustLevel)] = [
            (makeProgress(trusted: 0, total: 0), .trusted),
            (makeProgress(trusted: 0, total: 2), .warning),
            (makeProgress(trusted: 1, total: 2), .warning),
            (makeProgress(trusted: 3, total: 4), .warning),
            (makeProgress(trusted: 5, total: 5), .trusted),
            (makeProgress(trusted: 10, total: 5), .trusted)
        ]
        
        for (devices, expected) in devicesToTrustLevel {
            let trustLevel = encryption.userTrustLevel(
                crossSigning: makeCrossSigning(isVerified: true),
                trustedDevicesProgress: devices
            )
            XCTAssertEqual(trustLevel, expected, "\(devices.completedUnitCount) trusted device(s) out of \(devices.totalUnitCount)")
        }
    }
    
    // MARK: - Rooms
    
    func test_roomTrustLevel() {
        let usersDevicesToTrustLevel: [(Progress, Progress, RoomEncryptionTrustLevel)] = [
            // No users verified
            (makeProgress(trusted: 0, total: 0), makeProgress(trusted: 0, total: 0), .normal),
            
            // Only some users verified
            (makeProgress(trusted: 0, total: 1), makeProgress(trusted: 0, total: 1), .normal),
            (makeProgress(trusted: 3, total: 4), makeProgress(trusted: 5, total: 5), .normal),
            (makeProgress(trusted: 3, total: 4), makeProgress(trusted: 5, total: 5), .normal),
            
            // All users verified
            (makeProgress(trusted: 2, total: 2), makeProgress(trusted: 0, total: 0), .trusted),
            (makeProgress(trusted: 3, total: 3), makeProgress(trusted: 0, total: 1), .warning),
            (makeProgress(trusted: 3, total: 3), makeProgress(trusted: 3, total: 4), .warning),
            (makeProgress(trusted: 4, total: 4), makeProgress(trusted: 5, total: 5), .trusted),
            (makeProgress(trusted: 10, total: 4), makeProgress(trusted: 10, total: 5), .trusted),
        ]
        
        for (users, devices, expected) in usersDevicesToTrustLevel {
            let trustLevel = encryption.roomTrustLevel(
                summary: MXUsersTrustLevelSummary(
                    trustedUsersProgress: users,
                    andTrustedDevicesProgress: devices
                )
            )
            XCTAssertEqual(trustLevel, expected, "\(users.completedUnitCount)/\(users.totalUnitCount) trusted users(s), \(devices.completedUnitCount)/\(devices.totalUnitCount) trusted device(s)")
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
