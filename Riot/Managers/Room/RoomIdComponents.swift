/*
 Copyright 2019 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
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
