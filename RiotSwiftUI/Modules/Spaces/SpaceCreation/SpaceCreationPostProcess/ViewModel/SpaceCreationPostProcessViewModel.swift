// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationPostProcess SpaceCreationPostProcess
//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias SpaceCreationPostProcessViewModelType = StateStoreViewModel<SpaceCreationPostProcessViewState, SpaceCreationPostProcessViewAction>

class SpaceCreationPostProcessViewModel: SpaceCreationPostProcessViewModelType, SpaceCreationPostProcessViewModelProtocol {
    // MARK: - Properties

    // MARK: Private

    private let spaceCreationPostProcessService: SpaceCreationPostProcessServiceProtocol
    private var updateNotificationObserver: Any?

    // MARK: Public

    var completion: ((SpaceCreationPostProcessViewModelResult) -> Void)?

    // MARK: - Setup

    static func makeSpaceCreationPostProcessViewModel(spaceCreationPostProcessService: SpaceCreationPostProcessServiceProtocol) -> SpaceCreationPostProcessViewModelProtocol {
        SpaceCreationPostProcessViewModel(spaceCreationPostProcessService: spaceCreationPostProcessService)
    }

    private init(spaceCreationPostProcessService: SpaceCreationPostProcessServiceProtocol) {
        self.spaceCreationPostProcessService = spaceCreationPostProcessService
        super.init(initialViewState: Self.defaultState(spaceCreationPostProcessService: spaceCreationPostProcessService))
        setupTasksObserving()
    }

    private static func defaultState(spaceCreationPostProcessService: SpaceCreationPostProcessServiceProtocol) -> SpaceCreationPostProcessViewState {
        let tasks = spaceCreationPostProcessService.tasksSubject.value
        return SpaceCreationPostProcessViewState(
            avatar: spaceCreationPostProcessService.avatar,
            avatarImage: spaceCreationPostProcessService.avatarImage,
            tasks: tasks,
            isFinished: tasks.first?.state == .failure || tasks.reduce(true) { result, task in result && task.isFinished },
            errorCount: tasks.reduce(0) { result, task in result + (task.state == .failure ? 1 : 0) }
        )
    }
    
    private func setupTasksObserving() {
        spaceCreationPostProcessService
            .tasksSubject
            .sink(receiveValue: { [weak self] tasks in
                guard let self = self else { return }
                
                self.state.tasks = tasks
                self.state.isFinished = tasks.first?.state == .failure || tasks.reduce(true) { result, task in result && task.isFinished }
                self.state.errorCount = tasks.reduce(0) { result, task in result + (task.state == .failure ? 1 : 0) }
                
                NotificationCenter.default.post(name: SpaceCreationPostProcessViewModel.didUpdate,
                                                object: nil,
                                                userInfo: [SpaceCreationPostProcessViewModel.newStateKey: self.state])
            })
            .store(in: &cancellables)
        
        updateNotificationObserver = NotificationCenter.default.addObserver(forName: SpaceCreationPostProcessViewModel.didUpdate, object: nil, queue: OperationQueue.main) { [weak self] notification in
            guard let self = self else {
                return
            }
            
            guard let state = notification.userInfo?[SpaceCreationPostProcessViewModel.newStateKey] as? SpaceCreationPostProcessViewState else {
                return
            }
            
            if state.isFinished, state.errorCount == 0 {
                guard let spaceId = self.spaceCreationPostProcessService.createdSpaceId else {
                    self.cancel()
                    return
                }
                
                self.done(spaceId: spaceId)
            }
        }
    }
    
    deinit {
        if let updateNotificationObserver = self.updateNotificationObserver {
            NotificationCenter.default.removeObserver(updateNotificationObserver)
        }
    }

    // MARK: - Public

    override func process(viewAction: SpaceCreationPostProcessViewAction) {
        switch viewAction {
        case .cancel:
            cancel()
        case .runTasks:
            runTasks()
        case .retry:
            runTasks()
        }
    }

    private func done(spaceId: String) {
        completion?(.done(spaceId))
    }

    private func cancel() {
        completion?(.cancel)
    }
    
    private func runTasks() {
        spaceCreationPostProcessService.run()
    }
}

// MARK: - MXSpaceService notification constants

extension SpaceCreationPostProcessViewModel {
    /// Posted once the process is finished
    public static let didUpdate = Notification.Name("SpaceCreationPostProcessViewModelDidUpdate")
    
    public static let newStateKey = "newState"
}
