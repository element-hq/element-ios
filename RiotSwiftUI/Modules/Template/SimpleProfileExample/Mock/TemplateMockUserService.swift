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

struct TemplateMockUserService: TemplateUserServiceType {
    
    static let example = TemplateMockUserService(userId: "123", displayName: "Alice", avatarUrl: "mx123@matrix.com", currentlyActive: true, lastActive: 123456)
    
    let userId: String
    let displayName: String?
    let avatarUrl: String?
    let currentlyActive: Bool
    let lastActive: UInt
}
