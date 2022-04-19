// File created from FlowTemplate
// $ createRootCoordinator.sh Threads ThreadsBeta
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

@objc protocol ThreadsBetaCoordinatorBridgePresenterDelegate {
    func threadsBetaCoordinatorBridgePresenterDelegateDidTapEnable(_ coordinatorBridgePresenter: ThreadsBetaCoordinatorBridgePresenter)
    func threadsBetaCoordinatorBridgePresenterDelegateDidTapCancel(_ coordinatorBridgePresenter: ThreadsBetaCoordinatorBridgePresenter)
}

/// ThreadsBetaCoordinatorBridgePresenter enables to start ThreadsBetaCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
/// **WARNING**: This class breaks the Coordinator abstraction and it has been introduced for **Objective-C compatibility only** (mainly for integration in legacy view controllers).
/// Each bridge should be removed once the underlying Coordinator has been integrated by another Coordinator.
@objcMembers
final class ThreadsBetaCoordinatorBridgePresenter: NSObject {
    
    // MARK: - Constants

    // MARK: - Properties
    
    // MARK: Private

    public let threadId: String
    public let infoText: String
    public let additionalText: String?
    private let slidingModalPresenter = SlidingModalPresenter()
    private var coordinator: ThreadsBetaCoordinator?
    
    // MARK: Public
    
    weak var delegate: ThreadsBetaCoordinatorBridgePresenterDelegate?
    
    // MARK: - Setup
    
    init(threadId: String, infoText: String, additionalText: String?) {
        self.threadId = threadId
        self.infoText = infoText
        self.additionalText = additionalText
        super.init()
    }
    
    // MARK: - Public

    func present(from viewController: UIViewController, animated: Bool) {
        
        let threadsBetaCoordinator = ThreadsBetaCoordinator(threadId: threadId,
                                                            infoText: infoText,
                                                            additionalText: additionalText)
        threadsBetaCoordinator.delegate = self
        guard let presentable = threadsBetaCoordinator.toPresentable() as? SlidingModalPresentable.ViewControllerType else {
            MXLog.error("[ThreadsBetaCoordinatorBridgePresenter] Presentable is not 'SlidingModalPresentable'")
            return
        }
        slidingModalPresenter.present(presentable,
                                      from: viewController,
                                      animated: animated,
                                      options: .spanning,
                                      completion: nil)
        threadsBetaCoordinator.start()
        
        self.coordinator = threadsBetaCoordinator
    }

    func dismiss(animated: Bool, completion: (() -> Void)?) {
        slidingModalPresenter.dismiss(animated: animated, completion: completion)
    }
}

// MARK: - ThreadsBetaCoordinatorDelegate
extension ThreadsBetaCoordinatorBridgePresenter: ThreadsBetaCoordinatorDelegate {
    
    func threadsBetaCoordinatorDidTapEnable(_ coordinator: ThreadsBetaCoordinatorProtocol) {
        self.delegate?.threadsBetaCoordinatorBridgePresenterDelegateDidTapEnable(self)
    }
    
    func threadsBetaCoordinatorDidTapCancel(_ coordinator: ThreadsBetaCoordinatorProtocol) {
        self.delegate?.threadsBetaCoordinatorBridgePresenterDelegateDidTapCancel(self)
    }
}
