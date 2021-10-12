// File created from FlowTemplate
// $ createRootCoordinator.sh Modal ServiceTermsModal ServiceTermsModalLoadTermsScreen
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
