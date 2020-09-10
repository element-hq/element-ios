// File created from FlowTemplate
// $ createRootCoordinator.sh Rooms2 ShowDirectory ShowDirectory
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

@objc protocol ShowDirectoryCoordinatorBridgePresenterDelegate {
    func showDirectoryCoordinatorBridgePresenterDelegateDidComplete(_ coordinatorBridgePresenter: ShowDirectoryCoordinatorBridgePresenter)
}

/// ShowDirectoryCoordinatorBridgePresenter enables to start ShowDirectoryCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
@objcMembers
final class ShowDirectoryCoordinatorBridgePresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private var coordinator: ShowDirectoryCoordinator?
    
    // MARK: Public
    
    weak var delegate: ShowDirectoryCoordinatorBridgePresenterDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.session = session
        super.init()
    }
    
    // MARK: - Public
    
    // NOTE: Default value feature is not compatible with Objective-C.
    // func present(from viewController: UIViewController, animated: Bool) {
    //     self.present(from: viewController, animated: animated)
    // }
    
    func present(from viewController: UIViewController, animated: Bool) {
        let showDirectoryCoordinator = ShowDirectoryCoordinator(session: self.session)
        showDirectoryCoordinator.delegate = self
        viewController.present(showDirectoryCoordinator.toPresentable(), animated: animated, completion: nil)
        showDirectoryCoordinator.start()
        
        self.coordinator = showDirectoryCoordinator
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

// MARK: - ShowDirectoryCoordinatorDelegate
extension ShowDirectoryCoordinatorBridgePresenter: ShowDirectoryCoordinatorDelegate {
    func showDirectoryCoordinatorDidComplete(_ coordinator: ShowDirectoryCoordinatorType) {
        self.delegate?.showDirectoryCoordinatorBridgePresenterDelegateDidComplete(self)
    }
}
