//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import MatrixSDK

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
        room = session.room(withRoomId: spaceId)
        isLoadingSubject = CurrentValueSubject(false)
        showPostProcessAlert = CurrentValueSubject(false)
        roomPropertiesSubject = CurrentValueSubject(roomProperties)
        addressValidationSubject = CurrentValueSubject(.none("#"))
        defaultAddress = ""
        
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
    
    func trackSpace() {
        Analytics.shared.exploringSpace = session.spaceService.getSpace(withId: spaceId)
    }
    
    // MARK: - Private
    
    private func readRoomState() {
        isLoadingSubject.send(true)
        room?.state { [weak self] roomState in
            self?.roomState = roomState
            self?.isLoadingSubject.send(false)
        }
        
        roomEventListener = room?.listen(toEvents: { [weak self] _, _, _ in
            self?.room?.state { [weak self] roomState in
                self?.roomState = roomState
            }
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
            let allowContent: [[String: String]] = joinRuleEvent.wireContent[kMXJoinRulesContentKeyAllow] as? [[String: String]] ?? []
            allowedParentIds = allowContent.compactMap { allowDictionnary in
                guard let type = allowDictionnary[kMXJoinRulesContentKeyType], type == kMXEventTypeStringRoomMembership else {
                    return nil
                }
                
                return allowDictionnary[kMXJoinRulesContentKeyRoomId]
            }
        }
        return allowedParentIds
    }
    
    private func isField(ofType notification: String, editableWith powerLevels: MXRoomPowerLevels?) -> Bool {
        guard let powerLevels = powerLevels else {
            return false
        }
        
        let userPowerLevel = powerLevels.powerLevelOfUser(withUserID: session.myUserId)
        return userPowerLevel >= powerLevels.minimumPowerLevel(forNotifications: notification, defaultPower: powerLevels.stateDefault)
    }
    
    private func validateAddress() {
        addressValidationOperation?.cancel()
        addressValidationOperation = nil

        guard let userDefinedAddress = userDefinedAddress, !userDefinedAddress.isEmpty else {
            let fullAddress = MXTools.fullLocalAlias(from: defaultAddress, with: session)

            if let publicAddress = publicAddress, !publicAddress.isEmpty {
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
        let fullAddress = MXTools.fullLocalAlias(from: aliasLocalPart, with: session)

        if let publicAddress = publicAddress, publicAddress == aliasLocalPart {
            addressValidationSubject.send(.current(fullAddress))
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
        
        if let canonicalAlias = roomState.canonicalAlias {
            let localAliasPart = MXTools.extractLocalAliasPart(from: canonicalAlias)
            publicAddress = localAliasPart
            defaultAddress = localAliasPart
        } else {
            publicAddress = nil
            defaultAddress = MXTools.validAliasLocalPart(from: roomState.name)
        }
        
        roomProperties = SpaceSettingsRoomProperties(
            name: roomState.name,
            topic: roomState.topic,
            address: defaultAddress,
            avatarUrl: roomState.avatar,
            visibility: visibility(with: roomState),
            allowedParentIds: allowedParentIds(with: roomState),
            isAvatarEditable: isField(ofType: kMXEventTypeStringRoomAvatar, editableWith: roomState.powerLevels),
            isNameEditable: isField(ofType: kMXEventTypeStringRoomName, editableWith: roomState.powerLevels),
            isTopicEditable: isField(ofType: kMXEventTypeStringRoomTopic, editableWith: roomState.powerLevels),
            isAddressEditable: isField(ofType: kMXEventTypeStringRoomAliases, editableWith: roomState.powerLevels),
            isAccessEditable: isField(ofType: kMXEventTypeStringRoomJoinRules, editableWith: roomState.powerLevels)
        )
    }
    
    // MARK: - Post process
    
    private var currentTaskIndex = 0
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
            state == .failure || state == .success
        }
        
        static func == (lhs: PostProcessTask, rhs: PostProcessTask) -> Bool {
            lhs.type == rhs.type && lhs.state == rhs.state
        }
    }

    func update(roomName: String, topic: String, address: String, avatar: UIImage?,
                completion: ((_ result: SpaceSettingsServiceCompletionResult) -> Void)?) {
        // First attempt
        if tasks.isEmpty {
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
            tasks = tasks.map { task in
                if task.state == .failure {
                    return PostProcessTask(type: task.type, state: .none)
                }
                return task
            }
        }
        
        isLoadingSubject.send(true)
        self.completion = completion
        lastError = nil
        currentTaskIndex = -1
        runNextTask()
    }
    
    private func runNextTask() {
        currentTaskIndex += 1
        guard currentTaskIndex < tasks.count else {
            isLoadingSubject.send(false)
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
        
        currentOperation = room?.addAlias(MXTools.fullLocalAlias(from: canonicalAlias, with: session), completion: { [weak self] response in
            guard let self = self else { return }
            
            switch response {
            case .success:
                if let publicAddress = self.publicAddress {
                    self.currentOperation = self.room?.removeAlias(MXTools.fullLocalAlias(from: publicAddress, with: self.session), completion: { [weak self] _ in
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
        currentOperation = room?.setCanonicalAlias(MXTools.fullLocalAlias(from: canonicalAlias, with: session), completion: { [weak self] response in
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
                                 success: { [weak self] urlString in
                                     guard let self = self else { return }
                                    
                                     guard let urlString = urlString else {
                                         self.updateCurrentTaskState(with: .failure)
                                         self.runNextTask()
                                         return
                                     }
                                     guard let url = URL(string: urlString) else {
                                         self.updateCurrentTaskState(with: .failure)
                                         self.runNextTask()
                                         return
                                     }
                                    
                                     self.setAvatar(withURL: url)
                                 },
                                 failure: { [weak self] error in
                                     guard let self = self else { return }
                                    
                                     self.lastError = error
                                     self.updateCurrentTaskState(with: .failure)
                                     self.runNextTask()
                                 })
    }
    
    private func setAvatar(withURL url: URL) {
        currentOperation = room?.setAvatar(url: url) { [weak self] response in
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
