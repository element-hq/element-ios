// File created from FlowTemplate
// $ createRootCoordinator.sh UserVerification UserVerification
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
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
        userVerificationCoordinator.delegate = self
        userVerificationCoordinator.start()
        self.coordinator = userVerificationCoordinator
    }
}

extension UserVerificationCoordinatorBridgePresenter: UserVerificationCoordinatorDelegate {
    func userVerificationCoordinatorDidComplete(_ coordinator: UserVerificationCoordinatorType) {
        delegate?.userVerificationCoordinatorBridgePresenterDelegateDidComplete(self)
    }
}
