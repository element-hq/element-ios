// File created from FlowTemplate
// $ createRootCoordinator.sh Room RoomCreationModal RoomCreationEventsModal
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

import Foundation

@objc protocol RoomCreationModalCoordinatorBridgePresenterDelegate {
    func roomCreationModalCoordinatorBridgePresenterDelegateDidComplete(_ coordinatorBridgePresenter: RoomCreationModalCoordinatorBridgePresenter)
}

/// RoomCreationModalCoordinatorBridgePresenter enables to start RoomCreationModalCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
@objcMembers
final class RoomCreationModalCoordinatorBridgePresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let roomState: MXRoomState
    private var coordinator: RoomCreationEventsModalCoordinator?
    private lazy var slidingModalPresenter: SlidingModalPresenter = {
        return SlidingModalPresenter()
    }()
    
    // MARK: Public
    
    weak var delegate: RoomCreationModalCoordinatorBridgePresenterDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, roomState: MXRoomState) {
        self.session = session
        self.roomState = roomState
        super.init()
    }
    
    // MARK: - Public
    
    func present(from viewController: UIViewController, animated: Bool) {
        slidingModalPresenter.dismiss(animated: false, completion: nil)
        let roomCreationEventsModalCoordinator = RoomCreationEventsModalCoordinator(session: self.session, roomState: roomState)
        roomCreationEventsModalCoordinator.delegate = self
        
        slidingModalPresenter.present(roomCreationEventsModalCoordinator.toSlidingModalPresentable(),
                                      from: viewController,
                                      animated: animated,
                                      options: .spanning,
                                      completion: nil)
        
        roomCreationEventsModalCoordinator.start()
        
        self.coordinator = roomCreationEventsModalCoordinator
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        slidingModalPresenter.dismiss(animated: animated, completion: completion)
    }
}

// MARK: - RoomCreationModalCoordinatorDelegate
extension RoomCreationModalCoordinatorBridgePresenter: RoomCreationEventsModalCoordinatorDelegate {
    
    func roomCreationEventsModalCoordinatorDidTapClose(_ coordinator: RoomCreationEventsModalCoordinatorType) {
        self.delegate?.roomCreationModalCoordinatorBridgePresenterDelegateDidComplete(self)
    }
    
}
