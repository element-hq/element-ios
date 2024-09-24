// File created from FlowTemplate
// $ createRootCoordinator.sh Modal ServiceTermsModal ServiceTermsModalLoadTermsScreen
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

@objc protocol ServiceTermsModalCoordinatorBridgePresenterDelegate {
    func serviceTermsModalCoordinatorBridgePresenterDelegateDidAccept(_ coordinatorBridgePresenter: ServiceTermsModalCoordinatorBridgePresenter)
    func serviceTermsModalCoordinatorBridgePresenterDelegateDidDecline(_ coordinatorBridgePresenter: ServiceTermsModalCoordinatorBridgePresenter, session: MXSession)
    func serviceTermsModalCoordinatorBridgePresenterDelegateDidClose(_ coordinatorBridgePresenter: ServiceTermsModalCoordinatorBridgePresenter)
}

/// ServiceTermsModalCoordinatorBridgePresenter enables to start ServiceTermsModalCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
@objcMembers
final class ServiceTermsModalCoordinatorBridgePresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let baseUrl: String
    private let serviceType: MXServiceType
    private let accessToken: String
    private var coordinator: ServiceTermsModalCoordinator?
    
    // MARK: Public
    
    weak var delegate: ServiceTermsModalCoordinatorBridgePresenterDelegate?
    
    var isPresenting: Bool {
        return self.coordinator != nil
    }
    
    // MARK: - Setup
    
    init(session: MXSession, baseUrl: String, serviceType: MXServiceType, accessToken: String) {
        self.session = session
        self.baseUrl = baseUrl
        self.serviceType = serviceType
        self.accessToken = accessToken
        super.init()
    }
    
    // MARK: - Public
    
    // NOTE: Default value feature is not compatible with Objective-C.
    // func present(from viewController: UIViewController, animated: Bool) {
    //     self.present(from: viewController, animated: animated)
    // }
    
    func present(from viewController: UIViewController, animated: Bool) {
        let serviceTermsModalCoordinator = ServiceTermsModalCoordinator(session: self.session, baseUrl: self.baseUrl, serviceType: self.serviceType, accessToken: accessToken)
        serviceTermsModalCoordinator.delegate = self
        let presentable = serviceTermsModalCoordinator.toPresentable()
        viewController.present(presentable, animated: animated, completion: nil)
        serviceTermsModalCoordinator.start()
        
        if let coordinator = self.coordinator {
            coordinator.toPresentable().dismiss(animated: false, completion: nil)
        }
        
        self.coordinator = serviceTermsModalCoordinator
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

// MARK: - ServiceTermsModalCoordinatorDelegate
extension ServiceTermsModalCoordinatorBridgePresenter: ServiceTermsModalCoordinatorDelegate {

    func serviceTermsModalCoordinatorDidAccept(_ coordinator: ServiceTermsModalCoordinatorType) {
        self.delegate?.serviceTermsModalCoordinatorBridgePresenterDelegateDidAccept(self)
    }

    func serviceTermsModalCoordinatorDidDecline(_ coordinator: ServiceTermsModalCoordinatorType) {
        self.delegate?.serviceTermsModalCoordinatorBridgePresenterDelegateDidDecline(self, session: self.session)
    }
    
    func serviceTermsModalCoordinatorDidDismissInteractively(_ coordinator: ServiceTermsModalCoordinatorType) {
        self.delegate?.serviceTermsModalCoordinatorBridgePresenterDelegateDidClose(self)
    }
}
