// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationPostProcess SpaceCreationPostProcess
//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import UIKit

class MockSpaceCreationPostProcessService: SpaceCreationPostProcessServiceProtocol {
    static let defaultTasks: [SpaceCreationPostProcessTask] = [
        SpaceCreationPostProcessTask(type: .createSpace, title: "Space creation", state: .success),
        SpaceCreationPostProcessTask(type: .createRoom("Room#1"), title: "Room#1 creation", state: .failure),
        SpaceCreationPostProcessTask(type: .createRoom("Room#2"), title: "Room#2 creation", state: .started),
        SpaceCreationPostProcessTask(type: .createRoom("Room#3"), title: "Room#3 creation", state: .none)
    ]
    
    static let nextStepTasks: [SpaceCreationPostProcessTask] = [
        SpaceCreationPostProcessTask(type: .createSpace, title: "Space creation", state: .success),
        SpaceCreationPostProcessTask(type: .createRoom("Room#1"), title: "Room#1 creation", state: .failure),
        SpaceCreationPostProcessTask(type: .createRoom("Room#2"), title: "Room#2 creation", state: .failure),
        SpaceCreationPostProcessTask(type: .createRoom("Room#3"), title: "Room#3 creation", state: .started)
    ]
    
    static let lastTaskDoneWithError: [SpaceCreationPostProcessTask] = [
        SpaceCreationPostProcessTask(type: .createSpace, title: "Space creation", state: .success),
        SpaceCreationPostProcessTask(type: .createRoom("Room#1"), title: "Room#1 creation", state: .failure),
        SpaceCreationPostProcessTask(type: .createRoom("Room#2"), title: "Room#2 creation", state: .failure),
        SpaceCreationPostProcessTask(type: .createRoom("Room#3"), title: "Room#3 creation", state: .success)
    ]

    static let lastTaskDoneSuccesfully: [SpaceCreationPostProcessTask] = [
        SpaceCreationPostProcessTask(type: .createSpace, title: "Space creation", state: .success),
        SpaceCreationPostProcessTask(type: .createRoom("Room#1"), title: "Room#1 creation", state: .success),
        SpaceCreationPostProcessTask(type: .createRoom("Room#2"), title: "Room#2 creation", state: .success),
        SpaceCreationPostProcessTask(type: .createRoom("Room#3"), title: "Room#3 creation", state: .success)
    ]

    var tasksSubject: CurrentValueSubject<[SpaceCreationPostProcessTask], Never>
    private(set) var createdSpaceId: String?
    var avatar: AvatarInput {
        AvatarInput(mxContentUri: nil, matrixItemId: "", displayName: "Some space")
    }

    var avatarImage: UIImage? {
        nil
    }

    init(
        tasks: [SpaceCreationPostProcessTask] = defaultTasks
    ) {
        tasksSubject = CurrentValueSubject<[SpaceCreationPostProcessTask], Never>(tasks)
    }
    
    func simulateUpdate(tasks: [SpaceCreationPostProcessTask]) {
        tasksSubject.send(tasks)
    }
    
    func run() { }
}
