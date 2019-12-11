// File created from FlowTemplate
// $ createRootCoordinator.sh DeviceVerification DeviceVerification DeviceVerificationStart
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

@objc protocol DeviceVerificationCoordinatorBridgePresenterDelegate {
    func deviceVerificationCoordinatorBridgePresenterDelegateDidComplete(_ coordinatorBridgePresenter: DeviceVerificationCoordinatorBridgePresenter, otherUserId: String, otherDeviceId: String)
}

/// DeviceVerificationCoordinatorBridgePresenter enables to start DeviceVerificationCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
@objcMembers
final class DeviceVerificationCoordinatorBridgePresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private var coordinator: DeviceVerificationCoordinator?
    
    // MARK: Public
    
    weak var delegate: DeviceVerificationCoordinatorBridgePresenterDelegate?
    
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
    
    func present(from viewController: UIViewController, otherUserId: String, otherDeviceId: String, animated: Bool) {
        
        NSLog("[DeviceVerificationCoordinatorBridgePresenter] Present from \(viewController)")
        
        let deviceVerificationCoordinator = DeviceVerificationCoordinator(session: self.session, otherUserId: otherUserId, otherDeviceId: otherDeviceId)
        deviceVerificationCoordinator.delegate = self
        viewController.present(deviceVerificationCoordinator.toPresentable(), animated: animated, completion: nil)
        deviceVerificationCoordinator.start()
        
        self.coordinator = deviceVerificationCoordinator
    }

    func present(from viewController: UIViewController, incomingTransaction: MXIncomingSASTransaction, animated: Bool) {
        
        NSLog("[DeviceVerificationCoordinatorBridgePresenter] Present incoming verification from \(viewController)")
        
        let deviceVerificationCoordinator = DeviceVerificationCoordinator(session: self.session, incomingTransaction: incomingTransaction)
        deviceVerificationCoordinator.delegate = self
        viewController.present(deviceVerificationCoordinator.toPresentable(), animated: animated, completion: nil)
        deviceVerificationCoordinator.start()

        self.coordinator = deviceVerificationCoordinator
    }

    func dismiss(animated: Bool, completion: (() -> Void)?) {
        guard let coordinator = self.coordinator else {
            return
        }
        
        NSLog("[DeviceVerificationCoordinatorBridgePresenter] Dismiss")
        
        coordinator.toPresentable().dismiss(animated: animated) {
            self.coordinator = nil

            if let completion = completion {
                completion()
            }
        }
    }
}

// MARK: - DeviceVerificationCoordinatorDelegate
extension DeviceVerificationCoordinatorBridgePresenter: DeviceVerificationCoordinatorDelegate {
    func deviceVerificationCoordinatorDidComplete(_ coordinator: DeviceVerificationCoordinatorType, otherUserId: String, otherDeviceId: String) {
        self.delegate?.deviceVerificationCoordinatorBridgePresenterDelegateDidComplete(self, otherUserId: otherUserId, otherDeviceId: otherDeviceId)
    }
}
