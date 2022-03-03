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

@available(iOS 14.0, *)
class SpaceSettingsService: SpaceSettingsServiceProtocol {

    // MARK: - Properties
    
    var userDefinedAddress: String? {
        didSet {
            validateAddress()
        }
    }

    // MARK: Private
    
    private let session: MXSession
    private var roomState: MXRoomState? {
        didSet {
            updateRoomProperties()
        }
    }
    private let room: MXRoom?
    private var roomEventListener: Any?
    
    private var publicAddress: String? {
        didSet {
            validateAddress()
        }
    }
    
    private var defaultAddress: String {
        didSet {
            validateAddress()
        }
    }

    // MARK: Public
    
    var displayName: String? {
        room?.displayName
    }
    
    private(set) var spaceId: String
    private(set) var roomProperties: SpaceSettingsRoomProperties? {
        didSet {
            roomPropertiesSubject.send(roomProperties)
        }
    }
    
    private(set) var isLoadingSubject: CurrentValueSubject<Bool, Never>
    private(set) var roomPropertiesSubject: CurrentValueSubject<SpaceSettingsRoomProperties?, Never>
    private(set) var showPostProcessAlert: CurrentValueSubject<Bool, Never>
    
    private(set) var addressValidationSubject: CurrentValueSubject<SpaceCreationSettingsAddressValidationStatus, Never>
    var isAddressValid: Bool {
        switch addressValidationSubject.value {
        case .none, .valid:
            return true
        default:
            return false
        }
    }

    private var currentOperation: MXHTTPOperation?
    private var addressValidationOperation: MXHTTPOperation?
    
    private lazy var mediaUploader: MXMediaLoader = MXMediaManager.prepareUploader(withMatrixSession: session, initialRange: 0, andRange: 1.0)
    
    // MARK: - Setup
    
    init(session: MXSession, spaceId: String) {
        self.session = session
        self.spaceId = spaceId
        self.room = session.room(withRoomId: spaceId)
        self.isLoadingSubject = CurrentValueSubject(false)
        self.showPostProcessAlert = CurrentValueSubject(false)
        self.roomPropertiesSubject = CurrentValueSubject(self.roomProperties)
        self.addressValidationSubject = CurrentValueSubject(.none("#"))
        self.defaultAddress = ""
        
        readRoomState()
    }
    
    deinit {
        if let roomEventListener = self.roomEventListener {
            self.room?.removeListener(roomEventListener)
        }
        
        currentOperation?.cancel()
        addressValidationOperation?.cancel()
    }
    
    // MARK: - Public
    
    func addressDidChange(_ newValue: String) {
        userDefinedAddress = newValue
    }
    
    // MARK: - Private
    
    private func readRoomState() {
        isLoadingSubject.send(true)
        self.room?.state { [weak self] roomState in
            self?.roomState = roomState
            self?.isLoadingSubject.send(false)
        }
        
        roomEventListener = self.room?.listen(toEvents: { [weak self] event, direction, state in
            self?.room?.state({ [weak self] roomState in
                self?.roomState = roomState
            })
        })
    }
    
    private func visibility(with roomState: MXRoomState) -> SpaceSettingsVisibility {
        switch roomState.joinRule {
        case .public:
            return .public
        case .restricted:
            return .restricted
        default:
            return .private
        }
    }

    private func allowedParentIds(with roomState: MXRoomState) -> [String] {
        var allowedParentIds: [String] = []
        if roomState.joinRule == .restricted, let joinRuleEvent = roomState.stateEvents(with: .roomJoinRules)?.last {
            let allowContent: [[String: String]] = joinRuleEvent.wireContent["allow"] as? [[String: String]] ?? []
            allowedParentIds = allowContent.compactMap { allowDictionnary in
                guard let type = allowDictionnary["type"], type == "m.room_membership" else {
                    return nil
                }
                
                return allowDictionnary["room_id"]
            }
        }
        return allowedParentIds
    }
    
    private func isField(ofType notification: String, editableWith powerLevels: MXRoomPowerLevels?) -> Bool {
        guard let powerLevels = powerLevels else {
            return false
        }
        
        let userPowerLevel = powerLevels.powerLevelOfUser(withUserID: self.session.myUserId)
        return userPowerLevel >= powerLevels.minimumPowerLevel(forNotifications: notification, defaultPower: powerLevels.stateDefault)
    }
    
    private func validateAddress() {
        addressValidationOperation?.cancel()
        addressValidationOperation = nil

        guard let userDefinedAddress = self.userDefinedAddress, !userDefinedAddress.isEmpty else {
            let fullAddress = defaultAddress.fullLocalAlias(with: session)

            if let publicAddress = self.publicAddress, !publicAddress.isEmpty {
                addressValidationSubject.send(.current(fullAddress))
            } else if defaultAddress.isEmpty {
                addressValidationSubject.send(.none(fullAddress))
            } else {
                validate(defaultAddress)
            }
            return
        }

        validate(userDefinedAddress)
    }
    
    private func validate(_ aliasLocalPart: String) {
        let fullAddress = aliasLocalPart.fullLocalAlias(with: session)

        if let publicAddress = self.publicAddress, publicAddress == aliasLocalPart {
            self.addressValidationSubject.send(.current(fullAddress))
            return
        }
        
        addressValidationOperation = MXRoomAliasAvailabilityChecker.validate(aliasLocalPart: aliasLocalPart, with: session) { [weak self] result in
            guard let self = self else { return }
            
            self.addressValidationOperation = nil
            
            switch result {
            case .available:
                self.addressValidationSubject.send(.valid(fullAddress))
            case .invalid:
                self.addressValidationSubject.send(.invalidCharacters(fullAddress))
            case .notAvailable:
                self.addressValidationSubject.send(.alreadyExists(fullAddress))
            case .serverError:
                self.addressValidationSubject.send(.none(fullAddress))
            }
        }
    }

    private func updateRoomProperties() {
        guard let roomState = roomState else {
            return
        }
        
        self.publicAddress = roomState.canonicalAlias?.extractLocalAliasPart()
        self.defaultAddress = self.publicAddress ?? roomState.name.toValidAliasLocalPart()
        
        self.roomProperties = SpaceSettingsRoomProperties(
            name: roomState.name,
            topic: roomState.topic,
            address: self.defaultAddress,
            avatarUrl: roomState.avatar,
            visibility: visibility(with: roomState),
            allowedParentIds: allowedParentIds(with: roomState),
            isAvatarEditable: isField(ofType: kMXEventTypeStringRoomAvatar, editableWith: roomState.powerLevels),
            isNameEditable: isField(ofType: kMXEventTypeStringRoomName, editableWith: roomState.powerLevels),
            isTopicEditable: isField(ofType: kMXEventTypeStringRoomTopic, editableWith: roomState.powerLevels),
            isAddressEditable: isField(ofType: kMXEventTypeStringRoomAliases, editableWith: roomState.powerLevels),
            isAccessEditable: isField(ofType: kMXEventTypeStringRoomJoinRules, editableWith: roomState.powerLevels))
    }
    
    // MARK: - Post process
    
    private var currentTaskIndex: Int = 0
    private var tasks: [PostProcessTask] = []
    private var lastError: Error?
    private var completion: ((_ result: SpaceSettingsServiceCompletionResult) -> Void)?

    private enum PostProcessTaskType: Equatable {
        case updateName(String)
        case updateTopic(String)
        case updateAlias(String)
        case uploadAvatar(UIImage)
    }

    private enum PostProcessTaskState: CaseIterable, Equatable {
        case none
        case started
        case success
        case failure
    }

    private struct PostProcessTask: Equatable {
        let type: PostProcessTaskType
        var state: PostProcessTaskState = .none
        var isFinished: Bool {
            return state == .failure || state == .success
        }
        
        static func == (lhs: PostProcessTask, rhs: PostProcessTask) -> Bool {
            return lhs.type == rhs.type && lhs.state == rhs.state
        }
    }

    func update(roomName: String, topic: String, address: String, avatar: UIImage?,
                completion: ((_ result: SpaceSettingsServiceCompletionResult) -> Void)?) {
        // First attempt
        if self.tasks.isEmpty {
            var tasks: [PostProcessTask] = []
            if roomProperties?.name ?? "" != roomName {
                tasks.append(PostProcessTask(type: .updateName(roomName)))
            }
            if roomProperties?.topic ?? "" != topic {
                tasks.append(PostProcessTask(type: .updateTopic(topic)))
            }
            if roomProperties?.address ?? "" != address {
                tasks.append(PostProcessTask(type: .updateAlias(address)))
            }
            if let avatarImage = avatar {
                tasks.append(PostProcessTask(type: .uploadAvatar(avatarImage)))
            }
            self.tasks = tasks
        } else {
            // Retry -> restart failed tasks
            self.tasks = tasks.map({ task in
                if task.state == .failure {
                    return PostProcessTask(type: task.type, state: .none)
                }
                return task
            })
        }
        
        self.isLoadingSubject.send(true)
        self.completion = completion
        self.lastError = nil
        currentTaskIndex = -1
        runNextTask()
    }
    
    private func runNextTask() {
        currentTaskIndex += 1
        guard currentTaskIndex < tasks.count else {
            self.isLoadingSubject.send(false)
            if let error = lastError {
                showPostProcessAlert.send(true)
                completion?(.failure(error))
            } else {
                completion?(.success)
            }
            return
        }
        
        let task = tasks[currentTaskIndex]

        guard !task.isFinished else {
            runNextTask()
            return
        }

        switch task.type {
        case .updateName(let roomName):
            update(roomName: roomName)
        case .updateTopic(let topic):
            update(topic: topic)
        case .updateAlias(let address):
            update(canonicalAlias: address)
        case .uploadAvatar(let image):
            upload(avatar: image)
        }
    }
    
    private func updateCurrentTaskState(with state: PostProcessTaskState) {
        guard currentTaskIndex < tasks.count else {
            return
        }
        
        tasks[currentTaskIndex].state = state
    }

    private func update(roomName: String) {
        updateCurrentTaskState(with: .started)
        
        currentOperation = room?.setName(roomName, completion: { [weak self] response in
            guard let self = self else { return }
            
            switch response {
            case .success:
                self.updateCurrentTaskState(with: .success)
            case .failure(let error):
                self.lastError = error
                self.updateCurrentTaskState(with: .failure)
            }
            
            self.runNextTask()
        })
    }
    
    private func update(topic: String) {
        updateCurrentTaskState(with: .started)
        
        currentOperation = room?.setTopic(topic, completion: { [weak self] response in
            guard let self = self else { return }
            
            switch response {
            case .success:
                self.updateCurrentTaskState(with: .success)
            case .failure(let error):
                self.lastError = error
                self.updateCurrentTaskState(with: .failure)
            }
            
            self.runNextTask()
        })
    }
    
    private func update(canonicalAlias: String) {
        updateCurrentTaskState(with: .started)
        
        currentOperation = room?.addAlias(canonicalAlias.fullLocalAlias(with: session), completion: { [weak self] response in
            guard let self = self else { return }
            
            switch response {
            case .success:
                if let publicAddress = self.publicAddress {
                    self.currentOperation = self.room?.removeAlias(publicAddress.fullLocalAlias(with: self.session), completion: { [weak self] response in
                        guard let self = self else { return }

                        self.setup(canonicalAlias: canonicalAlias)
                    })
                } else {
                    self.setup(canonicalAlias: canonicalAlias)
                }
            case .failure(let error):
                self.lastError = error
                self.updateCurrentTaskState(with: .failure)
                self.runNextTask()
            }
        })
    }
    
    private func setup(canonicalAlias: String) {
        currentOperation = room?.setCanonicalAlias(canonicalAlias.fullLocalAlias(with: session), completion: { [weak self] response in
            guard let self = self else { return }
            
            switch response {
            case .success:
                self.updateCurrentTaskState(with: .success)
            case .failure(let error):
                self.lastError = error
                self.updateCurrentTaskState(with: .failure)
            }
            
            self.runNextTask()
        })
    }
    
    private func upload(avatar: UIImage) {
        updateCurrentTaskState(with: .started)
        
        let avatarUp = MXKTools.forceImageOrientationUp(avatar)
        
        mediaUploader.uploadData(avatarUp?.jpegData(compressionQuality: 0.5), filename: nil, mimeType: "image/jpeg",
                                 success: { [weak self] (urlString) in
                                    guard let self = self else { return }
                                    
                                    guard let urlString = urlString else { return }
                                    guard let url = URL(string: urlString) else { return }
                                    
                                    self.setAvatar(withURL: url)
                                 },
                                 failure: { [weak self] (error) in
                                    guard let self = self else { return }
                                    
                                    self.lastError = error
                                    self.updateCurrentTaskState(with: .failure)
                                    self.runNextTask()
                                 })
    }
    
    private func setAvatar(withURL url: URL) {
        currentOperation = room?.setAvatar(url: url) { [weak self] (response) in
            guard let self = self else { return }

            switch response {
            case .success:
                self.updateCurrentTaskState(with: .success)
            case .failure(let error):
                self.lastError = error
                self.updateCurrentTaskState(with: .failure)
            }
            
            self.runNextTask()
        }
    }

}
