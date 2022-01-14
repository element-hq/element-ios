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

/// RoomTimelineConfiguration enables to manage room timeline appearance configuration
@objcMembers
class RoomTimelineConfiguration: NSObject {
    
    // MARK: - Constants
    
    static let shared = RoomTimelineConfiguration()
    
    // MARK: - Properties
    
    private(set) var currentStyle: RoomTimelineStyle
    
    // MARK: - Setup
    
    init(style: RoomTimelineStyle) {
        self.currentStyle = style
        
        super.init()
    }
    
    convenience init(styleIdentifier: RoomTimelineStyleIdentifier) {
        
        let style = type(of: self).style(for: styleIdentifier)
        self.init(style: style)
    }
    
    convenience override init() {
        let styleIdentifier = RiotSettings.shared.roomTimelineStyleIdentifier
        self.init(styleIdentifier: styleIdentifier)
    }
    
    // MARK: - Public
    
    func updateStyle(_ roomTimelineStyle: RoomTimelineStyle) {
        self.currentStyle = roomTimelineStyle
    }
    
    func updateStyle(withIdentifier identifier: RoomTimelineStyleIdentifier) {
        
        let style = type(of: self).style(for: identifier)
        
        self.updateStyle(style)
    }
    
    // MARK: - Private
        
    private class func style(for identifier: RoomTimelineStyleIdentifier) -> RoomTimelineStyle {
        
        let roomTimelineStyle: RoomTimelineStyle
        
        switch identifier {
        case .plain:
            roomTimelineStyle = PlainRoomTimelineStyle()
        case .bubble:
            roomTimelineStyle = BubbleRoomTimelineStyle()
        }
        
        return roomTimelineStyle
    }
}
