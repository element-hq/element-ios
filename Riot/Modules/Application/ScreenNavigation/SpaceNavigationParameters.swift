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

/// Navigation parameters to display a space with a provided identifier in a specific matrix session.
@objcMembers
class SpaceNavigationParameters: NSObject {
    
    // MARK: - Properties

    /// The room identifier
    let roomId: String
    
    /// The Matrix session in which the room should be available.
    let mxSession: MXSession
    
    /// Screen presentation parameters.
    let presentationParameters: ScreenPresentationParameters
    
    // MARK: - Setup
    
    init(roomId: String,
         mxSession: MXSession,
         presentationParameters: ScreenPresentationParameters) {
        self.roomId = roomId
        self.mxSession = mxSession
        self.presentationParameters = presentationParameters
        
        super.init()
    }
}
