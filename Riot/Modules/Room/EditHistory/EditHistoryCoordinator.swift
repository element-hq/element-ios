// File created from ScreenTemplate
// $ createScreen.sh Room/EditHistory EditHistory
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation
import UIKit

final class EditHistoryCoordinator: EditHistoryCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private

    private var editHistoryViewModel: EditHistoryViewModelType
    private let editHistoryViewController: EditHistoryViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: EditHistoryCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession,
         formatter: MXKEventFormatter,
         event: MXEvent) {
        
        let editHistoryViewModel = EditHistoryViewModel(session: session, formatter: formatter, event: event)
        let editHistoryViewController = EditHistoryViewController.instantiate(with: editHistoryViewModel)
        self.editHistoryViewModel = editHistoryViewModel
        self.editHistoryViewController = editHistoryViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.editHistoryViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.editHistoryViewController
    }
}

// MARK: - EditHistoryViewModelCoordinatorDelegate
extension EditHistoryCoordinator: EditHistoryViewModelCoordinatorDelegate {

    func editHistoryViewModelDidClose(_ viewModel: EditHistoryViewModelType) {
        self.delegate?.editHistoryCoordinatorDidComplete(self)
    }
}
