// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationPostProcess SpaceCreationPostProcess
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
import Combine
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
        return AvatarInput(mxContentUri: nil, matrixItemId: "", displayName: "Some space")
    }
    var avatarImage: UIImage? {
        return nil
    }

    init(
        tasks: [SpaceCreationPostProcessTask] = defaultTasks
    ) {
        self.tasksSubject = CurrentValueSubject<[SpaceCreationPostProcessTask], Never>(tasks)
    }
    
    func simulateUpdate(tasks: [SpaceCreationPostProcessTask]) {
        self.tasksSubject.send(tasks)
    }
    
    func run() {
    }
}
