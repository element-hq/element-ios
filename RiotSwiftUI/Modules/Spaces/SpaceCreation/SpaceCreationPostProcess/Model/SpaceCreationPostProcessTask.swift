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

enum SpaceCreationPostProcessTaskState: CaseIterable, Equatable {
    static var allCases: [SpaceCreationPostProcessTaskState] = [.none, .started, .success, .failure]
    
    case none
    case started
    case success
    case failure
}

enum SpaceCreationPostProcessTaskType: Equatable {
    case createSpace
    case uploadAvatar
    case createRoom(_ roomName: String)
    case addRooms
    case inviteUsersByEmail
}

struct SpaceCreationPostProcessTask: Equatable {
    let type: SpaceCreationPostProcessTaskType
    let title: String
    var state: SpaceCreationPostProcessTaskState
    var isFinished: Bool {
        return state == .failure || state == .success
    }
    var subTasks: [SpaceCreationPostProcessTask] = []
    
    static func == (lhs: SpaceCreationPostProcessTask, rhs: SpaceCreationPostProcessTask) -> Bool {
        return lhs.type == rhs.type && lhs.title == rhs.title && lhs.state == rhs.state && lhs.subTasks == lhs.subTasks
    }
}
