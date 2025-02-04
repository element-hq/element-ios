//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
        state == .failure || state == .success
    }

    var subTasks: [SpaceCreationPostProcessTask] = []
    
    static func == (lhs: SpaceCreationPostProcessTask, rhs: SpaceCreationPostProcessTask) -> Bool {
        lhs.type == rhs.type && lhs.title == rhs.title && lhs.state == rhs.state && lhs.subTasks == lhs.subTasks
    }
}
