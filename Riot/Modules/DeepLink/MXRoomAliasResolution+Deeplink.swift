// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixSDK

@objc extension MXRoomAliasResolution {
    
    /// Deeplink fragment using a room identifier and a list of servers aware of this identifier
    ///
    /// For more details see
    /// https://github.com/matrix-org/matrix-spec-proposals/blob/old_master/proposals/1704-matrix.to-permalinks.md
    var deeplinkFragment: String? {
        guard let roomId = roomId else {
            MXLog.debug("[MXRoomAliasResolution]: Missing room identifier")
            return nil
        }
        
        return fragment(for: roomId)
    }
    
    private func fragment(for roomId: String) -> String {
        guard let servers = servers, !servers.isEmpty else {
            return roomId
        }
        return roomId + "?via=" + servers.joined(separator: "&via=")
    }
}
