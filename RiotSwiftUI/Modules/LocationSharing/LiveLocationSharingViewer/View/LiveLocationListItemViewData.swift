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

/// View data for LiveLocationListItem
struct LiveLocationListItemViewData: Identifiable {
    var id: String {
        userId
    }
        
    let userId: String
    
    let isCurrentUser: Bool
    
    let avatarData: AvatarInputProtocol
    
    let displayName: String
        
    /// The location sharing expiration date
    let expirationDate: TimeInterval
    
    /// Last coordinatore update
    let lastUpdate: TimeInterval
}
