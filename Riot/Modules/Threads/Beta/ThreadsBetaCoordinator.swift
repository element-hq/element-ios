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

import UIKit

@objcMembers
final class ThreadsBetaCoordinator: NSObject, ThreadsBetaCoordinatorProtocol {
    
    // MARK: - Properties
    
    // MARK: Private
        
    private let threadId: String
    private let infoText: String
    private let additionalText: String?
    private lazy var viewController: ThreadsBetaViewController = {
        let result = ThreadsBetaViewController.instantiate(infoText: infoText, additionalText: additionalText)
        result.didTapEnableButton = { [weak self] in
            guard let self = self else { return }
            RiotSettings.shared.enableThreads = true
            MXSDKOptions.sharedInstance().enableThreads = true
            self.delegate?.threadsBetaCoordinatorDidTapEnable(self)
        }
        result.didTapCancelButton = { [weak self] in
            guard let self = self else { return }
            self.delegate?.threadsBetaCoordinatorDidTapCancel(self)
        }
        return result
    }()

    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: ThreadsBetaCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(threadId: String, infoText: String, additionalText: String?) {
        self.threadId = threadId
        self.infoText = infoText
        self.additionalText = additionalText
    }    
    
    // MARK: - Public
    
    func start() {
        //  no-op. this is a static screen
    }
    
    func toPresentable() -> UIViewController {
        return viewController
    }
}
