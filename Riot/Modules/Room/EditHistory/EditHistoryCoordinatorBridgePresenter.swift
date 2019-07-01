// File created from FlowTemplate
// $ createRootCoordinator.sh Room/EditHistory EditHistory
/*
 Copyright 2019 New Vector Ltd
 
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

@objc protocol EditHistoryCoordinatorBridgePresenterDelegate {
    func editHistoryCoordinatorBridgePresenterDelegateDidComplete(_ coordinatorBridgePresenter: EditHistoryCoordinatorBridgePresenter)
}

/// EditHistoryCoordinatorBridgePresenter enables to start EditHistoryCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
@objcMembers
final class EditHistoryCoordinatorBridgePresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let aggregations: MXAggregations
    private let roomId: String
    private let eventId: String
    private var coordinator: EditHistoryCoordinator?
    
    // MARK: Public
    
    weak var delegate: EditHistoryCoordinatorBridgePresenterDelegate?
    
    // MARK: - Setup
    
    init(aggregations: MXAggregations,
         roomId: String,
         eventId: String) {
        self.aggregations = aggregations
        self.roomId = roomId
        self.eventId = eventId
        super.init()
    }
    
    // MARK: - Public
    
    // NOTE: Default value feature is not compatible with Objective-C.
    // func present(from viewController: UIViewController, animated: Bool) {
    //     self.present(from: viewController, animated: animated)
    // }
    
    func present(from viewController: UIViewController, animated: Bool) {
        let editHistoryCoordinator = EditHistoryCoordinator(aggregations: self.aggregations, roomId: self.roomId, eventId: self.eventId)
        editHistoryCoordinator.delegate = self

        let navigationController = UINavigationController()
        navigationController.addChild(editHistoryCoordinator.toPresentable())
        viewController.present(navigationController, animated: animated, completion: nil)
        
        editHistoryCoordinator.start()
        
        self.coordinator = editHistoryCoordinator
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

// MARK: - EditHistoryCoordinatorDelegate
extension EditHistoryCoordinatorBridgePresenter: EditHistoryCoordinatorDelegate {
    func editHistoryCoordinatorDidComplete(_ coordinator: EditHistoryCoordinatorType) {
        self.delegate?.editHistoryCoordinatorBridgePresenterDelegateDidComplete(self)
    }
}
