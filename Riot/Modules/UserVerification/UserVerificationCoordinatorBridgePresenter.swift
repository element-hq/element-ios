// File created from FlowTemplate
// $ createRootCoordinator.sh UserVerification UserVerification
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

@objc protocol UserVerificationCoordinatorBridgePresenterDelegate {
    func userVerificationCoordinatorBridgePresenterDelegateDidComplete(_ coordinatorBridgePresenter: UserVerificationCoordinatorBridgePresenter)
}

/// UserVerificationCoordinatorBridgePresenter enables to start UserVerificationCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
@objcMembers
final class UserVerificationCoordinatorBridgePresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private    
    
    private let presenter: Presentable
    private let session: MXSession
    private let userId: String
    private let userDisplayName: String?
    private var deviceId: String?
    
    private var coordinator: Coordinator?
    
    // MARK: Public
    
    weak var delegate: UserVerificationCoordinatorBridgePresenterDelegate?
    
    // MARK: - Setup
    
    init(presenter: UIViewController, session: MXSession, userId: String, userDisplayName: String?) {
        self.presenter = presenter
        self.session = session
        self.userId = userId
        self.userDisplayName = userDisplayName
        super.init()
    }
    
    init(presenter: UIViewController, session: MXSession, userId: String, userDisplayName: String?, deviceId: String) {
        self.presenter = presenter
        self.session = session
        self.userId = userId
        self.userDisplayName = userDisplayName
        self.deviceId = deviceId
        super.init()
    }
    
    // MARK: - Public
    
    func start() {
        self.present()
    }
    
    func present() {
        
        let userVerificationCoordinator: UserVerificationCoordinator
        
        if let deviceId = self.deviceId {
            userVerificationCoordinator = UserVerificationCoordinator(presenter: self.presenter, session: self.session, userId: self.userId, userDisplayName: self.userDisplayName, deviceId: deviceId)
        } else {
            userVerificationCoordinator = UserVerificationCoordinator(presenter: self.presenter, session: self.session, userId: self.userId, userDisplayName: self.userDisplayName)
        }
        
        userVerificationCoordinator.start()
        self.coordinator = userVerificationCoordinator
    }
}
