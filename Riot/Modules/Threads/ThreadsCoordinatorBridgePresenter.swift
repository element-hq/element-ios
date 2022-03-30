// File created from FlowTemplate
// $ createRootCoordinator.sh Threads Threads ThreadList
/*
 Copyright 2021 New Vector Ltd
 
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

@objc protocol ThreadsCoordinatorBridgePresenterDelegate {
    func threadsCoordinatorBridgePresenterDelegateDidComplete(_ coordinatorBridgePresenter: ThreadsCoordinatorBridgePresenter)
    func threadsCoordinatorBridgePresenterDelegateDidSelect(_ coordinatorBridgePresenter: ThreadsCoordinatorBridgePresenter,
                                                            roomId: String,
                                                            eventId: String?)
    func threadsCoordinatorBridgePresenterDidDismissInteractively(_ coordinatorBridgePresenter: ThreadsCoordinatorBridgePresenter)
}

/// ThreadsCoordinatorBridgePresenter enables to start ThreadsCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
/// **WARNING**: This class breaks the Coordinator abstraction and it has been introduced for **Objective-C compatibility only** (mainly for integration in legacy view controllers). Each bridge should be removed
/// once the underlying Coordinator has been integrated by another Coordinator.
@objcMembers
final class ThreadsCoordinatorBridgePresenter: NSObject {
    
    // MARK: - Constants
    
    private enum NavigationType {
        case present
        case push
    }
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let roomId: String
    private let threadId: String?
    private let userIndicatorPresenter: UserIndicatorTypePresenterProtocol
    private var navigationType: NavigationType = .present
    private var coordinator: ThreadsCoordinator?
    
    // MARK: Public
    
    weak var delegate: ThreadsCoordinatorBridgePresenterDelegate?
    
    // MARK: - Setup

    /// Initializer
    /// - Parameters:
    ///   - session: Session instance
    ///   - roomId: Room identifier
    ///   - threadId: Thread identifier. Specified thread will be opened if provided, the thread list otherwise
    init(session: MXSession,
         roomId: String,
         threadId: String?,
         userIndicatorPresenter: UserIndicatorTypePresenterProtocol) {
        self.session = session
        self.roomId = roomId
        self.threadId = threadId
        self.userIndicatorPresenter = userIndicatorPresenter
        super.init()
    }
    
    // MARK: - Public
    
    // NOTE: Default value feature is not compatible with Objective-C.
    // func present(from viewController: UIViewController, animated: Bool) {
    //     self.present(from: viewController, animated: animated)
    // }
    
    func present(from viewController: UIViewController, animated: Bool) {
        
        let threadsCoordinatorParameters = ThreadsCoordinatorParameters(session: self.session,
                                                                        roomId: self.roomId,
                                                                        threadId: self.threadId,
                                                                        userIndicatorPresenter: userIndicatorPresenter)
        
        let threadsCoordinator = ThreadsCoordinator(parameters: threadsCoordinatorParameters)
        threadsCoordinator.delegate = self
        let presentable = threadsCoordinator.toPresentable()
        viewController.present(presentable, animated: animated, completion: nil)
        threadsCoordinator.start()
        
        self.coordinator = threadsCoordinator
        self.navigationType = .present
    }
    
    func push(from navigationController: UINavigationController, animated: Bool) {
                
        let navigationRouter = NavigationRouterStore.shared.navigationRouter(for: navigationController)
        
        let threadsCoordinatorParameters = ThreadsCoordinatorParameters(session: self.session,
                                                                        roomId: self.roomId,
                                                                        threadId: self.threadId,
                                                                        userIndicatorPresenter: userIndicatorPresenter,
                                                                        navigationRouter: navigationRouter)
        
        let threadsCoordinator = ThreadsCoordinator(parameters: threadsCoordinatorParameters)
        threadsCoordinator.delegate = self
        threadsCoordinator.start() // Will trigger the view controller push
        
        self.coordinator = threadsCoordinator        
        self.navigationType = .push
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        guard let coordinator = self.coordinator else {
            return
        }

        switch navigationType {
        case .present:
            // Dismiss modal
            coordinator.toPresentable().dismiss(animated: animated) {
                self.coordinator = nil

                completion?()
            }
        case .push:
            //  stop coordinator to pop modules as needed
            coordinator.stop()
            self.coordinator = nil

            completion?()
        }
    }
}

// MARK: - ThreadsCoordinatorDelegate
extension ThreadsCoordinatorBridgePresenter: ThreadsCoordinatorDelegate {
    
    func threadsCoordinatorDidComplete(_ coordinator: ThreadsCoordinatorProtocol) {
        self.delegate?.threadsCoordinatorBridgePresenterDelegateDidComplete(self)
    }
    
    func threadsCoordinatorDidSelect(_ coordinator: ThreadsCoordinatorProtocol, roomId: String, eventId: String?) {
        self.delegate?.threadsCoordinatorBridgePresenterDelegateDidSelect(self, roomId: roomId, eventId: eventId)
    }
    
    func threadsCoordinatorDidDismissInteractively(_ coordinator: ThreadsCoordinatorProtocol) {
        self.delegate?.threadsCoordinatorBridgePresenterDidDismissInteractively(self)
    }
}
