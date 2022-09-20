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
