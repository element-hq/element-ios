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

import Combine
import Foundation
import MatrixSDK

class SpaceCreationPostProcessService: SpaceCreationPostProcessServiceProtocol {
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let parentSpaceId: String?
    private let creationParams: SpaceCreationParameters
    
    private var tasks: [SpaceCreationPostProcessTask] = []
    private var currentTaskIndex = 0
    private var isRetry = false
    
    private(set) var createdSpace: MXSpace? {
        didSet {
            createdSpaceId = createdSpace?.spaceId
        }
    }

    private var createdRoomsByName: [String: MXRoom] = [:]
    
    private var currentSubTaskIndex = 0

    private var processingQueue = DispatchQueue(label: "io.element.MXSpace.processingQueue", attributes: .concurrent)

    private lazy var stateEventBuilder = MXRoomInitialStateEventBuilder()

    private lazy var mediaUploader: MXMediaLoader = MXMediaManager.prepareUploader(withMatrixSession: session, initialRange: 0, andRange: 1.0)
    
    // MARK: Public
    
    private(set) var tasksSubject: CurrentValueSubject<[SpaceCreationPostProcessTask], Never>
    private(set) var createdSpaceId: String?
    var avatar: AvatarInput {
        let alias = creationParams.userDefinedAddress.isEmptyOrNil ? creationParams.address : creationParams.userDefinedAddress
        return AvatarInput(mxContentUri: alias, matrixItemId: "", displayName: creationParams.name)
    }

    var avatarImage: UIImage? {
        creationParams.userSelectedAvatar
    }

    // MARK: - Setup
    
    init(session: MXSession, parentSpaceId: String?, creationParams: SpaceCreationParameters) {
        self.session = session
        self.parentSpaceId = parentSpaceId
        self.creationParams = creationParams
        tasks = Self.tasks(with: creationParams)
        tasksSubject = CurrentValueSubject(tasks)
    }

    deinit { }
    
    // MARK: - Public
    
    func run() {
        isRetry = currentTaskIndex > 0
        currentTaskIndex = -1
        runNextTask()
    }
    
    // MARK: - Private
    
    private static func tasks(with creationParams: SpaceCreationParameters) -> [SpaceCreationPostProcessTask] {
        guard let spaceName = creationParams.name else {
            MXLog.error("[SpaceCreationPostProcessService] setupTasks: space name shouldn't be nil")
            return []
        }
        
        var tasks = [SpaceCreationPostProcessTask(type: .createSpace, title: VectorL10n.spacesCreationPostProcessCreatingSpaceTask(spaceName), state: .none)]
        if creationParams.userSelectedAvatar != nil {
            tasks.append(SpaceCreationPostProcessTask(type: .uploadAvatar, title: VectorL10n.spacesCreationPostProcessUploadingAvatar, state: .none))
        }
        if let addedRoomIds = creationParams.addedRoomIds {
            if !addedRoomIds.isEmpty {
                let subTasks = addedRoomIds.map { roomId in
                    SpaceCreationPostProcessTask(type: .addRooms, title: roomId, state: .none)
                }
                tasks.append(SpaceCreationPostProcessTask(type: .addRooms, title: VectorL10n.spacesCreationPostProcessAddingRooms("\(addedRoomIds.count)"), state: .none, subTasks: subTasks))
            }
        } else {
            tasks.append(contentsOf: creationParams.newRooms.compactMap { room in
                guard !room.name.isEmpty else {
                    return nil
                }
                
                return SpaceCreationPostProcessTask(type: .createRoom(room.name), title: VectorL10n.spacesCreationPostProcessCreatingRoom(room.name), state: .none)
            })
        }
        
        if creationParams.inviteType == .email {
            let emailInviteCount = creationParams.userDefinedEmailInvites.count
            if emailInviteCount > 0 {
                let subTasks = creationParams.userDefinedEmailInvites.map { emailAddress in
                    SpaceCreationPostProcessTask(type: .inviteUsersByEmail, title: emailAddress, state: .none)
                }
                
                tasks.append(SpaceCreationPostProcessTask(type: .inviteUsersByEmail, title: VectorL10n.spacesCreationPostProcessInvitingUsers("\(creationParams.userDefinedEmailInvites.count)"), state: .none, subTasks: subTasks))
            }
        }
        
        return tasks
    }
    
    private func runNextTask() {
        currentTaskIndex += 1
        guard currentTaskIndex < tasks.count else {
            return
        }
        
        let task = tasks[currentTaskIndex]

        guard !task.isFinished || task.state == .failure else {
            runNextTask()
            return
        }
        
        switch task.type {
        case .createSpace:
            createSpace(andUpdate: task)
        case .uploadAvatar:
            uploadAvatar(andUpdate: task)
        case .addRooms:
            addRooms(andUpdate: task)
        case .createRoom(let roomName):
            if let room = createdRoomsByName[roomName] {
                addToSpace(room: room)
            } else {
                createRoom(withName: roomName, andUpdate: task)
            }
        case .inviteUsersByEmail:
            inviteUsersByEmail(andUpdate: task)
        }
    }
    
    private func createSpace(andUpdate task: SpaceCreationPostProcessTask) {
        updateCurrentTask(with: .started)
        
        var alias = creationParams.address
        if let userDefinedAlias = creationParams.userDefinedAddress, !userDefinedAlias.isEmpty {
            alias = userDefinedAlias
        }
        let userIdInvites = creationParams.inviteType == .userId ? creationParams.userIdInvites : []
        session.spaceService.createSpace(withName: creationParams.name, topic: creationParams.topic, isPublic: creationParams.isPublic, aliasLocalPart: alias, inviteArray: userIdInvites) { [weak self] response in
            guard let self = self else { return }
            
            if response.isFailure {
                self.updateCurrentTask(with: .failure)
            } else {
                self.creationParams.isModified = false
                self.createdSpace = response.value

                guard let createdSpaceId = self.createdSpace?.spaceId, let parentSpaceId = self.parentSpaceId, let parentSpace = self.session.spaceService.getSpace(withId: parentSpaceId) else {
                    self.updateCurrentTask(with: .success)
                    self.runNextTask()
                    return
                }
                
                parentSpace.addChild(roomId: createdSpaceId) { [weak self] _ in
                    guard let self = self else { return }
                    
                    self.updateCurrentTask(with: .success)
                    self.runNextTask()
                }
            }
        }
    }
    
    private func uploadAvatar(andUpdate task: SpaceCreationPostProcessTask) {
        updateCurrentTask(with: .started)

        guard let avatar = creationParams.userSelectedAvatar, let spaceRoom = createdSpace?.room else {
            updateCurrentTask(with: .success)
            runNextTask()
            return
        }
        
        let avatarUp = MXKTools.forceImageOrientationUp(avatar)
        
        mediaUploader.uploadData(avatarUp?.jpegData(compressionQuality: 0.5), filename: nil, mimeType: "image/jpeg",
                                 success: { [weak self] urlString in
                                     guard let self = self else { return }
                                     guard let urlString = urlString else { return }
                                     guard let url = URL(string: urlString) else { return }
                                    
                                     self.setAvatar(ofRoom: spaceRoom, withURL: url, andUpdate: task)
                                 },
                                 failure: { [weak self] _ in
                                     guard let self = self else { return }
                                    
                                     self.updateCurrentTask(with: .failure)
                                     self.runNextTask()
                                 })
    }
    
    private func setAvatar(ofRoom room: MXRoom, withURL url: URL, andUpdate task: SpaceCreationPostProcessTask) {
        updateCurrentTask(with: .started)
        
        room.setAvatar(url: url) { [weak self] response in
            guard let self = self else { return }

            self.updateCurrentTask(with: response.isSuccess ? .success : .failure)
            self.runNextTask()
        }
    }

    private func createRoom(withName roomName: String, andUpdate task: SpaceCreationPostProcessTask) {
        guard let createdSpace = createdSpace else {
            updateCurrentTask(with: .failure)
            runNextTask()
            return
        }
        
        updateCurrentTask(with: .started)
        
        let joinRule: MXRoomJoinRule = creationParams.isPublic ? .public : .restricted
        let parentRoomId = creationParams.isPublic ? nil : createdSpace.spaceId
        session.createRoom(withName: roomName, joinRule: joinRule, topic: nil, parentRoomId: parentRoomId, aliasLocalPart: nil) { [weak self] response in
            guard let self = self else { return }

            guard response.isSuccess, let createdRoom = response.value else {
                self.updateCurrentTask(with: .failure)
                self.runNextTask()
                return
            }

            self.createdRoomsByName[roomName] = createdRoom
            self.addToSpace(room: createdRoom)
        }
    }
    
    private func addToSpace(room: MXRoom) {
        guard let createdSpace = createdSpace else {
            updateCurrentTask(with: .failure)
            runNextTask()
            return
        }

        createdSpace.addChild(roomId: room.matrixItemId, completion: { response in
            self.updateCurrentTask(with: response.isFailure ? .failure : .success)
            self.runNextTask()
        })
    }
    
    private func addRooms(andUpdate task: SpaceCreationPostProcessTask) {
        updateCurrentTask(with: .started)
        currentSubTaskIndex = -1
        addNextExistingRoom()
    }
    
    private func inviteUsersByEmail(andUpdate task: SpaceCreationPostProcessTask) {
        updateCurrentTask(with: .started)
        currentSubTaskIndex = -1
        inviteNextUserByEmail()
    }
    
    private func inviteNextUserByEmail() {
        guard let createdSpace = createdSpace, let room = createdSpace.room else {
            updateCurrentTask(with: .failure)
            runNextTask()
            return
        }
        
        currentSubTaskIndex += 1
        
        guard currentSubTaskIndex < tasks[currentTaskIndex].subTasks.count else {
            let isSuccess = tasks[currentTaskIndex].subTasks.reduce(true) { $0 && $1.state == .success }
            updateCurrentTask(with: isSuccess ? .success : .failure)
            runNextTask()
            return
        }
        
        room.invite(.email(creationParams.emailInvites[currentSubTaskIndex])) { [weak self] response in
            guard let self = self else { return }
            
            self.tasks[self.currentTaskIndex].subTasks[self.currentSubTaskIndex].state = response.isSuccess ? .success : .failure
            self.inviteNextUserByEmail()
        }
    }
    
    private func addNextExistingRoom() {
        guard let createdSpace = createdSpace else {
            updateCurrentTask(with: .failure)
            runNextTask()
            return
        }
        
        currentSubTaskIndex += 1
        
        guard currentSubTaskIndex < tasks[currentTaskIndex].subTasks.count else {
            let isSuccess = tasks[currentTaskIndex].subTasks.reduce(true) { $0 && $1.state == .success }
            updateCurrentTask(with: isSuccess ? .success : .failure)
            runNextTask()
            return
        }
        
        guard let roomId = creationParams.addedRoomIds?[currentSubTaskIndex] else {
            updateCurrentTask(with: .failure)
            runNextTask()
            return
        }
        
        createdSpace.addChild(roomId: roomId, completion: { [weak self] response in
            guard let self = self else { return }
            
            self.tasks[self.currentTaskIndex].subTasks[self.currentSubTaskIndex].state = response.isSuccess ? .success : .failure
            self.addNextExistingRoom()
        })
    }
    
    private func fakeTaskExecution(task: SpaceCreationPostProcessTask) {
        updateCurrentTask(with: .started)
        processingQueue.async {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.updateCurrentTask(with: .success)
                self.runNextTask()
            }
        }
    }
    
    private func updateCurrentTask(with state: SpaceCreationPostProcessTaskState) {
        guard currentTaskIndex < tasks.count else {
            return
        }
        
        tasks[currentTaskIndex].state = state
        tasksSubject.send(tasks)
    }
}
