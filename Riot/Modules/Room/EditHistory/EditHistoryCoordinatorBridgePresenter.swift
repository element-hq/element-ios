// File created from FlowTemplate
// $ createRootCoordinator.sh Room/EditHistory EditHistory
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

@objc protocol EditHistoryCoordinatorBridgePresenterDelegate {
    func editHistoryCoordinatorBridgePresenterDelegateDidComplete(_ coordinatorBridgePresenter: EditHistoryCoordinatorBridgePresenter)
}

/// EditHistoryCoordinatorBridgePresenter enables to start EditHistoryCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
@objcMembers
final class EditHistoryCoordinatorBridgePresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let event: MXEvent
    private var coordinator: EditHistoryCoordinator?
    
    // MARK: Public
    
    weak var delegate: EditHistoryCoordinatorBridgePresenterDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession,
         event: MXEvent) {
        self.session = session
        self.event = event
        super.init()
    }
    
    // MARK: - Public
    
    // NOTE: Default value feature is not compatible with Objective-C.
    // func present(from viewController: UIViewController, animated: Bool) {
    //     self.present(from: viewController, animated: animated)
    // }
    
    func present(from viewController: UIViewController, animated: Bool) {

        guard let formatter = self.createEventFormatter(session: self.session) else {
            return
        }

        let editHistoryCoordinator = EditHistoryCoordinator(session: self.session, formatter: formatter, event: self.event)
        editHistoryCoordinator.delegate = self

        let navigationController = RiotNavigationController(rootViewController: editHistoryCoordinator.toPresentable())
        navigationController.modalPresentationStyle = .formSheet
        viewController.present(navigationController, animated: animated, completion: nil)
        
        editHistoryCoordinator.start()
        
        self.coordinator = editHistoryCoordinator
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

    // MARK: - Private

    func createEventFormatter(session: MXSession) -> EventFormatter? {
        guard let formatter = EventFormatter(matrixSession: session) else {
            MXLog.debug("[EditHistoryCoordinatorBridgePresenter] createEventFormatter: Cannot build formatter")
            return nil
        }

        // Use the same event formatter settings as RoomDataSource
        formatter.treatMatrixUserIdAsLink = true
        formatter.treatMatrixRoomIdAsLink = true
        formatter.treatMatrixRoomAliasAsLink = true
        formatter.eventTypesFilterForMessages = MXKAppSettings.standard()?.eventsFilterForMessages

        // But do not display "...(Edited)"
        formatter.showEditionMention = false

        return formatter
    }
}

// MARK: - EditHistoryCoordinatorDelegate
extension EditHistoryCoordinatorBridgePresenter: EditHistoryCoordinatorDelegate {
    func editHistoryCoordinatorDidComplete(_ coordinator: EditHistoryCoordinatorType) {
        self.delegate?.editHistoryCoordinatorBridgePresenterDelegateDidComplete(self)
    }
}
