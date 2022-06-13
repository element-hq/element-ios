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
import MatrixSDK

@objc protocol ChangePasswordCoordinatorBridgePresenterDelegate {
    func changePasswordCoordinatorBridgePresenterDidCancel(_ bridgePresenter: ChangePasswordCoordinatorBridgePresenter)
    func changePasswordCoordinatorBridgePresenterDidComplete(_ bridgePresenter: ChangePasswordCoordinatorBridgePresenter)
}

/// ChangePasswordCoordinatorBridgePresenter enables to start ChangePasswordCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
/// **WARNING**: This class breaks the Coordinator abstraction and it has been introduced for **Objective-C compatibility only** (mainly for integration in legacy view controllers). Each bridge should be removed
/// once the underlying Coordinator has been integrated by another Coordinator.
@objcMembers
final class ChangePasswordCoordinatorBridgePresenter: NSObject {

    // MARK: - Constants

    // MARK: - Properties

    // MARK: Private

    private let session: MXSession
    private var coordinator: ChangePasswordCoordinator?

    // MARK: Public

    weak var delegate: ChangePasswordCoordinatorBridgePresenterDelegate?

    // MARK: - Setup

    /// Initializer
    /// - Parameters:
    ///   - session: Session instance
    init(session: MXSession) {
        self.session = session
        super.init()
    }

    // MARK: - Public

    func present(from viewController: UIViewController, animated: Bool) {

        let params = ChangePasswordCoordinatorParameters(restClient: self.session.matrixRestClient)

        let changePasswordCoordinator = ChangePasswordCoordinator(parameters: params)
        changePasswordCoordinator.callback = { [weak self] in
            guard let self = self else { return }
            self.delegate?.changePasswordCoordinatorBridgePresenterDidComplete(self)
        }
        let presentable = changePasswordCoordinator.toPresentable()
        let navController = RiotNavigationController(rootViewController: presentable.toPresentable())
        navController.navigationBar.topItem?.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                                                 target: self,
                                                                                 action: #selector(cancelTapped))
        navController.isModalInPresentation = true
        viewController.present(navController, animated: animated, completion: nil)
        changePasswordCoordinator.start()

        self.coordinator = changePasswordCoordinator
    }

    func dismiss(animated: Bool, completion: (() -> Void)?) {
        guard let coordinator = self.coordinator else {
            return
        }

        // Dismiss modal
        coordinator.toPresentable().dismiss(animated: animated) {
            self.coordinator = nil

            completion?()
        }
    }

    @objc
    private func cancelTapped() {
        delegate?.changePasswordCoordinatorBridgePresenterDidCancel(self)
    }
}
