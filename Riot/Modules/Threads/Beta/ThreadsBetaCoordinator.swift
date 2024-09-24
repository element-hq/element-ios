// File created from FlowTemplate
// $ createRootCoordinator.sh Threads ThreadsBeta
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
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
