// File created from FlowTemplate
// $ createRootCoordinator.sh Room2 RoomInfo RoomInfoList
/*
 Copyright 2020 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import UIKit

@objcMembers
final class RoomInfoCoordinator: NSObject, RoomInfoCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let navigationRouter: NavigationRouterType
    private let session: MXSession
    private let room: MXRoom
    
    private lazy var segmentedViewController: SegmentedViewController = {
        let controller = SegmentedViewController()
        
        let participants = RoomParticipantsViewController()
        participants.finalizeInit()
        participants.enableMention = true
        participants.mxRoom = self.room
        participants.delegate = self
        
        let files = RoomFilesViewController()
        files.finalizeInit()
        MXKRoomDataSource.load(withRoomId: self.room.roomId, andMatrixSession: self.session) { (dataSource) in
            guard let dataSource = dataSource as? MXKRoomDataSource else { return }
            dataSource.filterMessagesWithURL = true
            dataSource.finalizeInitialization()
            files.hasRoomDataSourceOwnership = true
            files.displayRoom(dataSource)
        }
        
        let settings = RoomSettingsViewController()
        settings.finalizeInit()
        settings.initWith(self.session, andRoomId: self.room.roomId)
        
        if self.room.isDirect {
            controller.title = VectorL10n.roomDetailsTitleForDm
        } else {
            controller.title = VectorL10n.roomDetailsTitle
        }
        controller.initWithTitles([
            VectorL10n.roomDetailsPeople,
            VectorL10n.roomDetailsFiles,
            VectorL10n.roomDetailsSettings
        ], viewControllers: [
            participants,
            files,
            settings
        ], defaultSelected: 0)
        controller.addMatrixSession(self.session)
        
        _ = controller.view
        
        return controller
    }()
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: RoomInfoCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, room: MXRoom) {
        self.navigationRouter = NavigationRouter(navigationController: RiotNavigationController())
        self.session = session
        self.room = room
    }    
    
    // MARK: - Public methods
    
    func start() {
        let rootCoordinator = self.createRoomInfoListCoordinator()

        rootCoordinator.start()

        self.add(childCoordinator: rootCoordinator)

        self.navigationRouter.setRootModule(rootCoordinator)
    }
    
    func toPresentable() -> UIViewController {
        return self.navigationRouter.toPresentable()
    }
    
    // MARK: - Private methods

    private func createRoomInfoListCoordinator() -> RoomInfoListCoordinator {
        let coordinator = RoomInfoListCoordinator(session: self.session, room: room)
        coordinator.delegate = self
        return coordinator
    }
}

// MARK: - RoomInfoListCoordinatorDelegate
extension RoomInfoCoordinator: RoomInfoListCoordinatorDelegate {
    
    func roomInfoListCoordinator(_ coordinator: RoomInfoListCoordinatorType, wantsToNavigateTo target: RoomInfoListTarget) {
        segmentedViewController.selectedIndex = target.rawValue
        navigationRouter.push(segmentedViewController, animated: true, popCompletion: nil)
    }
    
    func roomInfoListCoordinatorDidCancel(_ coordinator: RoomInfoListCoordinatorType) {
        self.delegate?.roomInfoCoordinatorDidComplete(self)
    }

}

extension RoomInfoCoordinator: RoomParticipantsViewControllerDelegate {
    
    func roomParticipantsViewController(_ roomParticipantsViewController: RoomParticipantsViewController!, mention member: MXRoomMember!) {
        
    }
    
}
