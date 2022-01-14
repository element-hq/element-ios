// 
// Copyright 2021 New Vector Ltd
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

class PlainRoomTimelineStyle: RoomTimelineStyle {

    // MARK: - Properties
    
    let identifier: RoomTimelineStyleIdentifier
    
    let cellLayoutUpdater: RoomCellLayoutUpdaterProtocol?
    
    let cellProvider: RoomTimelineCellProviderProtocol
    
    // MARK: - Setup
    
    init() {
        self.identifier = .plain
        self.cellLayoutUpdater = nil
        self.cellProvider = PlainRoomTimelineCellProvider()
    }
    
    // MARK: - Methods
    
    func canAddEvent(_ event: MXEvent, and roomState: MXRoomState, to cellData: MXKRoomBubbleCellData) -> Bool {
        return true
    }
}
