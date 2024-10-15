/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

/// A structure that parses Matrix Room ID and constructs their constituent parts.
struct RoomIdComponents {
    
    // MARK: - Constants
    
    private enum Constants {
        static let matrixRoomIdPrefix = "!"
        static let homeServerSeparator: Character = ":"
    }
    
    // MARK: - Properties
    
    let localRoomId: String
    let homeServer: String
    
    // MARK: - Setup
    
    init?(matrixID: String) {
        guard MXTools.isMatrixRoomIdentifier(matrixID),
            let (localRoomId, homeServer) = RoomIdComponents.getLocalRoomIDAndHomeServer(from: matrixID) else {
            return nil
        }
        
        self.localRoomId = localRoomId
        self.homeServer = homeServer
    }
    
    // MARK: - Private    

    /// Extract local room id and homeserver from Matrix ID
    ///
    /// - Parameter matrixID: A Matrix ID
    /// - Returns: A tuple with local room ID and homeserver.
    private static func getLocalRoomIDAndHomeServer(from matrixID: String) -> (String, String)? {
        let matrixIDParts = matrixID.split(separator: Constants.homeServerSeparator)
        
        guard matrixIDParts.count == 2 else {
            return nil
        }
        
        let localRoomID = matrixIDParts[0].replacingOccurrences(of: Constants.matrixRoomIdPrefix, with: "")
        let homeServer = String(matrixIDParts[1])

        return (localRoomID, homeServer)
    }
}
