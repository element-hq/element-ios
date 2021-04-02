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

import Foundation

@objc protocol RoomInfoCoordinatorBridgePresenterDelegate {
    func roomInfoCoordinatorBridgePresenterDelegateDidComplete(_ coordinatorBridgePresenter: RoomInfoCoordinatorBridgePresenter)
}

/// RoomInfoCoordinatorBridgePresenter enables to start RoomInfoCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
@objcMembers
final class RoomInfoCoordinatorBridgePresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let coordinatorParameters: RoomInfoCoordinatorParameters
    private var coordinator: RoomInfoCoordinator?
    
    // MARK: Public
    
    weak var delegate: RoomInfoCoordinatorBridgePresenterDelegate?
    
    // MARK: - Setup
    
    init(parameters: RoomInfoCoordinatorParameters) {
        self.coordinatorParameters = parameters
        super.init()
    }
    
    // MARK: - Public
    
    // NOTE: Default value feature is not compatible with Objective-C.
    // func present(from viewController: UIViewController, animated: Bool) {
    //     self.present(from: viewController, animated: animated)
    // }
    
    func present(from viewController: UIViewController, animated: Bool) {
        let roomInfoCoordinator = RoomInfoCoordinator(parameters: self.coordinatorParameters)
        roomInfoCoordinator.delegate = self
        let presentable = roomInfoCoordinator.toPresentable()
        presentable.presentationController?.delegate = self
        viewController.present(presentable, animated: animated, completion: nil)
        roomInfoCoordinator.start()
        
        self.coordinator = roomInfoCoordinator
    }
    
    func push(from navigationController: UINavigationController, animated: Bool) {
        let navigationRouter = NavigationRouter(navigationController: navigationController)
        
        let roomInfoCoordinator = RoomInfoCoordinator(parameters: self.coordinatorParameters, navigationRouter: navigationRouter)
        roomInfoCoordinator.delegate = self
        roomInfoCoordinator.start()
        
        self.coordinator = roomInfoCoordinator
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        guard let coordinator = self.coordinator else {
            return
        }
        coordinator.toPresentable().dismiss(animated: animated) {
            self.coordinator = nil

            if let completion = completion {
                completion()
            }
        }
    }
}

// MARK: - RoomInfoCoordinatorDelegate
extension RoomInfoCoordinatorBridgePresenter: RoomInfoCoordinatorDelegate {
    
    func roomInfoCoordinatorDidComplete(_ coordinator: RoomInfoCoordinatorType) {
        self.delegate?.roomInfoCoordinatorBridgePresenterDelegateDidComplete(self)
    }
    
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension RoomInfoCoordinatorBridgePresenter: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.delegate?.roomInfoCoordinatorBridgePresenterDelegateDidComplete(self)
    }
    
}
