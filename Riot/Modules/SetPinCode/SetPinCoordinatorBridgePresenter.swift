// File created from FlowTemplate
// $ createRootCoordinator.sh SetPinCode SetPin EnterPinCode
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
import UIKit

@objc enum SetPinCoordinatorViewMode: Int {
    case setPin
    case setPinAfterLogin
    case setPinAfterRegister
    case notAllowedPin
    case unlock
    case confirmPinToDeactivate
    case setupBiometricsAfterLogin
    case setupBiometricsFromSettings
    case confirmBiometricsToDeactivate
    case inactive
    case changePin
}

@objc protocol SetPinCoordinatorBridgePresenterDelegate {
    func setPinCoordinatorBridgePresenterDelegateDidComplete(_ coordinatorBridgePresenter: SetPinCoordinatorBridgePresenter)
    @objc optional
    func setPinCoordinatorBridgePresenterDelegateDidCancel(_ coordinatorBridgePresenter: SetPinCoordinatorBridgePresenter)
    @objc optional
    func setPinCoordinatorBridgePresenterDelegateDidCompleteWithReset(_ coordinatorBridgePresenter: SetPinCoordinatorBridgePresenter, dueToTooManyErrors: Bool)
}

/// SetPinCoordinatorBridgePresenter enables to start SetPinCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
@objcMembers
final class SetPinCoordinatorBridgePresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private var pinCoordinatorWindow: UIWindow?
    
    private let session: MXSession?
    private var coordinator: SetPinCoordinator?
    var viewMode: SetPinCoordinatorViewMode {
        didSet {
            if viewMode != oldValue {
                coordinator?.viewMode = viewMode
            }
        }
    }
    
    // MARK: Public
    
    weak var delegate: SetPinCoordinatorBridgePresenterDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession?, viewMode: SetPinCoordinatorViewMode) {
        self.session = session
        self.viewMode = viewMode
        super.init()
    }
    
    // MARK: - Public
    
    // NOTE: Default value feature is not compatible with Objective-C.
    // func present(from viewController: UIViewController, animated: Bool) {
    //     self.present(from: viewController, animated: animated)
    // }
    
    func present(from viewController: UIViewController, animated: Bool) {
        let setPinCoordinator = SetPinCoordinator(session: self.session, viewMode: self.viewMode, pinCodePreferences: .shared)
        setPinCoordinator.delegate = self
        viewController.present(setPinCoordinator.toPresentable(), animated: animated, completion: nil)
        setPinCoordinator.start()
        
        self.coordinator = setPinCoordinator
    }
    
    func presentWithMainAppWindow(_ window: UIWindow) {
        let pinCoordinatorWindow = UIWindow(frame: window.bounds)
        
        let setPinCoordinator = SetPinCoordinator(session: self.session, viewMode: self.viewMode, pinCodePreferences: .shared)
        setPinCoordinator.delegate = self
        
        pinCoordinatorWindow.rootViewController = setPinCoordinator.toPresentable()        
        pinCoordinatorWindow.makeKeyAndVisible()
        
        setPinCoordinator.start()
        
        self.pinCoordinatorWindow = pinCoordinatorWindow
        self.coordinator = setPinCoordinator
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
    
    func dismissWithMainAppWindow(_ window: UIWindow) {
        window.makeKeyAndVisible()
        pinCoordinatorWindow = nil
        coordinator = nil
    }
}

// MARK: - SetPinCoordinatorDelegate
extension SetPinCoordinatorBridgePresenter: SetPinCoordinatorDelegate {
    
    func setPinCoordinatorDidComplete(_ coordinator: SetPinCoordinatorType) {
        self.delegate?.setPinCoordinatorBridgePresenterDelegateDidComplete(self)
    }
    
    func setPinCoordinatorDidCompleteWithReset(_ coordinator: SetPinCoordinatorType, dueToTooManyErrors: Bool) {
        self.delegate?.setPinCoordinatorBridgePresenterDelegateDidCompleteWithReset?(self, dueToTooManyErrors: dueToTooManyErrors)
    }
    
    func setPinCoordinatorDidCancel(_ coordinator: SetPinCoordinatorType) {
        self.delegate?.setPinCoordinatorBridgePresenterDelegateDidCancel?(self)
    }
}
